-- ── Permite subir una imagen personalizada a cada categoría de producto ────
alter table public.product_categories
  add column if not exists image_url text;
