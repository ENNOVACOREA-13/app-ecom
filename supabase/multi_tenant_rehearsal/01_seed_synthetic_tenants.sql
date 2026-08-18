-- Fase 3 (rehearsal, LOCAL SOLAMENTE): siembra 2 tenants sintéticos con
-- datos que ejercitan las 27 tablas, para probar backfill + NOT NULL antes
-- de tocar datos reales. Usa UUIDs fijos para poder verificar después.

-- ── Tenants (dispara provision_tenant_defaults automáticamente) ──────────
insert into public.tenants (id, slug, business_name) values
  ('a0000000-0000-0000-0000-000000000001', 'tenant-a', 'Barbería A'),
  ('b0000000-0000-0000-0000-000000000001', 'tenant-b', 'Barbería B');

insert into public.tenant_domains (tenant_id, domain) values
  ('a0000000-0000-0000-0000-000000000001', 'tenant-a.test'),
  ('b0000000-0000-0000-0000-000000000001', 'tenant-b.test');

-- ── auth.users + profiles (client/employee/admin por tenant) ─────────────
-- raw_user_meta_data.tenant_id es obligatorio desde la Fase 4
-- (handle_new_user() rechaza el signup si falta o no es un tenant activo).
insert into auth.users (id, email, raw_user_meta_data) values
  ('a0000000-0000-0000-0000-0000000000c1', 'cliente@tenant-a.test', '{"tenant_id":"a0000000-0000-0000-0000-000000000001"}'),
  ('a0000000-0000-0000-0000-0000000000e1', 'empleado@tenant-a.test', '{"tenant_id":"a0000000-0000-0000-0000-000000000001"}'),
  ('a0000000-0000-0000-0000-0000000000ad', 'admin@tenant-a.test', '{"tenant_id":"a0000000-0000-0000-0000-000000000001"}'),
  ('b0000000-0000-0000-0000-0000000000c1', 'cliente@tenant-b.test', '{"tenant_id":"b0000000-0000-0000-0000-000000000001"}'),
  ('b0000000-0000-0000-0000-0000000000e1', 'empleado@tenant-b.test', '{"tenant_id":"b0000000-0000-0000-0000-000000000001"}'),
  ('b0000000-0000-0000-0000-0000000000ad', 'admin@tenant-b.test', '{"tenant_id":"b0000000-0000-0000-0000-000000000001"}');

