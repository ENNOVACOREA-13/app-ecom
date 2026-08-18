-- ============================================================================
-- Multi-tenant, Fase 2 (parte 1/3): tablas tenants/tenant_domains.
--
-- Va SOLA y primero porque las funciones de la parte 3/3 (current_tenant_id,
-- etc.) referencian public.profiles.tenant_id, columna que recién existe
-- después de la parte 2/3 (20260818110000_multi_tenant_add_columns.sql) —
-- Postgres valida las columnas referenciadas en funciones `language sql` al
-- crearlas, no solo al ejecutarlas, así que el orden importa.
--
-- ADITIVO Y SEGURO: tablas nuevas, nadie las usa todavía. La app sigue
-- funcionando exactamente igual después de esto.
--
-- Ver plan completo: C:\Users\HP\.claude\plans\stateful-dreaming-breeze.md
-- ============================================================================

create table if not exists public.tenants (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  business_name  text not null,
  status         text not null default 'active'
                 check (status in ('active','suspended','maintenance')),
  created_at     timestamptz not null default now()
);

create table if not exists public.tenant_domains (
  id          uuid primary key default gen_random_uuid(),
  tenant_id   uuid not null references public.tenants(id) on delete cascade,
  domain      text not null unique,
  created_at  timestamptz not null default now()
);
create index if not exists idx_tenant_domains_tenant on public.tenant_domains(tenant_id);

alter table public.tenants        enable row level security;
alter table public.tenant_domains enable row level security;
-- Las policies reales (is_platform_admin()) se crean en
-- 20260818120000_multi_tenant_functions.sql, una vez esa función exista.
