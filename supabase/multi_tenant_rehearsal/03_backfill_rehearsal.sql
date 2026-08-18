-- Simula datos "legacy" (pre-migración, sin tenant_id) como estarán los de
-- MC-BARBER de verdad, para ensayar el backfill antes de la Fase 5 real.

insert into public.tenants (id, slug, business_name) values
  ('c0000000-0000-0000-0000-000000000001', 'legacy', 'Negocio Legacy (MC-BARBER simulado)');

-- handle_new_user() crea automáticamente la fila en public.profiles (sin
-- tenant_id, que es justo el estado "legacy" que queremos simular).
insert into auth.users (id, email) values
  ('c0000000-0000-0000-0000-0000000000c1', 'cliente@legacy.test');

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
