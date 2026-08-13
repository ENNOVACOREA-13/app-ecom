-- ── Categorías de productos (tienda) ────────────────────────────────────────
-- Permite a admin/sysadmin crear categorías (nombre + icono), asignarles
-- productos, y mostrar una fila de chips en el home entre la barra de
-- búsqueda y el banner de referencia.

create table if not exists public.product_categories (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  icon        text not null default 'category',
  sort_order  int not null default 0,
  created_at  timestamptz not null default now()
);

alter table public.product_categories enable row level security;

drop policy if exists "product_categories_select_public" on public.product_categories;
create policy "product_categories_select_public" on public.product_categories
  for select using (true);

drop policy if exists "product_categories_write_admin" on public.product_categories;
create policy "product_categories_write_admin" on public.product_categories
  for all to authenticated
  using (public.is_admin_or_sysadmin())
  with check (public.is_admin_or_sysadmin());

alter table public.products
  add column if not exists category_id uuid references public.product_categories(id) on delete set null;
