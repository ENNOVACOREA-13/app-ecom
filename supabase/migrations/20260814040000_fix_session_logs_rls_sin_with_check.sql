-- session_logs_update tenía USING (profile_id = auth.uid() or is_sysadmin())
-- sin WITH CHECK: un usuario podía reasignar el profile_id de su propia
-- fila de session_logs a otro usuario, o alterar platform/device/login_at.
-- El impacto real es bajo (no otorga permisos, solo corrompe datos de
-- sesión), pero la app nunca necesita tocar esas columnas — los únicos
-- UPDATE reales (activity_service.dart, sysadmin_logs_page.dart) solo
-- cambian is_active/logout_at/last_active_at — así que se restringe por
-- trigger, mismo patrón que notifications/products.

drop policy if exists "session_logs_update" on public.session_logs;
create policy "session_logs_update" on public.session_logs
  for update to authenticated
  using (profile_id = auth.uid() or public.is_sysadmin())
  with check (profile_id = auth.uid() or public.is_sysadmin());

create or replace function public.restringir_actualizacion_session_log()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.profile_id is distinct from old.profile_id
     or new.platform is distinct from old.platform
     or new.device is distinct from old.device
     or new.login_at is distinct from old.login_at then
    raise exception 'SOLO_SE_PUEDE_ACTUALIZAR_ESTADO_DE_SESION';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_restringir_session_log on public.session_logs;
create trigger trg_restringir_session_log
  before update on public.session_logs
  for each row execute function public.restringir_actualizacion_session_log();

