-- ============================================================================
-- Multi-tenant, Fase 2 (parte 3/3): funciones de resolución/rol, trigger de
-- aprovisionamiento, y las policies de tenants/tenant_domains.
--
-- Corre DESPUÉS de 20260818110000_multi_tenant_add_columns.sql porque
-- current_tenant_id() referencia public.profiles.tenant_id.
--
-- ADITIVO Y SEGURO: nada de esto lo usa la app todavía (RLS tenant-aware de
-- las tablas reales viene en una migración posterior, solo tras verificar
-- el backfill al 100%). Después de correr esto, la app sigue funcionando
-- exactamente igual que antes.
--
-- Ver plan completo: C:\Users\HP\.claude\plans\stateful-dreaming-breeze.md
-- ============================================================================

-- ── current_tenant_id(): tenant del usuario autenticado actual ───────────
-- SECURITY DEFINER + STABLE, mismo espíritu que is_admin()/is_sysadmin() en
-- rebuild_schema.sql. Deriva SIEMPRE de profiles.tenant_id (server-side),
-- nunca de un header — eso es lo que lo hace a prueba de manipulación.
create or replace function public.current_tenant_id()
returns uuid language sql stable security definer set search_path = public as $$
  select tenant_id from public.profiles where id = auth.uid();
$$;

-- ── is_platform_admin(): operador de la plataforma (no un sysadmin de un
--    negocio) — el único rol con permiso de escribir en tenants/tenant_domains.
create or replace function public.is_platform_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role from public.profiles where id = auth.uid()) = 'platform_admin', false);
$$;

-- ── resolve_tenant_by_domain(): reemplaza al RPC del control plane externo.
--    Pública (grant a anon) porque se llama ANTES de tener sesión.
create or replace function public.resolve_tenant_by_domain(p_domain text)
returns table(tenant_id uuid, slug text, business_name text, status text)
language sql stable security definer set search_path = public as $$
  select t.id, t.slug, t.business_name, t.status
  from public.tenant_domains d
  join public.tenants t on t.id = d.tenant_id
  where d.domain = p_domain;
$$;
grant execute on function public.resolve_tenant_by_domain(text) to anon, authenticated;

-- ── provision_tenant_defaults(): siembra las filas singleton-por-tenant que
--    necesita un negocio nuevo para no romper la app al primer login. Se
--    llama automáticamente vía trigger al insertar en tenants — dar de alta
--    un tenant nuevo queda en un solo INSERT, sin ningún paso manual de
--    infraestructura.
create or replace function public.provision_tenant_defaults()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.app_config (tenant_id, primary_color)
  values (new.id, '#4ECDC4')
  on conflict (tenant_id) do nothing;

  insert into public.commission_settings (tenant_id, cutoff_day, cutoff_hour, cutoff_minute)
  values (new.id, 0, 23, 59)
  on conflict (tenant_id) do nothing;

  insert into public.loyalty_config (tenant_id, activo, nombre_programa, monto_por_punto, puntos_por_peso_canje)
  values (new.id, true, 'Programa de lealtad', 100, 10)
  on conflict (tenant_id) do nothing;

  return new;
end;
$$;
drop trigger if exists on_tenant_created on public.tenants;
create trigger on_tenant_created
  after insert on public.tenants
  for each row execute function public.provision_tenant_defaults();

-- ============================================================================
-- profiles.role: agregar 'platform_admin' al catálogo de roles válidos.
-- Aditivo — no cambia el rol de nadie, solo permite que el valor exista.
-- ============================================================================
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('client','employee','admin','super_admin','sysadmin','platform_admin'));

-- ============================================================================
-- RLS de tenants/tenant_domains (tablas creadas en la parte 1/3)
-- ============================================================================
drop policy if exists "tenants_all_platform_admin" on public.tenants;
create policy "tenants_all_platform_admin" on public.tenants
  for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());

drop policy if exists "tenant_domains_all_platform_admin" on public.tenant_domains;
create policy "tenant_domains_all_platform_admin" on public.tenant_domains
  for all to authenticated
  using (public.is_platform_admin()) with check (public.is_platform_admin());
