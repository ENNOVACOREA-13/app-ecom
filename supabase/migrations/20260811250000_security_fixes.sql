-- ============================================================================
-- FIX 1 (crítico): profiles exponía email/teléfono de TODOS los usuarios a
-- cualquier usuario autenticado. Se restringe a "propio perfil o admin/sysadmin"
-- y se crea una vista pública sin columnas sensibles para los usos legítimos
-- de mostrar nombre/avatar de OTROS usuarios (ej. elegir especialista).
-- ============================================================================

drop policy if exists "profiles_select_authenticated" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles
  for select to authenticated using (id = auth.uid() or public.is_admin_or_sysadmin());

create or replace view public.profiles_public as
select id, full_name, avatar_url, role, bio, is_active, created_at
from public.profiles;

grant select on public.profiles_public to anon, authenticated;

-- Vistas que mostraban nombre de OTROS usuarios ahora usan la vista pública,
-- para que sigan funcionando igual sin depender de acceso directo a profiles.
create or replace view public.bookings_detailed
with (security_invoker = true) as
select
  b.id, b.client_id, b.employee_id, b.service_id,
  b.booking_date, b.start_time, b.end_time,
  b.status, b.total_price, b.notes, b.cancel_reason, b.created_at,
  c.full_name  as client_name,
  e.full_name  as employee_name,
  s.name       as service_name,
  s.duration_min,
  b.cancel_requested, b.cancel_requested_at
from public.bookings b
join public.profiles_public c on c.id = b.client_id
join public.profiles_public e on e.id = b.employee_id
join public.services s on s.id = b.service_id;

create or replace view public.employee_stats
with (security_invoker = true) as
select
  p.id as employee_id,
  p.full_name,
  count(*) filter (where b.status = 'completed')                              as total_completadas,
  count(*) filter (where b.status = 'pending')                                as total_pendientes,
  count(*) filter (where b.status = 'cancelled')                              as total_canceladas,
  coalesce(sum(b.total_price) filter (where b.status = 'completed'), 0)       as ingresos_totales,
  (select round(avg(r.rating)::numeric, 1) from public.reviews r where r.employee_id = p.id) as rating_promedio,
  (select count(*) from public.reviews r where r.employee_id = p.id)          as total_reviews
from public.profiles_public p
left join public.bookings b on b.employee_id = p.id
where p.role = 'employee'
group by p.id, p.full_name;

-- ============================================================================
-- FIX 2 (crítico): el precio de reservas y pedidos lo mandaba el cliente sin
-- validarlo contra el precio real. Se recalcula del lado del servidor.
-- ============================================================================

-- crear_reserva: ignora p_total_price (se deja el parámetro por compatibilidad)
-- y calcula el total real desde el precio de los servicios en la base de datos.
create or replace function public.crear_reserva(
  p_employee_id uuid,
  p_service_id uuid,
  p_date date,
  p_start_time time,
  p_total_price numeric,
  p_notes text,
  p_extra_ids uuid[]
)
returns setof public.bookings
language plpgsql security definer set search_path = public as $$
declare
  v_client_id uuid := auth.uid();
  v_duration int;
  v_base_price numeric;
  v_extras_duration int := 0;
  v_extras_price numeric := 0;
  v_real_total numeric;
  v_end_time time;
  v_booking_id uuid;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select duration_min, price into v_duration, v_base_price
  from public.services where id = p_service_id;
  if v_duration is null then
    raise exception 'SERVICE_NOT_FOUND';
  end if;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    select coalesce(sum(duration_min), 0), coalesce(sum(price), 0)
      into v_extras_duration, v_extras_price
    from public.services where id = any(p_extra_ids);
  end if;

  v_duration := v_duration + v_extras_duration;
  v_real_total := v_base_price + v_extras_price;
  v_end_time := p_start_time + (v_duration || ' minutes')::interval;

  if exists (
    select 1 from public.bookings b
    where b.employee_id = p_employee_id
      and b.booking_date = p_date
      and b.status in ('pending','confirmed')
      and (p_start_time, v_end_time) overlaps (b.start_time, b.end_time)
  ) then
    raise exception 'BOOKING_CONFLICT';
  end if;

  insert into public.bookings
    (client_id, employee_id, service_id, booking_date, start_time, end_time, total_price, notes)
  values
    (v_client_id, p_employee_id, p_service_id, p_date, p_start_time, v_end_time, v_real_total, p_notes)
  returning id into v_booking_id;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    insert into public.booking_extra_services (booking_id, service_id)
    select v_booking_id, unnest(p_extra_ids);
  end if;

  return query select * from public.bookings where id = v_booking_id;
