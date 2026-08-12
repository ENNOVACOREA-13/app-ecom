-- ============================================================================
-- FIX de seguridad: la política de UPDATE de `profiles` dejaba que CUALQUIER
-- usuario autenticado se cambiara su propio `role` a 'admin' (o el que sea)
-- con un PATCH directo a la REST API, porque el USING permitía id=auth.uid()
-- pero no había WITH CHECK que protegiera la columna `role`.
--
-- Este script reemplaza esa política para que:
--   - admin/super_admin/sysadmin puedan editar cualquier perfil (incluido el rol)
--   - un usuario normal pueda editar su propio perfil (nombre, tel, avatar, bio)
--     pero NO pueda cambiarse el rol a sí mismo.
-- ============================================================================

drop policy if exists "profiles_update_self_or_admin" on public.profiles;

create policy "profiles_update_self_or_admin" on public.profiles
  for update to authenticated
  using (id = auth.uid() or public.is_admin_or_sysadmin())
  with check (
    public.is_admin_or_sysadmin()
    or (id = auth.uid() and role = public.my_profile_role())
  );

-- Mismo problema, versión INSERT: el registro manual de respaldo en
-- auth_repository.dart siempre manda role:'client', así que restringirlo no
-- rompe nada — solo cierra la ventana teórica de que alguien inserte su propio
-- perfil con un rol distinto antes de que corra el trigger handle_new_user().
-- (La creación de empleados/admins por un sysadmin no depende de esta política:
-- el rol se asigna vía raw_user_meta_data en el signUp, que procesa el trigger
-- con SECURITY DEFINER y por lo tanto no pasa por RLS.)
drop policy if exists "profiles_insert_self" on public.profiles;

create policy "profiles_insert_self" on public.profiles
  for insert to authenticated
  with check (id = auth.uid() and role = 'client');
