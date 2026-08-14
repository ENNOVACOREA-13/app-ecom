-- crear_reserva recibía p_total_price directo del cliente y lo guardaba tal
-- cual, sin validarlo contra el precio real del servicio en la base de
-- datos (a diferencia de crear_pedido, que sí calcula el precio en el
-- servidor). Cualquiera con la anon key podía llamar el RPC directo
-- (saltándose la UI de Flutter) y crear una reserva con el precio que
-- quisiera, inflando o vaciando el total_price que ve el admin en reportes
-- de ingresos (employee_stats.ingresos_totales).
--
-- Se quita el parámetro p_total_price: el precio ahora se calcula siempre
-- en el servidor sumando el precio vigente del servicio principal + extras,
-- igual que ya se hacía en crear_pedido.

drop function if exists public.crear_reserva(uuid, uuid, date, time, numeric, text, uuid[]);

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
  v_duration int;
  v_precio numeric;
  v_end_time time;
  v_booking_id uuid;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select duration_min, price into v_duration, v_precio
  from public.services where id = p_service_id;
  if v_duration is null then
    raise exception 'SERVICE_NOT_FOUND';
  end if;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    select v_duration + coalesce(sum(duration_min), 0), v_precio + coalesce(sum(price), 0)
      into v_duration, v_precio
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
    (v_client_id, p_employee_id, p_service_id, p_date, p_start_time, v_end_time, v_precio, p_notes)
  returning id into v_booking_id;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    insert into public.booking_extra_services (booking_id, service_id)
    select v_booking_id, unnest(p_extra_ids);
  end if;

  return query select * from public.bookings where id = v_booking_id;
end;
$$;
grant execute on function public.crear_reserva(uuid, uuid, date, time, text, uuid[]) to authenticated;
