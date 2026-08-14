-- app_config_write_admin usaba is_admin() (admin/super_admin), que excluye
-- a sysadmin. Pero "Diseñador de vista" (view_designer_page.dart) — que
-- lee/escribe app_config vía ProveedorConfig.publicarBorrador/guardarBorrador
-- — es una herramienta EXCLUSIVA de sysadmin en la navegación de la app.
--
-- Como config_repository.dart hace upsert() y solo revisa si la llamada
-- lanzó excepción (no si realmente afectó filas), el UPDATE se filtraba en
-- silencio por RLS: 0 filas afectadas, sin error, y la app mostraba
-- "Cambios publicados" sin haber guardado nada — el mismo patrón de bug ya
-- visto y corregido para products/category_id.

drop policy if exists "app_config_write_admin" on public.app_config;
create policy "app_config_write_admin" on public.app_config
  for all to authenticated
  using (public.is_admin_or_sysadmin())
  with check (public.is_admin_or_sysadmin());
