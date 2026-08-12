-- Imagen del banner promocional del home, configurable desde el panel de sysadmin.
alter table public.app_config
  add column if not exists banner_image_url text;
