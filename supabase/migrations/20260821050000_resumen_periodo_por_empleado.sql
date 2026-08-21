-- Desglose por empleado del periodo actual EN VIVO (no solo al momento
-- de generar un corte) — lo necesita el dashboard de admin para
-- "Rendimiento por empleado", que antes leía la vista employee_stats
-- (de toda la vida). Misma lógica de agrupación que ya usa
-- generar_corte_caja() en su loop, solo que aquí no se guarda nada.
create or replace function public.obtener_resumen_periodo_actual_por_empleado()
returns table (
  employee_id             uuid,
  employee_name           text,
  servicios_completados   int,
  ingresos                numeric,
  comisiones              numeric
)
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tenant_id uuid;
  v_desde timestamptz;
  v_hasta timestamptz := now();
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
    select
      p.id,
      p.full_name,
      count(b.id)::int,
      coalesce(sum(b.total_price), 0),
      coalesce((
        select sum(ce.commission_amount) from public.commission_entries ce
        where ce.employee_id = p.id and ce.tenant_id = v_tenant_id
          and ce.cut_id is null and ce.earned_at > v_desde and ce.earned_at <= v_hasta
      ), 0)
    from public.profiles p
    left join public.bookings b
      on b.employee_id = p.id and b.tenant_id = v_tenant_id
      and b.status = 'completed' and b.paid_at > v_desde and b.paid_at <= v_hasta
    where p.tenant_id = v_tenant_id and p.role = 'employee'
    group by p.id, p.full_name
    order by coalesce(sum(b.total_price), 0) desc;
end;
$$;
