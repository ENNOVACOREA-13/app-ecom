-- ── Admin/sysadmin también deben recibir notificaciones de reservas ───────
-- Antes solo se notificaba al empleado (reserva nueva) o al cliente (cambio
-- de estado). Ahora admin/super_admin/sysadmin reciben ambas también.

create or replace function public.notificar_nueva_reserva()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_cliente_nombre text;
  v_empleado_nombre text;
begin
  select full_name into v_cliente_nombre from public.profiles where id = new.client_id;
  select full_name into v_empleado_nombre from public.profiles where id = new.employee_id;

  insert into public.notifications (user_id, title, body, type, related_id)
  values (
    new.employee_id,
    'Nueva reserva',
    coalesce(v_cliente_nombre, 'Un cliente') || ' reservó para el ' ||
      to_char(new.booking_date, 'DD/MM/YYYY') || ' a las ' || to_char(new.start_time, 'HH24:MI'),
    'booking_new',
    new.id
  );

  insert into public.notifications (user_id, title, body, type, related_id)
  select id, 'Nueva reserva',
    coalesce(v_cliente_nombre, 'Un cliente') || ' reservó con ' ||
      coalesce(v_empleado_nombre, 'un empleado') || ' para el ' ||
      to_char(new.booking_date, 'DD/MM/YYYY') || ' a las ' || to_char(new.start_time, 'HH24:MI'),
    'booking_new',
    new.id
  from public.profiles
  where role in ('admin','super_admin','sysadmin') and id <> new.employee_id;

  return new;
end;
$$;

create or replace function public.notificar_cambio_reserva()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_titulo text;
  v_cuerpo_cliente text;
  v_cuerpo_admin text;
  v_cliente_nombre text;
begin
  if new.status is distinct from old.status then
    select full_name into v_cliente_nombre from public.profiles where id = new.client_id;

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
  return new;
end;
$$;
