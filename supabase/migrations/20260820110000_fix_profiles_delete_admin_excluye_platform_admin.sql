-- Hueco encontrado al probar en vivo la migración anterior (verificación
-- obligatoria de aislamiento): profiles_delete_admin dejaba borrar CUALQUIER
-- perfil del tenant actual, sin excluir platform_admin — a diferencia de
-- profiles_update_self_or_admin, que sí excluye 'platform_admin' en su
-- with_check. Como el tenant_id "de relleno" de un platform_admin puede
-- coincidir por casualidad con un tenant real (como pasa hoy con
-- juremaguilar@icloud.com y MC-BARBER), cualquier admin/sysadmin de ESE
-- tenant podía borrar esa cuenta. Solo no pasó en la prueba porque una
-- foreign key de bookings lo bloqueó, pero no debe depender de eso.
drop policy if exists "profiles_delete_admin" on public.profiles;
create policy "profiles_delete_admin" on public.profiles
  for delete to authenticated
  using (
    tenant_id = public.current_tenant_id()
    and public.is_admin_or_sysadmin()
    and role <> 'platform_admin'
  );
