-- ============================================================================
-- Una cuenta, varios negocios: permite que un mismo login sea admin/sysadmin
-- de más de un tenant a la vez, resuelto automáticamente por el dominio
-- visitado (ya se manda como header x-tenant-id desde tenant_resolver.dart,
-- ver request_tenant_id()). Alcance limitado a admin/super_admin/sysadmin —
-- client/employee/platform_admin no cambian en absoluto.
--
-- Diseño: current_tenant_id()/is_admin()/is_sysadmin()/is_admin_or_sysadmin()/
-- my_profile_role() son el único cuello de botella real (casi todas las
-- policies RLS del proyecto los llaman en vez de leer profiles directo), así
-- que basta con hacerlos conscientes de la tabla nueva — el resto de las
-- policies no se toca. Para una cuenta SIN membresías extra, el coalesce cae
-- exactamente al comportamiento actual (profiles.tenant_id/role fijo) — cero
-- regresión para el 99% de las cuentas que solo pertenecen a un negocio.
-- ============================================================================

create table if not exists public.user_tenant_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  role text not null check (role in ('admin', 'super_admin', 'sysadmin')),
  created_at timestamptz not null default now(),
  unique (user_id, tenant_id)
);

alter table public.user_tenant_memberships enable row level security;

-- Solo el dueño de la membresía y platform_admin pueden leerlas. Los inserts/
-- updates/deletes solo los hace la Edge Function con service_role (bypassea
-- RLS) — mismo patrón que password_reset_tokens: deny-by-default para
-- authenticated en escritura.
drop policy if exists "memberships_select_own_or_platform_admin" on public.user_tenant_memberships;
create policy "memberships_select_own_or_platform_admin" on public.user_tenant_memberships
  for select to authenticated
  using (user_id = auth.uid() or public.is_platform_admin());

-- Backfill: cada cuenta admin/super_admin/sysadmin actual obtiene su
-- membresía "de casa" — deja igual de accesible su negocio actual.
insert into public.user_tenant_memberships (user_id, tenant_id, role)
select id, tenant_id, role from public.profiles
where role in ('admin', 'super_admin', 'sysadmin')
on conflict (user_id, tenant_id) do nothing;

-- ============================================================================
-- Función central: mi rol efectivo en el tenant que se está visitando ahora
-- (según el dominio -> header x-tenant-id -> request_tenant_id()). Si hay
-- una membresía para ESE tenant, gana; si no, cae al role fijo de profiles.
-- ============================================================================
create or replace function public.mi_rol_en_tenant_actual()
returns text language sql stable security definer set search_path = public as $$
  select coalesce(
    (select role from public.user_tenant_memberships
       where user_id = auth.uid() and tenant_id = public.request_tenant_id()),
    (select role from public.profiles where id = auth.uid())
  );
$$;

create or replace function public.current_tenant_id()
returns uuid language sql stable security definer set search_path = public as $$
  select coalesce(
    (select tenant_id from public.user_tenant_memberships
       where user_id = auth.uid() and tenant_id = public.request_tenant_id()),
    (select tenant_id from public.profiles where id = auth.uid())
  );
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.mi_rol_en_tenant_actual() in ('admin', 'super_admin'), false);
$$;

create or replace function public.is_sysadmin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.mi_rol_en_tenant_actual() = 'sysadmin', false);
$$;

create or replace function public.is_admin_or_sysadmin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.mi_rol_en_tenant_actual() in ('admin', 'super_admin', 'sysadmin'), false);
$$;

create or replace function public.my_profile_role()
returns text language sql stable security definer set search_path = public as $$
  select public.mi_rol_en_tenant_actual();
$$;

-- is_platform_admin() NO se toca: sigue siendo un flag global sin contexto
-- de tenant (platform_admin no "pertenece" a ningún negocio en particular).

-- ============================================================================
-- Perfil efectivo para el cliente Flutter: junta profiles con el rol/tenant
-- resueltos para el dominio actual, en vez de exponer el role/tenant_id fijo
-- de profiles directo (que puede no ser el correcto si hay una membresía
-- extra activa para este dominio).
-- ============================================================================
create or replace function public.obtener_mi_perfil_efectivo()
returns table(
  id uuid, email text, full_name text, phone text, avatar_url text, bio text,
  is_active boolean, email_verificado boolean, role text, tenant_id uuid,
  created_at timestamptz
)
language sql stable security definer set search_path = public as $$
  select p.id, p.email, p.full_name, p.phone, p.avatar_url, p.bio,
         p.is_active, p.email_verificado,
         public.mi_rol_en_tenant_actual() as role,
         public.current_tenant_id() as tenant_id,
         p.created_at
  from public.profiles p
  where p.id = auth.uid();
$$;

grant execute on function public.obtener_mi_perfil_efectivo() to authenticated;
