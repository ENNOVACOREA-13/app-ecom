-- Icono personalizable por servicio (elegido por el admin desde un set curado).
alter table public.services
  add column if not exists icon_name text;
