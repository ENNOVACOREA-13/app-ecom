-- El sysadmin también debe poder configurar app_config (ej. banner_image_url),
-- no solo el admin. Misma clase de bug que las políticas de orders: una
-- actualización bloqueada por RLS afecta 0 filas sin lanzar error, por lo que
-- la app mostraba "éxito" aunque nunca se guardara nada.

drop policy if exists "app_config_write_admin" on public.app_config;
create policy "app_config_write_admin" on public.app_config
  for all to authenticated using (public.is_admin_or_sysadmin()) with check (public.is_admin_or_sysadmin());
