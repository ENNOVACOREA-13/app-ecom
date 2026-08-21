-- Corte de caja: reporte de periodo + reinicio de contadores.
--
-- Diseño elegido (ver plan): un "boundary" por fecha en vez de marcar
-- filas individuales (a diferencia de commission_entries.cut_id). Una
-- fila en caja_cuts guarda el rango [period_start, period_end] de cada
-- corte; "periodo actual" es todo lo posterior al period_end del último
-- corte (o desde siempre, si es el primero). Cero columnas nuevas en
-- bookings/orders/supply_purchases — nunca se tocan, solo se leen con
-- un filtro de fecha, así que ningún dato real se borra ni se modifica.

create table if not exists public.caja_cuts (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null default public.current_tenant_id() references public.tenants(id) on delete cascade,
  period_start            timestamptz not null,
  period_end              timestamptz not null default now(),
  ingresos_servicios      numeric(12,2) not null default 0,
  ingresos_tienda         numeric(12,2) not null default 0,
  ingresos_totales        numeric(12,2) not null default 0,
  comisiones_pendientes   numeric(12,2) not null default 0,
  insumos_comprados       numeric(12,2) not null default 0,
  ganancias_netas         numeric(12,2) not null default 0,
  servicios_completados   int not null default 0,
  pedidos_total           int not null default 0,
  pedidos_pendientes      int not null default 0,
  created_by              uuid references public.profiles(id) on delete set null,
  created_at              timestamptz not null default now()
);
create index if not exists idx_caja_cuts_tenant on public.caja_cuts(tenant_id, period_end desc);

-- Desglose por empleado dentro de un corte — snapshot del nombre para
-- que un corte viejo se siga viendo igual aunque el empleado cambie de
-- nombre o se borre la cuenta después.
create table if not exists public.caja_cut_employee_stats (
  id                      uuid primary key default gen_random_uuid(),
  cut_id                  uuid not null references public.caja_cuts(id) on delete cascade,
  tenant_id               uuid not null default public.current_tenant_id() references public.tenants(id) on delete cascade,
  employee_id             uuid references public.profiles(id) on delete set null,
  employee_name           text not null,
  servicios_completados   int not null default 0,
  ingresos                numeric(12,2) not null default 0,
  comisiones              numeric(12,2) not null default 0
);
create index if not exists idx_caja_cut_employee_stats_cut on public.caja_cut_employee_stats(cut_id);

alter table public.caja_cuts enable row level security;
alter table public.caja_cut_employee_stats enable row level security;

drop policy if exists caja_cuts_select_admin on public.caja_cuts;
create policy caja_cuts_select_admin on public.caja_cuts
  for select
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists caja_cut_employee_stats_select_admin on public.caja_cut_employee_stats;
create policy caja_cut_employee_stats_select_admin on public.caja_cut_employee_stats
  for select
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

-- Sin política de INSERT/UPDATE/DELETE para ningún rol: las únicas
-- filas que existen las crea generar_corte_caja() (SECURITY DEFINER,
-- ve abajo), nunca un insert directo del cliente.

