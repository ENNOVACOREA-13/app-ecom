-- crear_reserva hacía "select exists(overlap) -> insert" sin ningún lock:
-- bajo carga concurrente, dos clientes reservando el mismo horario del mismo
-- empleado en la misma fracción de segundo pueden pasar ambos el chequeo de
-- solapamiento antes de que cualquiera inserte, resultando en doble reserva.
--
-- Se agrega un advisory lock transaccional sobre (employee_id, fecha) justo
-- antes del chequeo: serializa solo las reservas que compiten por el mismo
-- empleado/día (no bloquea reservas de otros empleados u otras fechas), y se
-- libera automáticamente al terminar la transacción de la función.

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
  v_end_time time;
  v_booking_id uuid;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select duration_min into v_duration from public.services where id = p_service_id;
  if v_duration is null then
    raise exception 'SERVICE_NOT_FOUND';
  end if;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    select v_duration + coalesce(sum(duration_min), 0) into v_duration
    from public.services where id = any(p_extra_ids);
  end if;

  v_end_time := p_start_time + (v_duration || ' minutes')::interval;

  -- Serializa únicamente las reservas que compiten por el mismo empleado+día.
  perform pg_advisory_xact_lock(hashtext(p_employee_id::text), hashtext(p_date::text));

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
    (v_client_id, p_employee_id, p_service_id, p_date, p_start_time, v_end_time, p_total_price, p_notes)
  returning id into v_booking_id;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    insert into public.booking_extra_services (booking_id, service_id)
    select v_booking_id, unnest(p_extra_ids);
  end if;

  return query select * from public.bookings where id = v_booking_id;
end;
$$;
