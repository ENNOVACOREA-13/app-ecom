-- ── Banner promocional como carrusel (hasta 5 imágenes) ────────────────────
alter table public.app_config
  add column if not exists banner_images jsonb not null default '[]'::jsonb;

-- Migra la imagen única existente (si había) al nuevo arreglo.
update public.app_config
set banner_images = jsonb_build_array(banner_image_url)
where banner_image_url is not null and banner_image_url <> ''
  and banner_images = '[]'::jsonb;
