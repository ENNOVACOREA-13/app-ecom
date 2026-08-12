-- ============================================================================
-- Historial real de compras de insumos, para que "Ganancias netas" reste lo
-- que efectivamente se gastó (no el valor del inventario que quedó guardado).
--
-- Corre esto en el SQL Editor de Supabase.
-- ============================================================================

create table if not exists public.supply_purchases (
  id            uuid primary key default gen_random_uuid(),
  supply_id     uuid not null references public.supplies(id) on delete cascade,
  quantity      int not null default 0,
  total_cost    numeric(10,2) not null default 0,
  purchased_at  date not null default current_date,
  notes         text,
  created_by    uuid references public.profiles(id) on delete set null,
  created_at    timestamptz not null default now()
);
create index if not exists idx_supply_purchases_supply on public.supply_purchases(supply_id);
create index if not exists idx_supply_purchases_date on public.supply_purchases(purchased_at);

alter table public.supply_purchases enable row level security;

create policy "supply_purchases_all_admin" on public.supply_purchases
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.supply_purchases to authenticated;
