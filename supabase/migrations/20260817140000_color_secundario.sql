-- Color secundario (fondo de toda la app, incluyendo login) — mismo patrón
-- que primary_color, se publica vía el flujo de borrador existente.

alter table public.app_config
  add column if not exists background_color text;
