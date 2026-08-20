-- Permite a platform_admin editar (nombre/teléfono) y eliminar por completo
-- cualquier cuenta admin/super_admin/sysadmin de CUALQUIER tenant desde el
-- panel de Negocios — antes solo podía leerlas (profiles_select_platform_admin)
-- y quitar membresías extra, pero no tocar la cuenta "de casa" de un negocio
-- (la que no tiene fila en user_tenant_memberships). Pedido explícito del
-- usuario: "cualquier correo de admin o admin de negocios desde control
-- plane debe poder quitarse o cambiarse o editarse".
--
-- Mismo alcance de roles que la política de SELECT ya existente: nunca
-- client/employee, para no exponer ni tocar datos de clientes de un negocio
-- desde la plataforma.
drop policy if exists "profiles_update_platform_admin" on public.profiles;
create policy "profiles_update_platform_admin" on public.profiles
  for update to authenticated
  using (public.is_platform_admin() and role in ('admin', 'super_admin', 'sysadmin'))
  with check (public.is_platform_admin() and role in ('admin', 'super_admin', 'sysadmin'));

drop policy if exists "profiles_delete_platform_admin" on public.profiles;
create policy "profiles_delete_platform_admin" on public.profiles
  for delete to authenticated
  using (public.is_platform_admin() and role in ('admin', 'super_admin', 'sysadmin'));

-- Protección: ni siquiera platform_admin puede editar el rol ni eliminar el
-- perfil de sysadmin@prettycore.xyz (el sysadmin principal de la
-- plataforma) — mismo criterio que proteger_sysadmin_principal() ya usa
-- para user_tenant_memberships. Nombre/teléfono sí se pueden editar.
create or replace function public.proteger_perfil_sysadmin_principal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.email = 'sysadmin@prettycore.xyz' then
    if tg_op = 'DELETE' then
      raise exception 'No se puede eliminar la cuenta del sysadmin principal.';
    end if;
    if new.role is distinct from old.role then
      raise exception 'No se puede cambiar el rol del sysadmin principal.';
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trg_proteger_perfil_sysadmin_principal on public.profiles;
create trigger trg_proteger_perfil_sysadmin_principal
  before update or delete on public.profiles
  for each row execute function public.proteger_perfil_sysadmin_principal();
