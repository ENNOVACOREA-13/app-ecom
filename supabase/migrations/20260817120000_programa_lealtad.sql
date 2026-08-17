-- ============================================================================
-- Programa de lealtad: puntos por reservas completadas y pedidos pagados.
-- Configuración simple (dos números) en vez de una "fórmula" libre — todos
-- los ejemplos pedidos ("cada $100 = 1 punto", "total/10 = puntos", "10% del
-- total = puntos") son la misma razón lineal con distinto valor:
--   puntos = monto_gastado / monto_por_punto
-- ============================================================================

-- ── loyalty_config (fila única, mismo patrón que app_config) ──────────────
create table if not exists public.loyalty_config (
  id                  boolean primary key default true,
  activo              boolean not null default true,
  nombre_programa     text not null default 'Programa de lealtad',
  monto_por_punto     numeric(10,2) not null default 100,
  puntos_por_peso_canje numeric(10,2) not null default 10,
  gana_por_reservas   boolean not null default true,
  gana_por_pedidos    boolean not null default true,
  updated_at          timestamptz not null default now(),
  constraint loyalty_config_singleton check (id),
  constraint loyalty_config_monto_positivo check (monto_por_punto > 0),
  constraint loyalty_config_canje_positivo check (puntos_por_peso_canje > 0)
);

insert into public.loyalty_config (id) values (true) on conflict (id) do nothing;

-- ── loyalty_points (ledger: una fila por movimiento, saldo = suma) ────────
create table if not exists public.loyalty_points (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  origen       text not null check (origen in ('reserva','pedido','ajuste_manual')),
  origen_id    uuid,
  puntos       numeric(10,2) not null,
  descripcion  text,
  created_at   timestamptz not null default now()
);

create index if not exists idx_loyalty_points_profile on public.loyalty_points(profile_id);

-- ── RLS ─────────────────────────────────────────────────────────────────
alter table public.loyalty_config enable row level security;
alter table public.loyalty_points enable row level security;

create policy "loyalty_config_select_public" on public.loyalty_config
  for select to anon, authenticated using (true);
create policy "loyalty_config_write_admin" on public.loyalty_config
  for all to authenticated using (public.is_admin_or_sysadmin()) with check (public.is_admin_or_sysadmin());

create policy "loyalty_points_select" on public.loyalty_points
  for select to authenticated using (profile_id = auth.uid() or public.is_admin_or_sysadmin());
-- Sin policy de insert/update/delete para authenticated: solo se escribe vía
-- las funciones security definer de abajo (evita que un cliente se regale
-- puntos insertando directo en la tabla).

-- ── Ajuste manual de puntos (admin/sysadmin) ───────────────────────────────
create or replace function public.ajustar_puntos_lealtad(
  p_profile_id uuid,
  p_puntos numeric,
  p_descripcion text default null
)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;
  if p_puntos = 0 then
    raise exception 'PUNTOS_REQUERIDOS';
  end if;

  insert into public.loyalty_points (profile_id, origen, puntos, descripcion)
  values (p_profile_id, 'ajuste_manual', p_puntos, p_descripcion);
end;
$$;
grant execute on function public.ajustar_puntos_lealtad(uuid, numeric, text) to authenticated;

-- ── actualizar_estado_reserva: agrega puntos al completar la reserva ──────
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
  v_cfg public.loyalty_config%rowtype;
begin
  select * into v_booking from public.bookings where id = p_booking_id for update;
  if v_booking.id is null then
    raise exception 'NOT_FOUND';
  end if;
  if not (v_booking.employee_id = v_uid or public.is_admin_or_sysadmin()) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  -- Ya estaba en ese estado: no hacer nada (evita comisiones/puntos duplicados)
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

    select * into v_cfg from public.loyalty_config where id = true;
    if v_cfg.activo and v_cfg.gana_por_reservas and v_booking.total_price > 0 then
      insert into public.loyalty_points (profile_id, origen, origen_id, puntos, descripcion)
      values (
        v_booking.client_id, 'reserva', v_booking.id,
        floor(v_booking.total_price / v_cfg.monto_por_punto),
        'Reserva completada'
      );
    end if;
  end if;
end;
$$;

-- ── crear_pedido: agrega puntos si el pedido se crea ya pagado ────────────
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
  v_cfg public.loyalty_config%rowtype;
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

    -- Descuento atómico: solo aplica si en este instante hay stock suficiente.
    update public.products
    set stock = stock - v_cantidad
    where id = v_product_id and stock >= v_cantidad;

    if not found then
      raise exception 'INSUFFICIENT_STOCK: %', v_nombre;
    end if;
  end loop;

  update public.orders set total = v_total where id = v_order_id;

  if p_payment_status = 'paid' then
    select * into v_cfg from public.loyalty_config where id = true;
    if v_cfg.activo and v_cfg.gana_por_pedidos and v_total > 0 then
      insert into public.loyalty_points (profile_id, origen, origen_id, puntos, descripcion)
      values (v_client_id, 'pedido', v_order_id, floor(v_total / v_cfg.monto_por_punto), 'Pedido pagado');
    end if;
  end if;

  return v_order_id;
end;
$$;
