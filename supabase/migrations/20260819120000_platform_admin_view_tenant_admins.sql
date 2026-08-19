-- Permite a platform_admin leer las cuentas admin/super_admin/sysadmin de
-- CUALQUIER tenant (para mostrarlas en el panel de Negocios) — nunca
-- client/employee, para no exponer datos de clientes de un negocio a la
-- plataforma. Política adicional (se suman con OR a profiles_select_own_or_admin),
-- no reemplaza nada existente.
drop policy if exists "profiles_select_platform_admin" on public.profiles;
create policy "profiles_select_platform_admin" on public.profiles
  for select to authenticated
  using (public.is_platform_admin() and role in ('admin', 'super_admin', 'sysadmin'));
