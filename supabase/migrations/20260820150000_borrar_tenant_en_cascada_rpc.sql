-- Función que ejecuta la Edge Function admin-delete-tenant para el borrado
-- en cascada real: enciende la válvula de escape de
-- bloquear_eliminacion_sysadmin() SOLO dentro de esta transacción (set_config
-- con is_local=true) y borra la fila de tenants, lo que dispara el cascade
-- completo (20260820140000). No se le da acceso a "authenticated" en
-- general — la Edge Function la llama con service_role, después de validar
-- que quien llama es platform_admin y de que el slug de confirmación
-- coincide.
create or replace function public.borrar_tenant_en_cascada(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  perform set_config('app.borrando_tenant_en_cascada', 'true', true);
  delete from public.tenants where id = p_tenant_id;
end;
$$;

revoke all on function public.borrar_tenant_en_cascada(uuid) from public;
revoke all on function public.borrar_tenant_en_cascada(uuid) from authenticated;
grant execute on function public.borrar_tenant_en_cascada(uuid) to service_role;
