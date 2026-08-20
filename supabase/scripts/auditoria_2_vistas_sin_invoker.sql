-- Vistas sin security_invoker=true y sin filtro explícito de tenant en su
-- definición — el bug real que causó la fuga de
-- bookings_detailed/profiles_public (2026-08-20).
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
