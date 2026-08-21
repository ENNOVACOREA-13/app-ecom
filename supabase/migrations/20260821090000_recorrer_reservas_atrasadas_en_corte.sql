-- Pedido del usuario: al generar un corte, cualquier reserva que siga
-- pendiente/confirmada (nunca se completó ni se canceló) con fecha ya
-- pasada se recorre a HOY. Evita que una reserva "olvidada" de días
-- atrás se complete después del corte y quede con una fecha de reserva
-- vieja mientras sus ingresos ya cuentan para el periodo siguiente (por
-- paid_at, que es el campo real que decide a qué corte pertenece un
-- ingreso — eso no cambia aquí). Nunca toca reservas completed ni
-- cancelled: esas son historial real, no se modifican.
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
          and ce.earned_at > v_desde and ce.earned_at <= v_hasta
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

  update public.bookings
  set booking_date = (now() at time zone 'America/Mexico_City')::date
  where tenant_id = v_tenant_id
    and status in ('pending', 'confirmed')
    and booking_date < (now() at time zone 'America/Mexico_City')::date;

  return v_cut_id;
end;
$$;
