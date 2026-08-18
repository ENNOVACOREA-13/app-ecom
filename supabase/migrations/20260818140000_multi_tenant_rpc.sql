-- ============================================================================
-- Multi-tenant, Fase 4 (parte 2/2): funciones SECURITY DEFINER tenant-aware.
--
-- Estas funciones bypasean RLS por diseño (SECURITY DEFINER) — la única
-- barrera contra fugas entre tenants aquí es el código de la función misma.
-- Cada una deriva v_tenant_id := current_tenant_id() al inicio y lo usa
-- para: (a) validar que toda referencia recibida como parámetro (service_id,
-- employee_id, product_id, profile_id) pertenece al mismo tenant, (b) fijar
-- tenant_id explícito en cada insert nuevo, (c) filtrar cada update/lookup
-- por tenant_id.
--
-- De paso arregla 2 bugs reales encontrados al auditar el estado actual
-- (no son solo "faltaba tenant_id"):
--   1. crear_pedido/actualizar_estado_reserva leían loyalty_config con
--      `where id = true` (la columna legado booleana) — con más de un
--      tenant siempre traían la fila equivocada. Ahora filtran por
--      tenant_id real.
--   2. process_commission_cut agrupaba por employee_id sin filtrar tenant —
--      mezclaría comisiones de negocios distintos que compartieran ventana
--      de fechas. Ahora scopea todo el loop por tenant_id.
--   3. Las notificaciones automáticas avisaban a TODOS los admins de la
--      plataforma sin filtrar tenant. Ahora solo a los del mismo negocio.
--
-- Ver plan: C:\Users\HP\.claude\plans\stateful-dreaming-breeze.md
-- ============================================================================

-- ============================================================================
-- handle_new_user(): ahora exige un tenant_id válido en raw_user_meta_data
-- (lo debe mandar el cliente Flutter al hacer signUp, resuelto por
-- tenant_resolver.dart — cambio de código correspondiente en Fase 6). Un
-- signup sin tenant_id válido se rechaza por completo, no crea cuentas
-- huérfanas sin negocio.
-- ============================================================================
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_tenant_id uuid;
begin
  v_tenant_id := nullif(new.raw_user_meta_data->>'tenant_id', '')::uuid;

  if v_tenant_id is null or not exists (
    select 1 from public.tenants where id = v_tenant_id and status = 'active'
  ) then
    raise exception 'INVALID_TENANT';
  end if;

  insert into public.profiles (id, email, full_name, role, is_active, tenant_id)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'client'),
    true,
    v_tenant_id
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

-- ============================================================================
-- crear_reserva
-- ============================================================================
create or replace function public.crear_reserva(
  p_employee_id uuid,
  p_service_id uuid,
  p_date date,
  p_start_time time,
  p_notes text,
  p_extra_ids uuid[]
)
returns setof public.bookings
language plpgsql security definer set search_path = public as $$
declare
  v_client_id uuid := auth.uid();
  v_tenant_id uuid;
  v_duration int;
  v_precio numeric;
  v_end_time time;
  v_booking_id uuid;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select duration_min, price into v_duration, v_precio
  from public.services where id = p_service_id and tenant_id = v_tenant_id;
  if v_duration is null then
    raise exception 'SERVICE_NOT_FOUND';
  end if;

  if not exists (select 1 from public.profiles where id = p_employee_id and tenant_id = v_tenant_id) then
    raise exception 'EMPLOYEE_NOT_FOUND';
  end if;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    if exists (select 1 from public.services where id = any(p_extra_ids) and tenant_id is distinct from v_tenant_id) then
      raise exception 'SERVICE_NOT_FOUND';
    end if;
    select v_duration + coalesce(sum(duration_min), 0), v_precio + coalesce(sum(price), 0)
      into v_duration, v_precio
    from public.services where id = any(p_extra_ids) and tenant_id = v_tenant_id;
  end if;

  v_end_time := p_start_time + (v_duration || ' minutes')::interval;

  -- employee_id ya es único globalmente (uuid), el lock sigue siendo
  -- correcto sin necesidad de meter tenant_id en el hash.
  perform pg_advisory_xact_lock(hashtext(p_employee_id::text), hashtext(p_date::text));

  if exists (
    select 1 from public.bookings b
    where b.employee_id = p_employee_id
      and b.tenant_id = v_tenant_id
      and b.booking_date = p_date
      and b.status in ('pending','confirmed')
      and (p_start_time, v_end_time) overlaps (b.start_time, b.end_time)
  ) then
    raise exception 'BOOKING_CONFLICT';
  end if;

  insert into public.bookings
    (client_id, employee_id, service_id, booking_date, start_time, end_time, total_price, notes, tenant_id)
  values
    (v_client_id, p_employee_id, p_service_id, p_date, p_start_time, v_end_time, v_precio, p_notes, v_tenant_id)
  returning id into v_booking_id;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    insert into public.booking_extra_services (booking_id, service_id, tenant_id)
    select v_booking_id, unnest(p_extra_ids), v_tenant_id;
  end if;

  return query select * from public.bookings where id = v_booking_id;
