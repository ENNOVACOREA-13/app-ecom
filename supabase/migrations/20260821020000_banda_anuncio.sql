-- Banda de anuncio tipo carrusel, siempre visible arriba de la app,
-- editable desde sysadmin. Apagada por default (marquee_enabled=false):
-- nadie ve una banda vacía sin que sysadmin la configure primero.
alter table app_config
  add column if not exists marquee_enabled boolean not null default false,
  add column if not exists marquee_text text,
  add column if not exists marquee_bg_color text not null default '#FF3B30',
  add column if not exists marquee_text_color text not null default '#FFFFFF';
