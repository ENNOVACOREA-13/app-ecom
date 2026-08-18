-- Simula datos "legacy" (pre-migración, sin tenant_id) como estarán los de
-- MC-BARBER de verdad, para ensayar el backfill antes de la Fase 5 real.

insert into public.tenants (id, slug, business_name) values
  ('c0000000-0000-0000-0000-000000000001', 'legacy', 'Negocio Legacy (MC-BARBER simulado)');

-- La Fase 5 real restaura auth.users/profiles con
-- `session_replication_role = replica` (ver runbook_new_tenant_server.md),
-- lo que DESACTIVA on_auth_user_created — se reproduce aquí igual, porque
-- desde la Fase 4 ese trigger exige tenant_id en raw_user_meta_data y
-- fallaría con INVALID_TENANT si corriera (esto es un restore, no un
-- signup real).
set session_replication_role = replica;
insert into auth.users (id, email) values
  ('c0000000-0000-0000-0000-0000000000c1', 'cliente@legacy.test');
insert into public.profiles (id, email, role, full_name) values
  ('c0000000-0000-0000-0000-0000000000c1', 'cliente@legacy.test', 'client', 'Cliente Legacy');
set session_replication_role = origin;

insert into public.services (id, name, duration_min, price) values
  ('c1000000-0000-0000-0000-000000000001', 'Corte Legacy', 30, 90);

insert into public.products (id, name, price, stock) values
  ('c3000000-0000-0000-0000-000000000001', 'Cera Legacy', 40, 5);

-- ── Backfill: todo lo que sigue con tenant_id null pertenece a 'legacy' ──
update public.profiles set tenant_id = 'c0000000-0000-0000-0000-000000000001' where tenant_id is null;
update public.services  set tenant_id = 'c0000000-0000-0000-0000-000000000001' where tenant_id is null;
update public.products  set tenant_id = 'c0000000-0000-0000-0000-000000000001' where tenant_id is null;
-- (en la Fase 5 real esto se repite para las 27 tablas; aquí basta una
-- muestra representativa para probar el mecanismo)
