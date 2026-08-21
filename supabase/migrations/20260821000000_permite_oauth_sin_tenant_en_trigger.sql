-- Login con Google/Facebook nunca manda tenant_id en raw_user_meta_data
-- (a diferencia del registro normal, que sí lo incluye a propósito) — el
-- trigger tumbaba la creación ENTERA de la cuenta de Auth con
-- 'INVALID_TENANT', así que un primer login con Google fallaba siempre,
-- en cualquier tenant (bug real encontrado 2026-08-20).
--
-- Ahora, si no hay tenant_id válido, el trigger simplemente no crea el
-- perfil (en vez de abortar la transacción completa) — la cuenta de Auth
-- se crea igual, y el perfil se crea del lado del cliente en cuanto
-- aterriza en el dominio correcto (RepositorioAuth.obtenerOCrearPerfilOAuth),
-- vía la misma política RLS profiles_insert_self que ya se usaba para el
-- registro normal. El registro normal y las invitaciones (que sí mandan
-- tenant_id siempre) siguen exactamente igual.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tenant_id uuid;
begin
  v_tenant_id := nullif(new.raw_user_meta_data->>'tenant_id', '')::uuid;

  if v_tenant_id is null or not exists (
    select 1 from public.tenants where id = v_tenant_id and status = 'active'
  ) then
    return new;
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