end;
$$;
grant execute on function public.crear_reserva(uuid, uuid, date, time, numeric, text, uuid[]) to authenticated;

-- crear_pedido: nueva función que reemplaza los inserts directos a orders/order_items
-- desde el cliente. Calcula el precio real (con oferta si aplica) del lado del servidor.
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
  v_order_id uuid;
  v_total numeric := 0;
  v_item jsonb;
  v_product_id uuid;
  v_cantidad int;
  v_nombre text;
  v_precio numeric;
  v_precio_oferta numeric;
  v_precio_efectivo numeric;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_CART';
  end if;

  insert into public.orders (client_id, total, payment_method, payment_status, stripe_payment_id, notes)
  values (v_client_id, 0, p_payment_method, p_payment_status, p_stripe_payment_id, p_notes)
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := (v_item->>'product_id')::uuid;
    v_cantidad := (v_item->>'cantidad')::int;
    if v_cantidad is null or v_cantidad <= 0 then
      raise exception 'INVALID_QUANTITY';
    end if;

    select name, price, sale_price into v_nombre, v_precio, v_precio_oferta
    from public.products where id = v_product_id;
    if v_nombre is null then
      raise exception 'PRODUCT_NOT_FOUND';
    end if;

    v_precio_efectivo := coalesce(v_precio_oferta, v_precio);
    v_total := v_total + (v_precio_efectivo * v_cantidad);

    insert into public.order_items (order_id, product_id, product_name, quantity, unit_price)
    values (v_order_id, v_product_id, v_nombre, v_cantidad, v_precio_efectivo);

    update public.products
    set stock = greatest(stock - v_cantidad, 0)
    where id = v_product_id;
  end loop;

  update public.orders set total = v_total where id = v_order_id;

  return v_order_id;
end;
$$;
grant execute on function public.crear_pedido(jsonb, text, text, text, text) to authenticated;

-- Ya no se permite insertar directo en orders/order_items desde el cliente:
-- todo pedido debe crearse vía crear_pedido() para que el precio se valide.
drop policy if exists "orders_insert_own" on public.orders;
drop policy if exists "order_items_insert" on public.order_items;

-- ============================================================================
-- FIX 3 (medio): actualizar_estado_reserva podía insertar comisión duplicada
-- si se llamaba dos veces con el mismo estado 'completed' para una reserva.
-- ============================================================================

create or replace function public.actualizar_estado_reserva(
  p_booking_id uuid,
  p_status text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_booking public.bookings%rowtype;
  v_commission numeric;
begin
  select * into v_booking from public.bookings where id = p_booking_id;
  if v_booking.id is null then
    raise exception 'NOT_FOUND';
  end if;
  if not (v_booking.employee_id = v_uid or public.is_admin_or_sysadmin()) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  -- Ya estaba en ese estado: no hacer nada (evita comisiones duplicadas)
  if v_booking.status = p_status then
    return;
  end if;

  update public.bookings set status = p_status where id = p_booking_id;

  if p_status = 'completed' then
    select amount into v_commission from public.commission_configs where service_id = v_booking.service_id;
    if v_commission is not null and v_commission > 0 then
      insert into public.commission_entries
        (employee_id, booking_id, service_id, service_name, service_price, commission_amount)
      select v_booking.employee_id, v_booking.id, s.id, s.name, s.price, v_commission
      from public.services s where s.id = v_booking.service_id;
    end if;

    insert into public.commission_entries
      (employee_id, booking_id, service_id, service_name, service_price, commission_amount)
    select v_booking.employee_id, v_booking.id, s.id, s.name, s.price, cc.amount
    from public.booking_extra_services bes
    join public.services s on s.id = bes.service_id
    join public.commission_configs cc on cc.service_id = s.id and cc.amount > 0
    where bes.booking_id = v_booking.id;
  end if;
end;
$$;
grant execute on function public.actualizar_estado_reserva(uuid, text) to authenticated;
