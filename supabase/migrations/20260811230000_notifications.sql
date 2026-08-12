-- ── notifications (notificaciones en app, tiempo real vía Supabase Realtime) ─
create table if not exists public.notifications (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references public.profiles(id) on delete cascade,
  title       text not null,
  body        text not null,
  type        text not null default 'general',
  related_id  uuid,
  read        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists idx_notifications_user on public.notifications(user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
  for select using (user_id = auth.uid());

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update using (user_id = auth.uid());

-- ── Nueva reserva → notificar al empleado asignado ────────────────────────
create or replace function public.notificar_nueva_reserva()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_cliente_nombre text;
begin
  select full_name into v_cliente_nombre from public.profiles where id = new.client_id;
  insert into public.notifications (user_id, title, body, type, related_id)
  values (
    new.employee_id,
    'Nueva reserva',
    coalesce(v_cliente_nombre, 'Un cliente') || ' reservó para el ' ||
      to_char(new.booking_date, 'DD/MM/YYYY') || ' a las ' || to_char(new.start_time, 'HH24:MI'),
    'booking_new',
    new.id
  );
  return new;
end;
$$;

drop trigger if exists trg_notificar_nueva_reserva on public.bookings;
create trigger trg_notificar_nueva_reserva
  after insert on public.bookings
  for each row execute function public.notificar_nueva_reserva();

-- ── Cambio de estado de reserva → notificar al cliente ────────────────────
create or replace function public.notificar_cambio_reserva()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status then
    if new.status = 'confirmed' then
      insert into public.notifications (user_id, title, body, type, related_id)
      values (new.client_id, 'Reserva confirmada',
        'Tu reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue confirmada.',
        'booking_confirmed', new.id);
    elsif new.status = 'cancelled' then
      insert into public.notifications (user_id, title, body, type, related_id)
      values (new.client_id, 'Reserva cancelada',
        'Tu reserva del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue cancelada.',
        'booking_cancelled', new.id);
    elsif new.status = 'completed' then
      insert into public.notifications (user_id, title, body, type, related_id)
      values (new.client_id, '¡Gracias por tu visita!',
        'Tu servicio del ' || to_char(new.booking_date,'DD/MM/YYYY') || ' fue completado.',
        'booking_completed', new.id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_notificar_cambio_reserva on public.bookings;
create trigger trg_notificar_cambio_reserva
  after update on public.bookings
  for each row execute function public.notificar_cambio_reserva();

-- ── Nuevo pedido → notificar a admins/super_admins/sysadmin ───────────────
create or replace function public.notificar_nuevo_pedido()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (user_id, title, body, type, related_id)
  select id, 'Nuevo pedido',
    'Se recibió un nuevo pedido por $' || new.total::text,
    'order_new', new.id
  from public.profiles
  where role in ('admin','super_admin','sysadmin');
  return new;
end;
$$;

drop trigger if exists trg_notificar_nuevo_pedido on public.orders;
create trigger trg_notificar_nuevo_pedido
  after insert on public.orders
  for each row execute function public.notificar_nuevo_pedido();

-- ── Habilitar Realtime en la tabla ─────────────────────────────────────────
alter publication supabase_realtime add table public.notifications;
