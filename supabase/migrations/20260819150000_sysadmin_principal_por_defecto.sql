-- Cada negocio nuevo automáticamente tiene a sysadmin@prettycore.xyz como
-- su sysadmin "de fábrica" — la cuenta maestra de la plataforma (password
-- por defecto PRETTYCORE13), que nunca se puede quitar de ningún negocio.
-- Pedido explícito del usuario: "siempre que se levante una app, el correo
-- sysadmin@prettycore.xyz siempre sea el sysadmin principal ... pero si
-- quiero agregar más cuentas sysadmin o admin esas sí se pueden eliminar".
--
-- No crea la cuenta si no existe (eso requeriría el Admin API de GoTrue,
-- fuera del alcance de una migración SQL) — asume que ya existe, como es
-- el caso en este proyecto.

create or replace function public.sembrar_sysadmin_principal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  select id into v_user_id from auth.users where email = 'sysadmin@prettycore.xyz';
  if v_user_id is not null then
    insert into public.user_tenant_memberships (user_id, tenant_id, role)
    values (v_user_id, new.id, 'sysadmin')
    on conflict (user_id, tenant_id) do nothing;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_sembrar_sysadmin_principal on public.tenants;
create trigger trg_sembrar_sysadmin_principal
  after insert on public.tenants
  for each row execute function public.sembrar_sysadmin_principal();

-- Backfill: negocios que ya existían antes de este trigger (mc-barber,
-- pretty) también quedan con la membresía sembrada.
insert into public.user_tenant_memberships (user_id, tenant_id, role)
select (select id from auth.users where email = 'sysadmin@prettycore.xyz'), t.id, 'sysadmin'
from public.tenants t
where (select id from auth.users where email = 'sysadmin@prettycore.xyz') is not null
on conflict (user_id, tenant_id) do nothing;

-- Protección: ni siquiera platform_admin puede borrar la membresía de
-- sysadmin@prettycore.xyz vía DELETE directo (UI o API) — "siempre" el
-- sysadmin principal, en cualquier negocio, presente o futuro.
create or replace function public.proteger_sysadmin_principal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.user_id = (select id from auth.users where email = 'sysadmin@prettycore.xyz') then
    raise exception 'No se puede quitar el acceso del sysadmin principal.';
  end if;
  return old;
end;
$$;

drop trigger if exists trg_proteger_sysadmin_principal on public.user_tenant_memberships;
create trigger trg_proteger_sysadmin_principal
  before delete on public.user_tenant_memberships
  for each row execute function public.proteger_sysadmin_principal();
