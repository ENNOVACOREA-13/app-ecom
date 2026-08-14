-- actualizar_estado_reserva ya evita comisión duplicada cuando se llama dos
-- veces SECUENCIALMENTE (v_booking.status = p_status → return temprano),
-- pero el SELECT inicial no bloqueaba la fila: dos llamadas CONCURRENTES
-- para la misma reserva (p.ej. doble escaneo casi simultáneo del mismo QR,
-- o dos pestañas/dispositivos del mismo empleado) podían leer ambas
-- status='confirmed' antes de que cualquiera escribiera, y las dos
-- insertar commission_entries — pagando comisión doble por la misma cita.
--
-- Se agrega FOR UPDATE al SELECT: la segunda transacción concurrente queda
-- bloqueada hasta que la primera termine, y al reintentar su lectura ya ve
-- el status actualizado, cayendo en el "ya estaba en ese estado" existente.

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
  select * into v_booking from public.bookings where id = p_booking_id for update;
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
