-- process_commission_cut() solo tomaba entradas cuyo earned_at cayera DENTRO
-- del rango que mandaba el admin (normalmente "la semana actual"). Si nadie
-- procesaba un corte una semana, esas comisiones se quedaban con cut_id
-- null para siempre — invisibles en el dashboard del empleado (que solo
-- mira "esta semana") pero seguían sumando en el total de comisiones del
-- negocio, así que las cuentas no cuadraban entre lo que veía el empleado y
-- lo que mostraba el admin. Encontrado en vivo 2026-08-19: un empleado con
-- $55 en comisiones de hace 1-2 semanas (nunca cortadas) veía $0.00 en su
-- "Acumulado".
--
-- Ahora el corte barre TODO lo pendiente (cut_id is null) con earned_at
-- hasta la fecha dada — ya no hay forma de que quede un residuo sin
-- cortar. week_start de cada corte generado ya no es el lunes que eligió
-- el admin, sino el earned_at más viejo de lo que realmente se incluyó —
-- así el historial de Cortes describe con precisión qué cubre cada uno,
-- en vez de mentir con un rango fijo semanal.
-- create or replace exige la MISMA firma para reemplazar — la firma vieja
-- tenía 2 parámetros (p_week_start, p_week_end), la nueva tiene 1, así que
-- sin este drop quedarían las dos versiones sobrecargadas a la vez.
drop function if exists public.process_commission_cut(date, date);

create or replace function public.process_commission_cut(p_hasta date)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
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
    select employee_id, sum(commission_amount) as total, count(*) as cnt,
           min(earned_at) as primera
    from public.commission_entries
    where tenant_id = v_tenant_id
      and cut_id is null
      and earned_at < (p_hasta + 1)::timestamptz
    group by employee_id
  loop
    insert into public.commission_cuts
      (employee_id, week_start, week_end, total_amount, services_count, status, tenant_id)
    values
      (v_emp.employee_id, v_emp.primera::date, p_hasta, v_emp.total, v_emp.cnt, 'pending', v_tenant_id)
    returning id into v_cut_id;

    update public.commission_entries
    set cut_id = v_cut_id
    where tenant_id = v_tenant_id
      and cut_id is null
      and employee_id = v_emp.employee_id
      and earned_at < (p_hasta + 1)::timestamptz;
  end loop;
end;
$function$;