-- handle_new_user() ya creó estas 6 filas al insertar en auth.users (con
-- role='client' y tenant_id null por defecto) — ON CONFLICT DO UPDATE para
-- fijar el role/tenant_id real de cada una.
insert into public.profiles (id, email, role, full_name, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000c1', 'cliente@tenant-a.test', 'client', 'Cliente A', 'a0000000-0000-0000-0000-000000000001'),
  ('a0000000-0000-0000-0000-0000000000e1', 'empleado@tenant-a.test', 'employee', 'Empleado A', 'a0000000-0000-0000-0000-000000000001'),
  ('a0000000-0000-0000-0000-0000000000ad', 'admin@tenant-a.test', 'admin', 'Admin A', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000c1', 'cliente@tenant-b.test', 'client', 'Cliente B', 'b0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000e1', 'empleado@tenant-b.test', 'employee', 'Empleado B', 'b0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000ad', 'admin@tenant-b.test', 'admin', 'Admin B', 'b0000000-0000-0000-0000-000000000001')
on conflict (id) do update set role = excluded.role, full_name = excluded.full_name, tenant_id = excluded.tenant_id;

-- ── services / employee_services / work_schedules ─────────────────────────
insert into public.services (id, name, duration_min, price, tenant_id) values
  ('a1000000-0000-0000-0000-000000000001', 'Corte A', 30, 100, 'a0000000-0000-0000-0000-000000000001'),
  ('b1000000-0000-0000-0000-000000000001', 'Corte B', 30, 120, 'b0000000-0000-0000-0000-000000000001');

insert into public.employee_services (employee_id, service_id, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000e1', 'a1000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000e1', 'b1000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001');

insert into public.work_schedules (employee_id, day_of_week, start_time, end_time, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000e1', 'monday', '09:00', '18:00', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000e1', 'monday', '09:00', '18:00', 'b0000000-0000-0000-0000-000000000001');

-- ── products / product_categories / supplies ──────────────────────────────
insert into public.product_categories (id, name, tenant_id) values
  ('a2000000-0000-0000-0000-000000000001', 'Cuidado A', 'a0000000-0000-0000-0000-000000000001'),
  ('b2000000-0000-0000-0000-000000000001', 'Cuidado B', 'b0000000-0000-0000-0000-000000000001');

insert into public.products (id, name, price, stock, created_by, tenant_id) values
  ('a3000000-0000-0000-0000-000000000001', 'Cera A', 50, 10, 'a0000000-0000-0000-0000-0000000000ad', 'a0000000-0000-0000-0000-000000000001'),
  ('b3000000-0000-0000-0000-000000000001', 'Cera B', 60, 10, 'b0000000-0000-0000-0000-0000000000ad', 'b0000000-0000-0000-0000-000000000001');

insert into public.supplies (id, name, price, stock, created_by, tenant_id) values
  ('a4000000-0000-0000-0000-000000000001', 'Insumo A', 20, 5, 'a0000000-0000-0000-0000-0000000000ad', 'a0000000-0000-0000-0000-000000000001'),
  ('b4000000-0000-0000-0000-000000000001', 'Insumo B', 25, 5, 'b0000000-0000-0000-0000-0000000000ad', 'b0000000-0000-0000-0000-000000000001');

insert into public.supply_purchases (supply_id, quantity, total_cost, created_by, tenant_id) values
  ('a4000000-0000-0000-0000-000000000001', 2, 40, 'a0000000-0000-0000-0000-0000000000ad', 'a0000000-0000-0000-0000-000000000001'),
  ('b4000000-0000-0000-0000-000000000001', 2, 50, 'b0000000-0000-0000-0000-0000000000ad', 'b0000000-0000-0000-0000-000000000001');

-- ── bookings / reviews / commission_configs / commission_entries ──────────
insert into public.bookings (id, client_id, employee_id, service_id, booking_date, start_time, end_time, status, total_price, tenant_id) values
  ('a5000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-0000000000c1', 'a0000000-0000-0000-0000-0000000000e1', 'a1000000-0000-0000-0000-000000000001', current_date, '10:00', '10:30', 'completed', 100, 'a0000000-0000-0000-0000-000000000001'),
  ('b5000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000c1', 'b0000000-0000-0000-0000-0000000000e1', 'b1000000-0000-0000-0000-000000000001', current_date, '10:00', '10:30', 'completed', 120, 'b0000000-0000-0000-0000-000000000001');

insert into public.reviews (booking_id, client_id, employee_id, rating, tenant_id) values
  ('a5000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-0000000000c1', 'a0000000-0000-0000-0000-0000000000e1', 5, 'a0000000-0000-0000-0000-000000000001'),
  ('b5000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000c1', 'b0000000-0000-0000-0000-0000000000e1', 5, 'b0000000-0000-0000-0000-000000000001');

insert into public.commission_configs (service_id, amount, tenant_id) values
  ('a1000000-0000-0000-0000-000000000001', 20, 'a0000000-0000-0000-0000-000000000001'),
  ('b1000000-0000-0000-0000-000000000001', 25, 'b0000000-0000-0000-0000-000000000001');

insert into public.commission_entries (employee_id, booking_id, service_id, service_name, service_price, commission_amount, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000e1', 'a5000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001', 'Corte A', 100, 20, 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000e1', 'b5000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Corte B', 120, 25, 'b0000000-0000-0000-0000-000000000001');

-- ── orders / order_items / saved_products ─────────────────────────────────
insert into public.orders (id, client_id, total, status, tenant_id) values
  ('a6000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-0000000000c1', 50, 'delivered', 'a0000000-0000-0000-0000-000000000001'),
  ('b6000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000c1', 60, 'delivered', 'b0000000-0000-0000-0000-000000000001');

insert into public.order_items (order_id, product_id, product_name, quantity, unit_price, tenant_id) values
  ('a6000000-0000-0000-0000-000000000001', 'a3000000-0000-0000-0000-000000000001', 'Cera A', 1, 50, 'a0000000-0000-0000-0000-000000000001'),
  ('b6000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'Cera B', 1, 60, 'b0000000-0000-0000-0000-000000000001');

insert into public.saved_products (user_id, product_id, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000c1', 'a3000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000c1', 'b3000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001');

-- ── session_logs / activity_logs / notifications / loyalty_points / tokens / time_off ──
insert into public.session_logs (id, profile_id, platform, device, tenant_id) values
  ('a7000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-0000000000c1', 'web', 'Chrome', 'a0000000-0000-0000-0000-000000000001'),
  ('b7000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000c1', 'web', 'Chrome', 'b0000000-0000-0000-0000-000000000001');

insert into public.activity_logs (profile_id, session_id, event_type, event_name, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000c1', 'a7000000-0000-0000-0000-000000000001', 'screen_view', 'home', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000c1', 'b7000000-0000-0000-0000-000000000001', 'screen_view', 'home', 'b0000000-0000-0000-0000-000000000001');

insert into public.notifications (user_id, title, body, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000c1', 'Hola A', 'Bienvenido', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000c1', 'Hola B', 'Bienvenido', 'b0000000-0000-0000-0000-000000000001');

insert into public.loyalty_points (profile_id, origen, puntos, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000c1', 'reserva', 1, 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000c1', 'reserva', 1, 'b0000000-0000-0000-0000-000000000001');

insert into public.email_verification_tokens (user_id, token, expires_at, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000c1', 'tok-a-email', now() + interval '1 day', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000c1', 'tok-b-email', now() + interval '1 day', 'b0000000-0000-0000-0000-000000000001');

insert into public.password_reset_tokens (user_id, token, expires_at, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000c1', 'tok-a-reset', now() + interval '1 day', 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000c1', 'tok-b-reset', now() + interval '1 day', 'b0000000-0000-0000-0000-000000000001');

insert into public.employee_time_off (employee_id, date, tenant_id) values
  ('a0000000-0000-0000-0000-0000000000e1', current_date + 5, 'a0000000-0000-0000-0000-000000000001'),
  ('b0000000-0000-0000-0000-0000000000e1', current_date + 5, 'b0000000-0000-0000-0000-000000000001');
