-- El panel de Negocios (platform_admin) necesita poder quitar una membresía
-- cruzada (ej. limpiar una fila de prueba, o revocar el acceso de un admin
-- a un segundo negocio) directo desde la UI, sin pasar por una Edge
-- Function. Hasta ahora user_tenant_memberships solo tenía policy de
-- SELECT — cualquier intento de DELETE desde el cliente caía en deny-by-
-- default. Mismo patrón que ya usan tenants/tenant_domains (ALL para
-- platform_admin).
drop policy if exists "memberships_all_platform_admin" on public.user_tenant_memberships;
create policy "memberships_all_platform_admin" on public.user_tenant_memberships
  for all to authenticated
  using (public.is_platform_admin())
  with check (public.is_platform_admin());