end;
$$;

-- ============================================================================
-- crear_pedido — corrige el bug de `where id = true` sobre loyalty_config.
-- ============================================================================
create or replace function public.crear_pedido(
  p_items jsonb,
  p_notes text default null,
  p_payment_method text default 'cash',
  p_payment_status text default 'pending',
  p_stripe_payment_id text default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_client_id uuid := auth.uid();
  v_tenant_id uuid;
  v_order_id uuid;
  v_total numeric := 0;
  v_item jsonb;
  v_product_id uuid;
  v_cantidad int;
  v_nombre text;
  v_precio numeric;
  v_precio_oferta numeric;
  v_precio_efectivo numeric;
  v_cfg public.loyalty_config%rowtype;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_CART';
  end if;

  insert into public.orders (client_id, total, payment_method, payment_status, stripe_payment_id, notes, tenant_id)
  values (v_client_id, 0, p_payment_method, p_payment_status, p_stripe_payment_id, p_notes, v_tenant_id)
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := (v_item->>'product_id')::uuid;
    v_cantidad := (v_item->>'cantidad')::int;
    if v_cantidad is null or v_cantidad <= 0 then
      raise exception 'INVALID_QUANTITY';
    end if;

    select name, price, sale_price into v_nombre, v_precio, v_precio_oferta
    from public.products where id = v_product_id and tenant_id = v_tenant_id;
    if v_nombre is null then
      raise exception 'PRODUCT_NOT_FOUND';
    end if;

    v_precio_efectivo := coalesce(v_precio_oferta, v_precio);
    v_total := v_total + (v_precio_efectivo * v_cantidad);

    insert into public.order_items (order_id, product_id, product_name, quantity, unit_price, tenant_id)
    values (v_order_id, v_product_id, v_nombre, v_cantidad, v_precio_efectivo, v_tenant_id);

    -- Descuento atómico: solo aplica si en este instante hay stock suficiente,
    -- y solo dentro del mismo tenant (ya garantizado por el lookup de arriba).
    update public.products
    set stock = stock - v_cantidad
    where id = v_product_id and tenant_id = v_tenant_id and stock >= v_cantidad;

    if not found then
      raise exception 'INSUFFICIENT_STOCK: %', v_nombre;
    end if;
  end loop;

  update public.orders set total = v_total where id = v_order_id;

  if p_payment_status = 'paid' then
    select * into v_cfg from public.loyalty_config where tenant_id = v_tenant_id;
    if v_cfg.activo and v_cfg.gana_por_pedidos and v_total > 0 then
      insert into public.loyalty_points (profile_id, origen, origen_id, puntos, descripcion, tenant_id)
      values (v_client_id, 'pedido', v_order_id, floor(v_total / v_cfg.monto_por_punto), 'Pedido pagado', v_tenant_id);
    end if;
  end if;

  return v_order_id;
end;
$$;

-- ============================================================================
-- actualizar_estado_reserva — corrige el mismo bug de loyalty_config.
-- ============================================================================
create or replace function public.actualizar_estado_reserva(
  p_booking_id uuid,
  p_status text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_tenant_id uuid;
  v_booking public.bookings%rowtype;
  v_commission numeric;
  v_cfg public.loyalty_config%rowtype;
begin
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select * into v_booking from public.bookings
  where id = p_booking_id and tenant_id = v_tenant_id for update;
  if v_booking.id is null then
    raise exception 'NOT_FOUND';
  end if;
  if not (v_booking.employee_id = v_uid or public.is_admin_or_sysadmin()) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  if v_booking.status = p_status then
    return;
  end if;

  update public.bookings set status = p_status where id = p_booking_id;

  if p_status = 'completed' then
    select amount into v_commission from public.commission_configs
    where service_id = v_booking.service_id and tenant_id = v_tenant_id;
    if v_commission is not null and v_commission > 0 then
      insert into public.commission_entries
        (employee_id, booking_id, service_id, service_name, service_price, commission_amount, tenant_id)
      select v_booking.employee_id, v_booking.id, s.id, s.name, s.price, v_commission, v_tenant_id
      from public.services s where s.id = v_booking.service_id;
    end if;

    insert into public.commission_entries
      (employee_id, booking_id, service_id, service_name, service_price, commission_amount, tenant_id)
    select v_booking.employee_id, v_booking.id, s.id, s.name, s.price, cc.amount, v_tenant_id
    from public.booking_extra_services bes
    join public.services s on s.id = bes.service_id
    join public.commission_configs cc on cc.service_id = s.id and cc.amount > 0 and cc.tenant_id = v_tenant_id
    where bes.booking_id = v_booking.id;

    select * into v_cfg from public.loyalty_config where tenant_id = v_tenant_id;
    if v_cfg.activo and v_cfg.gana_por_reservas and v_booking.total_price > 0 then
      insert into public.loyalty_points (profile_id, origen, origen_id, puntos, descripcion, tenant_id)
      values (
        v_booking.client_id, 'reserva', v_booking.id,
        floor(v_booking.total_price / v_cfg.monto_por_punto),
        'Reserva completada', v_tenant_id
      );
    end if;
  end if;
end;
$$;

-- ============================================================================
-- actualizar_estado_pedido
-- ============================================================================
create or replace function public.actualizar_estado_pedido(
  p_order_id uuid,
  p_status text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_tenant_id uuid;
  v_estado_actual text;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select status into v_estado_actual from public.orders where id = p_order_id and tenant_id = v_tenant_id;
  if v_estado_actual is null then
    raise exception 'NOT_FOUND';
  end if;

  update public.orders
  set status = p_status, updated_at = now()
  where id = p_order_id and tenant_id = v_tenant_id;

  if p_status = 'cancelled' and v_estado_actual is distinct from 'cancelled' then
    update public.products p
    set stock = p.stock + oi.quantity
    from public.order_items oi
    where oi.order_id = p_order_id and oi.product_id = p.id and p.tenant_id = v_tenant_id;
  end if;
end;
$$;

-- ============================================================================
-- cancelar_reserva
-- ============================================================================
create or replace function public.cancelar_reserva(
  p_booking_id uuid,
  p_cancel_reason text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_tenant_id uuid := public.current_tenant_id();
begin
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  update public.bookings
  set status = 'cancelled', cancel_reason = p_cancel_reason
  where id = p_booking_id
    and tenant_id = v_tenant_id
    and (client_id = v_uid or employee_id = v_uid or public.is_admin_or_sysadmin());

  if not found then
    raise exception 'NOT_AUTHORIZED_OR_NOT_FOUND';
  end if;
end;
$$;

-- ============================================================================
-- solicitar_cancelacion_reserva
-- ============================================================================
create or replace function public.solicitar_cancelacion_reserva(p_booking_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_tenant_id uuid := public.current_tenant_id();
begin
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  update public.bookings
  set cancel_requested = true, cancel_requested_at = now()
  where id = p_booking_id
    and tenant_id = v_tenant_id
    and client_id = v_uid
    and status = 'confirmed';

  if not found then
    raise exception 'NOT_AUTHORIZED_OR_NOT_FOUND';
  end if;
end;
$$;

-- ============================================================================
-- process_commission_cut — corrige el bug real: antes agrupaba por
-- employee_id sin filtrar tenant, mezclando comisiones de negocios
-- distintos si compartían ventana de fechas.
-- ============================================================================
create or replace function public.process_commission_cut(
  p_week_start date,
  p_week_end date
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_tenant_id uuid;
  v_emp record;
  v_cut_id uuid;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  for v_emp in
    select employee_id, sum(commission_amount) as total, count(*) as cnt
    from public.commission_entries
    where tenant_id = v_tenant_id
      and cut_id is null
      and earned_at >= p_week_start::timestamptz
      and earned_at < (p_week_end + 1)::timestamptz
    group by employee_id
  loop
    insert into public.commission_cuts
      (employee_id, week_start, week_end, total_amount, services_count, status, tenant_id)
    values
      (v_emp.employee_id, p_week_start, p_week_end, v_emp.total, v_emp.cnt, 'pending', v_tenant_id)
    returning id into v_cut_id;

    update public.commission_entries
    set cut_id = v_cut_id
    where tenant_id = v_tenant_id
      and cut_id is null
      and employee_id = v_emp.employee_id
      and earned_at >= p_week_start::timestamptz
      and earned_at < (p_week_end + 1)::timestamptz;
  end loop;
end;
$$;

-- ============================================================================
-- ajustar_puntos_lealtad
-- ============================================================================
create or replace function public.ajustar_puntos_lealtad(
  p_profile_id uuid,
  p_puntos numeric,
  p_descripcion text default null
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_tenant_id uuid;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;
  if p_puntos = 0 then
    raise exception 'PUNTOS_REQUERIDOS';
  end if;

  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  if not exists (select 1 from public.profiles where id = p_profile_id and tenant_id = v_tenant_id) then
    raise exception 'PROFILE_NOT_FOUND';
  end if;

  insert into public.loyalty_points (profile_id, origen, puntos, descripcion, tenant_id)
  values (p_profile_id, 'ajuste_manual', p_puntos, p_descripcion, v_tenant_id);
end;
$$;

-- ============================================================================
-- get_available_slots — valida que el empleado consultado sea del mismo
-- tenant que el que llama (antes cualquier authenticated podía consultar
-- disponibilidad de un employee_id de cualquier negocio).
-- ============================================================================
create or replace function public.get_available_slots(
  p_employee_id uuid,
  p_date date,
  p_duration_min int
)
returns table(slot_start time, slot_end time)
language plpgsql security definer set search_path = public as $$
declare
  v_tenant_id uuid;
  v_dow text;
  v_start time;
  v_end time;
  v_cursor time;
  v_step interval := interval '30 minutes';
begin
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  if not exists (select 1 from public.profiles where id = p_employee_id and tenant_id = v_tenant_id) then
    return;
  end if;

  if exists (
    select 1 from public.employee_time_off
    where employee_id = p_employee_id and date = p_date and tenant_id = v_tenant_id
  ) then
    return;
  end if;

  v_dow := case extract(dow from p_date)::int
    when 0 then 'sunday'
    when 1 then 'monday'
    when 2 then 'tuesday'
    when 3 then 'wednesday'
    when 4 then 'thursday'
    when 5 then 'friday'
    when 6 then 'saturday'
  end;

  select start_time, end_time into v_start, v_end
  from public.work_schedules
  where employee_id = p_employee_id and day_of_week = v_dow and is_active = true and tenant_id = v_tenant_id
  limit 1;

  if v_start is null then
    return;
  end if;

  v_cursor := v_start;
  while v_cursor + (p_duration_min || ' minutes')::interval <= v_end loop
    if (p_date > current_date or v_cursor > current_time) and not exists (
      select 1 from public.bookings b
      where b.employee_id = p_employee_id
        and b.tenant_id = v_tenant_id
        and b.booking_date = p_date
        and b.status in ('pending','confirmed')
        and (v_cursor, v_cursor + (p_duration_min || ' minutes')::interval) overlaps (b.start_time, b.end_time)
    ) then
      slot_start := v_cursor;
      slot_end := v_cursor + (p_duration_min || ' minutes')::interval;
      return next;
    end if;
    v_cursor := v_cursor + v_step;
  end loop;
end;
$$;

-- ============================================================================
-- Triggers de notificaciones: ahora solo avisan a admins DEL MISMO TENANT
-- (antes notificaban a todos los admin/super_admin/sysadmin de la
-- plataforma, sin importar negocio) y fijan tenant_id en cada notificación.
-- ============================================================================
create or replace function public.notificar_nueva_reserva()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_cliente_nombre text;
  v_empleado_nombre text;
begin
  select full_name into v_cliente_nombre from public.profiles where id = new.client_id;
  select full_name into v_empleado_nombre from public.profiles where id = new.employee_id;

  insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
  values (
    new.employee_id,
    'Nueva reserva',
    coalesce(v_cliente_nombre, 'Un cliente') || ' reservó para el ' ||
      to_char(new.booking_date, 'DD/MM/YYYY') || ' a las ' || to_char(new.start_time, 'HH24:MI'),
    'booking_new',
    new.id,
    new.tenant_id
  );

  insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
  select id, 'Nueva reserva',
    coalesce(v_cliente_nombre, 'Un cliente') || ' reservó con ' ||
      coalesce(v_empleado_nombre, 'un empleado') || ' para el ' ||
      to_char(new.booking_date, 'DD/MM/YYYY') || ' a las ' || to_char(new.start_time, 'HH24:MI'),
    'booking_new',
    new.id,
    new.tenant_id
  from public.profiles
  where role in ('admin','super_admin','sysadmin') and id <> new.employee_id and tenant_id = new.tenant_id;

  return new;
end;
$$;

create or replace function public.notificar_cambio_reserva()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_titulo text;
  v_cuerpo_cliente text;
  v_cuerpo_admin text;
  v_cliente_nombre text;
begin
  select full_name into v_cliente_nombre from public.profiles where id = new.client_id;

  if new.status is distinct from old.status then
    if new.status = 'confirmed' then
      v_titulo := 'Reserva confirmada';
      v_cuerpo_cliente := 'Tu reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue confirmada.';
    elsif new.status = 'cancelled' then
      v_titulo := 'Reserva cancelada';
      v_cuerpo_cliente := 'Tu reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue cancelada.';
    elsif new.status = 'completed' then
      v_titulo := '¡Gracias por tu visita!';
      v_cuerpo_cliente := 'Tu servicio del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue completado.';
    else
      v_titulo := null;
    end if;

    if v_titulo is not null then
      insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
      values (new.client_id, v_titulo, v_cuerpo_cliente, 'booking_' || new.status, new.id, new.tenant_id);

      v_cuerpo_admin := 'La reserva de ' || coalesce(v_cliente_nombre, 'un cliente') ||
        ' del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' cambió a "' || new.status || '".';

      insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
      select id, v_titulo, v_cuerpo_admin, 'booking_' || new.status, new.id, new.tenant_id
      from public.profiles
      where role in ('admin','super_admin','sysadmin') and tenant_id = new.tenant_id;
    end if;
  end if;

  if new.cancel_requested and not old.cancel_requested then
    insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
    select id, 'Solicitud de cancelación',
      coalesce(v_cliente_nombre, 'Un cliente') || ' solicitó cancelar su reserva del ' ||
        to_char(new.booking_date,'DD/MM/YYYY') || '.',
      'booking_cancel_requested', new.id, new.tenant_id
    from public.profiles
    where role in ('admin','super_admin','sysadmin') and tenant_id = new.tenant_id;
  end if;

  if old.cancel_requested and not new.cancel_requested and new.status = 'confirmed' then
    insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
    values (new.client_id, 'Solicitud de cancelación rechazada',
      'Tu solicitud para cancelar la reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') ||
        ' fue rechazada. La reserva sigue confirmada.',
      'booking_cancel_rejected', new.id, new.tenant_id);
  end if;

  return new;
end;
$$;

create or replace function public.notificar_nuevo_pedido()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
  select id, 'Nuevo pedido',
    'Se recibió un nuevo pedido por $' || new.total::text,
    'order_new', new.id, new.tenant_id
  from public.profiles
  where role in ('admin','super_admin','sysadmin') and tenant_id = new.tenant_id;
  return new;
end;
$$;
