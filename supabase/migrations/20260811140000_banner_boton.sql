-- Texto y link del botón del banner promocional (sysadmin).
alter table public.app_config
  add column if not exists banner_button_text text,
  add column if not exists banner_button_link text;
