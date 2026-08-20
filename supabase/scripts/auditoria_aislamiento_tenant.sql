-- ═══════════════════════════════════════════════════════════════════════
-- AUDITORÍA DE AISLAMIENTO ENTRE TENANTS
-- ═══════════════════════════════════════════════════════════════════════
-- Corre esto CADA VEZ que se agregue una tabla o vista nueva (cada nueva
-- "app"/feature) — pégalo en el SQL Editor de Supabase o mándalo por la
-- Management API. Si algo aquí regresa filas, hay un hueco real que
-- revisar antes de seguir. No modifica nada, es 100% de solo lectura.
--
-- Pedido explícito del usuario 2026-08-20: "que más podemos hacer para
-- que jamás se filtren datos de un tenant a otro" — este script es la
-- respuesta permanente, no un parche puntual.
--
-- Qué revisa:
--   1. Toda tabla con columna tenant_id tiene RLS encendido Y al menos
--      una política que mencione tenant_id — o está en la lista de
--      excepciones documentadas (tablas de plataforma, no de negocio).
--   2. Toda vista tiene security_invoker=true, o su definición filtra
--      explícitamente por tenant_id/request_tenant_id() — el bug real
--      que causó la fuga de bookings_detailed/profiles_public
--      (2026-08-20) era exactamente la ausencia de esto.
--   3. Todo bucket de Storage con objetos privados tiene las 4 políticas
--      (SELECT/INSERT/UPDATE/DELETE) — sin SELECT, cualquier subida con
--      upsert:true falla (bug real encontrado 2026-08-20), y JUSTO por
--      eso es fácil no notar cuando falta.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 1. Tablas con tenant_id sin RLS o sin política que lo use ─────────
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

-- ── 2. Vistas sin security_invoker y sin filtro explícito de tenant ────
select
  c.relname as vista,
  'sin security_invoker=true y sin tenant_id/request_tenant_id() en su definicion' as problema
from pg_class c
join pg_namespace n on c.relnamespace = n.oid
where n.nspname = 'public'
  and c.relkind = 'v'
  and not (c.reloptions::text like '%security_invoker=true%')
  and pg_get_viewdef(c.oid, true) not like '%tenant_id%'
  and pg_get_viewdef(c.oid, true) not like '%request_tenant_id()%';

-- ── 3. Buckets de Storage privados sin las 4 políticas completas ──────
select
  b.id as bucket,
  array_agg(distinct p.cmd order by p.cmd) as comandos_con_politica,
  'le falta al menos uno de SELECT/INSERT/UPDATE/DELETE' as problema
from storage.buckets b
left join pg_policies p
  on p.schemaname = 'storage' and p.tablename = 'objects'
  and (
    position(b.id in coalesce(p.qual, '')) > 0
    or position(b.id in coalesce(p.with_check, '')) > 0
  )
where b.public = false
group by b.id
having count(distinct p.cmd) < 4;
