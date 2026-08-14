-- notifications_update_own solo tenía USING (user_id = auth.uid()), sin
-- WITH CHECK. Eso significa que, además de marcar su propia notificación
-- como leída (lo único que hace la app), un cliente podía mandar un UPDATE
-- directo cambiando CUALQUIER columna de una notificación propia —
-- incluyendo user_id, title, body, type y related_id. Reasignando user_id
-- al id de otra persona, esa fila pasa a aparecer en el feed de esa otra
-- persona (notifications_select_own) con el título/cuerpo que el atacante
-- haya puesto: permite inyectar notificaciones falsas en la bandeja de
-- cualquier usuario (phishing dentro de la app).
--
-- El único UPDATE real que hace la app es {'read': true} (ver
-- lib/data/notification_repository.dart), así que se restringe por
-- trigger a solo esa columna.

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create or replace function public.restringir_actualizacion_notificacion_propia()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.title is distinct from old.title
     or new.body is distinct from old.body
     or new.type is distinct from old.type
     or new.related_id is distinct from old.related_id
     or new.user_id is distinct from old.user_id
     or new.created_at is distinct from old.created_at then
    raise exception 'SOLO_SE_PUEDE_MARCAR_COMO_LEIDA';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_restringir_notificacion_propia on public.notifications;
create trigger trg_restringir_notificacion_propia
  before update on public.notifications
  for each row execute function public.restringir_actualizacion_notificacion_propia();