-- ── Cálculo del resumen (una sola fuente de verdad) ──────────────────
-- La usan tanto la vista en vivo (obtener_resumen_periodo_actual) como
-- el corte real (generar_corte_caja) — mismo cálculo exacto en los dos
-- casos, para que "lo que ves antes de cortar" sea lo que el corte
-- guarda.
--
-- Campo de fecha por tabla (para no dejar ingresos "atrapados" en un
-- corte ya cerrado si se completan/registran tarde):
--   bookings: paid_at (se llena solo al pasar a 'completed')
--   orders: created_at (no tiene paid_at propio; flujo actual es solo
--     efectivo, se cobra al momento)
--   commission_entries: earned_at (mismo campo que ya usa
--     process_commission_cut)
--   supply_purchases: created_at (inmutable; purchased_at es una fecha
--     editable por el admin, no sirve como boundary)
create or replace function public.calcular_resumen_periodo(p_desde timestamptz, p_hasta timestamptz)
returns table (
  ingresos_servicios      numeric,
  ingresos_tienda         numeric,
  ingresos_totales        numeric,
  comisiones_pendientes   numeric,
  insumos_comprados       numeric,
  ganancias_netas         numeric,
  servicios_completados   int,
  pedidos_total           int,
  pedidos_pendientes      int
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tenant_id uuid;
  v_ingresos_servicios numeric;
  v_ingresos_tienda numeric;
  v_comisiones numeric;
  v_insumos numeric;
  v_servicios_completados int;
  v_pedidos_total int;
  v_pedidos_pendientes int;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select coalesce(sum(total_price), 0), count(*)
    into v_ingresos_servicios, v_servicios_completados
  from public.bookings
  where tenant_id = v_tenant_id and status = 'completed'
    and paid_at > p_desde and paid_at <= p_hasta;

  select coalesce(sum(total), 0), count(*),
         count(*) filter (where status = 'pending')
    into v_ingresos_tienda, v_pedidos_total, v_pedidos_pendientes
  from public.orders
  where tenant_id = v_tenant_id and status <> 'cancelled'
    and created_at > p_desde and created_at <= p_hasta;

  select coalesce(sum(commission_amount), 0) into v_comisiones
  from public.commission_entries
  where tenant_id = v_tenant_id and cut_id is null
    and earned_at > p_desde and earned_at <= p_hasta;

  select coalesce(sum(total_cost), 0) into v_insumos
  from public.supply_purchases
  where tenant_id = v_tenant_id
    and created_at > p_desde and created_at <= p_hasta;

  return query select
    v_ingresos_servicios,
    v_ingresos_tienda,
    v_ingresos_servicios + v_ingresos_tienda,
    v_comisiones,
    v_insumos,
    (v_ingresos_servicios + v_ingresos_tienda) - v_comisiones - v_insumos,
    v_servicios_completados,
    v_pedidos_total,
    v_pedidos_pendientes;
end;
$$;

-- ── Resumen del periodo actual (solo lectura, para el dashboard) ────
create or replace function public.obtener_resumen_periodo_actual()
returns table (
  ingresos_servicios      numeric,
  ingresos_tienda         numeric,
  ingresos_totales        numeric,
  comisiones_pendientes   numeric,
  insumos_comprados       numeric,
  ganancias_netas         numeric,
  servicios_completados   int,
  pedidos_total           int,
  pedidos_pendientes      int,
  period_start            timestamptz
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tenant_id uuid;
  v_desde timestamptz;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select coalesce(max(cc.period_end), '-infinity'::timestamptz) into v_desde
  from public.caja_cuts cc where cc.tenant_id = v_tenant_id;

  return query
    select r.*, v_desde
    from public.calcular_resumen_periodo(v_desde, now()) r;
end;
$$;

-- ── Resumen del periodo actual para UN empleado (su propio dashboard) ──
-- Sin parámetro de employee_id: siempre auth.uid(), para que un
-- empleado nunca pueda pedir el resumen de otro solo cambiando un id.
create or replace function public.obtener_resumen_periodo_actual_empleado()
returns table (
  servicios_completados   int,
  servicios_pendientes    int,
  servicios_cancelados    int,
  ingresos                numeric,
  comisiones_pendientes   numeric,
  period_start            timestamptz
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tenant_id uuid;
  v_uid uuid := auth.uid();
  v_desde timestamptz;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select coalesce(max(cc.period_end), '-infinity'::timestamptz) into v_desde
  from public.caja_cuts cc where cc.tenant_id = v_tenant_id;

  return query
    select
      count(*) filter (where b.status = 'completed' and b.paid_at > v_desde)::int,
      count(*) filter (where b.status in ('pending','confirmed'))::int,
      count(*) filter (where b.status = 'cancelled' and b.created_at > v_desde)::int,
      coalesce(sum(b.total_price) filter (where b.status = 'completed' and b.paid_at > v_desde), 0),
      (select coalesce(sum(ce.commission_amount), 0) from public.commission_entries ce
        where ce.employee_id = v_uid and ce.tenant_id = v_tenant_id and ce.cut_id is null
          and ce.earned_at > v_desde),
      v_desde
    from public.bookings b
    where b.employee_id = v_uid and b.tenant_id = v_tenant_id;
end;
$$;

-- ── Generar un corte real (persiste el snapshot) ─────────────────────
create or replace function public.generar_corte_caja()
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tenant_id uuid;
  v_desde timestamptz;
  v_hasta timestamptz := now();
  v_cut_id uuid;
  v_resumen record;
  v_emp record;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select coalesce(max(cc.period_end), '-infinity'::timestamptz) into v_desde
  from public.caja_cuts cc where cc.tenant_id = v_tenant_id;

  select * into v_resumen from public.calcular_resumen_periodo(v_desde, v_hasta);

  insert into public.caja_cuts (
    tenant_id, period_start, period_end,
    ingresos_servicios, ingresos_tienda, ingresos_totales,
    comisiones_pendientes, insumos_comprados, ganancias_netas,
    servicios_completados, pedidos_total, pedidos_pendientes, created_by
  ) values (
    v_tenant_id, v_desde, v_hasta,
    v_resumen.ingresos_servicios, v_resumen.ingresos_tienda, v_resumen.ingresos_totales,
    v_resumen.comisiones_pendientes, v_resumen.insumos_comprados, v_resumen.ganancias_netas,
    v_resumen.servicios_completados, v_resumen.pedidos_total, v_resumen.pedidos_pendientes,
    auth.uid()
  ) returning id into v_cut_id;

  for v_emp in
    select
      p.id as employee_id,
      p.full_name as employee_name,
      count(b.id) as servicios_completados,
      coalesce(sum(b.total_price), 0) as ingresos,
      coalesce((
        select sum(ce.commission_amount) from public.commission_entries ce
        where ce.employee_id = p.id and ce.tenant_id = v_tenant_id
          and ce.cut_id is null and ce.earned_at > v_desde and ce.earned_at <= v_hasta
      ), 0) as comisiones
    from public.profiles p
    left join public.bookings b
      on b.employee_id = p.id and b.tenant_id = v_tenant_id
      and b.status = 'completed' and b.paid_at > v_desde and b.paid_at <= v_hasta
    where p.tenant_id = v_tenant_id and p.role = 'employee'
    group by p.id, p.full_name
  loop
    -- Solo se guarda si de verdad hubo algo en el periodo — un empleado
    -- sin actividad no aporta nada al desglose de este corte.
    if v_emp.servicios_completados > 0 or v_emp.comisiones > 0 then
      insert into public.caja_cut_employee_stats (
        cut_id, tenant_id, employee_id, employee_name,
        servicios_completados, ingresos, comisiones
      ) values (
        v_cut_id, v_tenant_id, v_emp.employee_id, v_emp.employee_name,
        v_emp.servicios_completados, v_emp.ingresos, v_emp.comisiones
      );
    end if;
  end loop;

  return v_cut_id;
end;
$$;
