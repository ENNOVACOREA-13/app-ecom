-- Dos bugs en get_available_slots, encontrados investigando la duda del
-- usuario sobre walk-ins con horario "atrasado por minutos":
--
-- 1. BUG GRAVE preexistente, mucho más grande de lo que se estaba
--    preguntando: la función comparaba contra current_date/current_time,
--    que en Postgres corren en UTC (confirmado: current_setting('TIMEZONE')
--    = 'UTC' en este proyecto) — pero los horarios de trabajo
--    (work_schedules.start_time/end_time, ej. 11:00-20:00) siempre se
--    capturaron pensando en hora LOCAL de México (UTC-6). Con esa
--    diferencia de 6 horas, la comparación "v_cursor > current_time"
--    trataba como "ya pasado" cualquier horario de hoy después de
--    aproximadamente medio día local — un cliente normal reservando
--    "hoy" en la tarde prácticamente nunca veía horarios disponibles,
--    aunque el negocio siguiera abierto varias horas más. Nunca se
--    detectó porque todas las reservas de prueba de este proyecto se
--    hicieron para el día SIGUIENTE (p_date > current_date, que sí
--    evade por completo esta comparación de hora). Se corrige calculando
--    "ahora" explícitamente en America/Mexico_City en vez de depender
--    del timezone de sesión de Postgres.
--
-- 2. El pedido original del usuario: admin/sysadmin/el propio empleado
--    consultado SÍ deben poder ver (y por lo tanto reservar) un horario
--    de hoy que ya pasó por minutos, para meter a un walk-in que llegó
--    de improviso — siempre que no choque con otra cita ya existente.
--    Un cliente reservando para sí mismo sigue sin poder elegir un
--    horario ya pasado.
create or replace function public.get_available_slots(
  p_employee_id uuid,
  p_date date,
  p_duration_min int
)
returns table(slot_start time, slot_end time)
language plpgsql security definer set search_path = public as $$
declare
  v_tenant_id uuid;
  v_uid uuid := auth.uid();
  v_dow text;
  v_start time;
  v_end time;
  v_cursor time;
  v_step interval := interval '30 minutes';
  v_es_staff boolean;
  v_fecha_local date := (now() at time zone 'America/Mexico_City')::date;
  v_hora_local time := (now() at time zone 'America/Mexico_City')::time;
begin
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  if not exists (select 1 from public.profiles where id = p_employee_id and tenant_id = v_tenant_id) then
    return;
  end if;

  v_es_staff := public.is_admin_or_sysadmin() or v_uid = p_employee_id;

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
    if (p_date > v_fecha_local or (p_date = v_fecha_local and v_cursor > v_hora_local) or v_es_staff) and not exists (
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
