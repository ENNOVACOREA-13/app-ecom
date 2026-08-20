-- Tablas con tenant_id sin RLS o sin política que lo use.
-- Excepciones documentadas (por qué NO necesitan política con tenant_id):
--   - tenant_domains, user_tenant_memberships: los administra
--     platform_admin, que no tiene "un" tenant propio — se protegen con
--     is_platform_admin() en vez de tenant_id.
--   - password_reset_tokens, email_verification_tokens: los crean Edge
--     Functions con service_role (bypasea RLS por diseño) — CERO
--     políticas es el estado correcto (deny total para clientes
--     normales), no un hueco.
select
  c.relname as tabla,
  'sin RLS o sin politica con tenant_id' as problema
from pg_class c
join pg_namespace n on c.relnamespace = n.oid
where n.nspname = 'public'
  and c.relkind = 'r'
  and exists (
    select 1 from information_schema.columns col
    where col.table_name = c.relname and col.table_schema = 'public'
      and col.column_name = 'tenant_id'
  )
  and c.relname not in (
    'tenant_domains', 'user_tenant_memberships',
    'password_reset_tokens', 'email_verification_tokens'
  )
  and (
    not c.relrowsecurity
    or not exists (
      select 1 from pg_policies p
      where p.schemaname = 'public' and p.tablename = c.relname
        and (p.qual like '%tenant_id%' or p.with_check like '%tenant_id%')
    )
  );
