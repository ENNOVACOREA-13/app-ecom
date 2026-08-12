-- Texto y alineación editables del banner promocional (sysadmin).
alter table public.app_config
  add column if not exists banner_text text,
  add column if not exists banner_align text not null default 'left';
