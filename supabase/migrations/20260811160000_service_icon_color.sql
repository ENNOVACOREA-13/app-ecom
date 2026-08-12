-- Color personalizable del icono/circulo de cada servicio.
alter table public.services
  add column if not exists icon_color text;
