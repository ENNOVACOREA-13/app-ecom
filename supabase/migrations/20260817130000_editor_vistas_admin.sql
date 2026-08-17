-- Permite a sysadmin decidir si el rol admin también ve la pestaña
-- "Diseñador de vista" (antes exclusiva de sysadmin). RLS de app_config ya
-- cubre admin/sysadmin (fix_app_config_rls_sysadmin.sql), no hace falta
-- tocar policies.

alter table public.app_config
  add column if not exists editor_vistas_admin boolean not null default false;
