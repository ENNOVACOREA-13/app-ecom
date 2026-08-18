-- notificar_cambio_reserva solo revisaba cambios de `status`, así que ni
-- "solicitar cancelación" (solicitar_cancelacion_reserva, solo cambia
-- cancel_requested) ni "Rechazar" (solo revierte cancel_requested) disparaban
-- ninguna notificación — el admin nunca se enteraba de la solicitud, y el
-- cliente nunca se enteraba de que fue rechazada.

create or replace function public.notificar_cambio_reserva()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_titulo text;
  v_cuerpo_cliente text;
  v_cuerpo_admin text;
  v_cliente_nombre text;
begin
  select full_name into v_cliente_nombre from public.profiles where id = new.client_id;

  if new.status is distinct from old.status then
    if new.status = 'confirmed' then
      v_titulo := 'Reserva confirmada';
      v_cuerpo_cliente := 'Tu reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue confirmada.';
    elsif new.status = 'cancelled' then
      v_titulo := 'Reserva cancelada';
      v_cuerpo_cliente := 'Tu reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue cancelada.';
    elsif new.status = 'completed' then
      v_titulo := '¡Gracias por tu visita!';
      v_cuerpo_cliente := 'Tu servicio del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue completado.';
    else
      v_titulo := null;
    end if;

    if v_titulo is not null then
      insert into public.notifications (user_id, title, body, type, related_id)
      values (new.client_id, v_titulo, v_cuerpo_cliente,
        'booking_' || new.status, new.id);

      v_cuerpo_admin := 'La reserva de ' || coalesce(v_cliente_nombre, 'un cliente') ||
        ' del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' cambió a "' || new.status || '".';

      insert into public.notifications (user_id, title, body, type, related_id)
      select id, v_titulo, v_cuerpo_admin, 'booking_' || new.status, new.id
      from public.profiles
      where role in ('admin','super_admin','sysadmin');
    end if;
  end if;

  -- Cliente solicitó cancelar (reserva sigue 'confirmed', solo cambió el flag)
  if new.cancel_requested and not old.cancel_requested then
    insert into public.notifications (user_id, title, body, type, related_id)
    select id, 'Solicitud de cancelación',
      coalesce(v_cliente_nombre, 'Un cliente') || ' solicitó cancelar su reserva del ' ||
        to_char(new.booking_date,'DD/MM/YYYY') || '.',
      'booking_cancel_requested', new.id
    from public.profiles
    where role in ('admin','super_admin','sysadmin');
  end if;

  -- Admin rechazó la solicitud (cancel_requested vuelve a false, pero la
  -- reserva sigue 'confirmed' — si en cambio se aprobó, status ya cambió a
  -- 'cancelled' arriba y el cliente ya fue notificado de eso, no de esto).
  if old.cancel_requested and not new.cancel_requested and new.status = 'confirmed' then
    insert into public.notifications (user_id, title, body, type, related_id)
    values (new.client_id, 'Solicitud de cancelación rechazada',
      'Tu solicitud para cancelar la reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') ||
        ' fue rechazada. La reserva sigue confirmada.',
      'booking_cancel_rejected', new.id);
  end if;

  return new;
end;
$$;
