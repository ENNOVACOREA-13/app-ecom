-- Encontrado al probar en vivo el borrado total de un tenant: cada negocio
-- nuevo trae sembrada automáticamente una membresía de sysadmin@prettycore.xyz
-- (ver sembrar_sysadmin_principal), y proteger_sysadmin_principal() bloquea
-- SIEMPRE borrar esa fila de user_tenant_memberships — sin la válvula de
-- escape, el cascade completo de borrar el tenant chocaba con esa membresía
-- sembrada y abortaba TODA la transacción, dejando imposible borrar
-- cualquier negocio (todos tienen esa membresía).
--
-- Se le agrega la misma válvula de escape que ya tiene
-- bloquear_eliminacion_sysadmin() (20260820140000): solo se salta la
-- protección dentro de la transacción de admin-delete-tenant, vía el mismo
-- GUC — quitar la membresía de un negocio TODAVÍA existente sigue
-- bloqueado exactamente igual que antes.
create or replace function public.proteger_sysadmin_principal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.user_id = (select id from auth.users where email = 'sysadmin@prettycore.xyz')
     and coalesce(current_setting('app.borrando_tenant_en_cascada', true), 'false') <> 'true' then
    raise exception 'No se puede quitar el acceso del sysadmin principal.';
  end if;
  return old;
end;
$$;
