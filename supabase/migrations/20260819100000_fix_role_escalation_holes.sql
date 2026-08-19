-- ============================================================================
-- FIX de seguridad crítico: dos vías de escalación de privilegios abiertas.
--
-- 1) handle_new_user() leía el campo `role` directo de raw_user_meta_data,
--    confiando en lo que mandara el cliente en /auth/v1/signup. Como esa
--    llamada solo necesita el anon key (público, está en el bundle JS),
--    cualquiera podía registrarse con role:"platform_admin" en el body y
--    obtener control total de la plataforma sin pasar por la app.
--    Confirmado explotable: sysadmin_config_page.dart y
--    manage_employees_page.dart ya mandan `role` en la metadata de signup
--    (para crear empleados/admins), probando que el trigger lo respeta tal
--    cual. Fix: el trigger ya NO lee `role` de la metadata — todo alta
--    pública nace 'client', sin excepción.
--
-- 2) profiles_update_self_or_admin permitía que CUALQUIER admin/sysadmin
--    de un tenant asignara CUALQUIER rol (incluido 'platform_admin') a
--    cualquier perfil de su propio tenant — sin restricción de a qué rol
--    concreto podían escalar. Un admin de un negocio podía hacer un PATCH
--    directo a su propia fila con role:'platform_admin' y ver todos los
--    tenants de la plataforma. Fix: ese rol queda excluido de la política
--    — 'platform_admin' solo se asigna por SQL manual o por la Edge
--    Function admin-create-user (que valida server-side quién llama).
-- ============================================================================

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_tenant_id uuid;
begin
  v_tenant_id := nullif(new.raw_user_meta_data->>'tenant_id', '')::uuid;

  if v_tenant_id is null or not exists (
    select 1 from public.tenants where id = v_tenant_id and status = 'active'
  ) then
    raise exception 'INVALID_TENANT';
  end if;

  insert into public.profiles (id, email, full_name, role, is_active, tenant_id)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    'client',
    true,
    v_tenant_id
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop policy if exists "profiles_update_self_or_admin" on public.profiles;
create policy "profiles_update_self_or_admin" on public.profiles
  for update to authenticated
  using (id = auth.uid() or (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin()))
  with check (
    (id = auth.uid() and role = public.my_profile_role() and tenant_id = public.current_tenant_id())
    or (
      public.is_admin_or_sysadmin()
      and tenant_id = public.current_tenant_id()
      and role <> 'platform_admin'
    )
  );
