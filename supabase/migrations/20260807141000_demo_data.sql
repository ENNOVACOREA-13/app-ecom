-- ============================================================================
-- DATOS DEMO — temporales, para ver la app con contenido real.
-- Corre esto DESPUÉS de 20260807130000_seed_users.sql y
-- 20260807140000_fix_profiles_role_escalation.sql.
--
-- Todo lo que crea este script queda marcado para poder borrarlo fácil:
--   - servicios/productos/insumos:  el nombre termina en " (demo)"
--   - empleados nuevos:             correo termina en ".demo@example.com"
-- Usa supabase/demo_data_cleanup.sql cuando quieras quitarlo todo.
--
-- Qué mete:
--   - 2 empleados nuevos (Carlos, Miguel) + horario Lun–Sáb 11:00–20:00
--     para ellos y para el empleado real (ennovajesus@gmail.com)
--   - 5 servicios, repartidos entre los 3 empleados
--   - 4 productos de tienda
--   - 4 reservas del cliente (juremaguilar@icloud.com) con 3 empleados
--     distintos y 4 estados distintos (pending/confirmed/completed/cancelled)
--     -> así puedes verificar que cada una aparece en el panel del empleado
--        correcto y NO en el de los otros.
--   - comisión configurada + 1 entrada de comisión (de la reserva completada)
--   - 1 reseña (de la reserva completada)
--   - 1 pedido de tienda con 2 productos
--   - 2 insumos y 1 producto guardado (favorito)
-- ============================================================================

do $$
declare
  v_instance_id uuid := '00000000-0000-0000-0000-000000000000';
  v_password    text := 'PRETTYCORE13';
  v_row         record;

  v_client_id      uuid;
  v_admin_id       uuid;
  v_emp_ennova     uuid;
  v_emp_carlos     uuid;
  v_emp_miguel     uuid;

  v_svc_corte        uuid;
  v_svc_corte_barba  uuid;
  v_svc_barba        uuid;
  v_svc_degradado    uuid;
  v_svc_tinte        uuid;

  v_prod_pomada   uuid;
  v_prod_aceite   uuid;
  v_prod_shampoo  uuid;
  v_prod_cera     uuid;

  v_booking_completada uuid;
  v_booking_confirmada uuid;
  v_booking_pendiente  uuid;
  v_booking_cancelada  uuid;

  v_order_id uuid;
begin
  -- ── Guard: si ya corriste esto antes, no dupliques nada ─────────────────
  if exists (select 1 from public.services where name = 'Corte de cabello (demo)') then
    raise notice 'Los datos demo ya existen. No se insertó nada de nuevo.';
    return;
  end if;

  select id into v_client_id from auth.users where email = 'juremaguilar@icloud.com';
  select id into v_admin_id  from auth.users where email = 'sysadmin@prettycore.xyz';
  select id into v_emp_ennova from auth.users where email = 'ennovajesus@gmail.com';

  if v_client_id is null or v_admin_id is null or v_emp_ennova is null then
    raise exception 'Corre primero 20260807130000_seed_users.sql (faltan los usuarios base)';
  end if;

  -- ── 2 empleados demo nuevos ──────────────────────────────────────────────
  for v_row in
    select * from (values
      ('carlos.demo@example.com', 'Carlos Ramírez', 'Especialista en cortes clásicos y degradados'),
      ('miguel.demo@example.com', 'Miguel Torres',  'Experto en barba y tratamientos capilares')
    ) as t(email, full_name, bio)
  loop
    declare
      v_uid uuid := gen_random_uuid();
    begin
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, last_sign_in_at,
        raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at,
        confirmation_token, recovery_token,
        email_change, email_change_token_new, email_change_token_current,
        phone_change, phone_change_token, reauthentication_token
      ) values (
        v_instance_id, v_uid, 'authenticated', 'authenticated',
        v_row.email, crypt(v_password, gen_salt('bf')),
        now(), now(),
        jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
        jsonb_build_object('full_name', v_row.full_name, 'role', 'employee'),
        now(), now(),
        '', '', '', '', '', '', '', ''
      );

      insert into auth.identities (
        id, provider_id, user_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(), v_uid::text, v_uid,
        jsonb_build_object('sub', v_uid::text, 'email', v_row.email,
                            'email_verified', true, 'phone_verified', false),
        'email', now(), now(), now()
      );

      update public.profiles set bio = v_row.bio where id = v_uid;
    end;
  end loop;

  select id into v_emp_carlos from auth.users where email = 'carlos.demo@example.com';
  select id into v_emp_miguel from auth.users where email = 'miguel.demo@example.com';
  update public.profiles set bio = 'Barbero senior, +5 años de experiencia' where id = v_emp_ennova;

  -- ── Horario Lun–Sáb 11:00–20:00 para los 3 empleados ────────────────────
  insert into public.work_schedules (employee_id, day_of_week, start_time, end_time)
  select emp, day, '11:00'::time, '20:00'::time
  from unnest(array[v_emp_ennova, v_emp_carlos, v_emp_miguel]) as emp
  cross join unnest(array['monday','tuesday','wednesday','thursday','friday','saturday']) as day;

  -- ── Servicios ────────────────────────────────────────────────────────────
  insert into public.services (name, description, duration_min, price)
  values ('Corte de cabello (demo)', 'Corte clásico con tijera y máquina', 30, 150)
  returning id into v_svc_corte;

  insert into public.services (name, description, duration_min, price)
  values ('Corte + Barba (demo)', 'Corte completo más arreglo de barba', 45, 220)
  returning id into v_svc_corte_barba;

  insert into public.services (name, description, duration_min, price)
  values ('Arreglo de barba (demo)', 'Perfilado y arreglo profesional', 20, 100)
  returning id into v_svc_barba;

  insert into public.services (name, description, duration_min, price)
  values ('Corte degradado (demo)', 'Degradado moderno a máquina', 40, 180)
  returning id into v_svc_degradado;

  insert into public.services (name, description, duration_min, price)
  values ('Tinte de cabello (demo)', 'Coloración completa con productos premium', 90, 350)
  returning id into v_svc_tinte;

  insert into public.employee_services (employee_id, service_id) values
    (v_emp_ennova, v_svc_corte), (v_emp_ennova, v_svc_corte_barba), (v_emp_ennova, v_svc_barba),
    (v_emp_carlos, v_svc_corte), (v_emp_carlos, v_svc_degradado),
    (v_emp_miguel, v_svc_corte_barba), (v_emp_miguel, v_svc_tinte), (v_emp_miguel, v_svc_barba);

  -- ── Productos de tienda ─────────────────────────────────────────────────
  insert into public.products (name, description, price, stock, created_by)
  values ('Pomada para cabello (demo)', 'Fijación fuerte, acabado mate', 180, 23, v_admin_id)
  returning id into v_prod_pomada;

  insert into public.products (name, description, price, stock, created_by)
  values ('Aceite para barba (demo)', 'Hidrata y suaviza, aroma amaderado', 150, 14, v_admin_id)
  returning id into v_prod_aceite;

  insert into public.products (name, description, price, stock, created_by)
  values ('Shampoo anticaspa (demo)', 'Uso diario, control de caspa', 120, 30, v_admin_id)
  returning id into v_prod_shampoo;

  insert into public.products (name, description, price, sale_price, stock, created_by)
  values ('Cera moldeadora (demo)', 'Brillo medio, fácil de peinar', 160, 130, 20, v_admin_id)
  returning id into v_prod_cera;

  -- ── Reservas repartidas entre los 3 empleados y 4 estados distintos ─────
  insert into public.bookings
    (client_id, employee_id, service_id, booking_date, start_time, end_time, status, total_price, notes)
  values
    (v_client_id, v_emp_ennova, v_svc_barba, current_date - 3, '11:00', '11:20', 'completed', 100,
     'Reserva demo completada')
  returning id into v_booking_completada;

  insert into public.bookings
    (client_id, employee_id, service_id, booking_date, start_time, end_time, status, total_price, notes)
  values
    (v_client_id, v_emp_carlos, v_svc_corte, current_date + 1, '12:00', '12:30', 'confirmed', 150,
     'Reserva demo confirmada')
  returning id into v_booking_confirmada;

  insert into public.bookings
    (client_id, employee_id, service_id, booking_date, start_time, end_time, status, total_price, notes)
  values
    (v_client_id, v_emp_miguel, v_svc_corte_barba, current_date + 2, '16:00', '16:45', 'pending', 220,
     'Reserva demo pendiente')
  returning id into v_booking_pendiente;

  insert into public.bookings
    (client_id, employee_id, service_id, booking_date, start_time, end_time, status, total_price,
     notes, cancel_reason)
  values
    (v_client_id, v_emp_carlos, v_svc_degradado, current_date - 1, '13:00', '13:40', 'cancelled', 180,
     'Reserva demo cancelada', 'Cliente reagendó')
  returning id into v_booking_cancelada;

  -- ── Comisiones ───────────────────────────────────────────────────────────
  insert into public.commission_configs (service_id, amount) values
    (v_svc_corte, 30), (v_svc_corte_barba, 50), (v_svc_barba, 25),
    (v_svc_degradado, 40), (v_svc_tinte, 80);

  insert into public.commission_entries
    (employee_id, booking_id, service_id, service_name, service_price, commission_amount, earned_at)
  values
    (v_emp_ennova, v_booking_completada, v_svc_barba, 'Arreglo de barba (demo)', 100, 25, now() - interval '3 days');

  -- ── Reseña de la cita completada ──────────────────────────────────────────
  insert into public.reviews (booking_id, client_id, employee_id, rating, comment, created_at)
  values (v_booking_completada, v_client_id, v_emp_ennova, 5,
          'Excelente servicio, muy profesional. ¡Totalmente recomendado!', now() - interval '3 days');

  -- ── Pedido de tienda ──────────────────────────────────────────────────────
  insert into public.orders (client_id, total, status, payment_method, payment_status, notes, created_at)
  values (v_client_id, 510, 'delivered', 'cash', 'paid', 'Pedido demo', now() - interval '2 days')
  returning id into v_order_id;

  insert into public.order_items (order_id, product_id, product_name, quantity, unit_price) values
    (v_order_id, v_prod_pomada, 'Pomada para cabello (demo)', 2, 180),
    (v_order_id, v_prod_aceite, 'Aceite para barba (demo)', 1, 150);

  -- ── Insumos y favorito ────────────────────────────────────────────────────
  insert into public.supplies (name, description, price, stock, unit, created_by) values
    ('Toallas desechables (demo)', 'Paquete de 100', 2.5, 100, 'unidad', v_admin_id),
    ('Shampoo profesional 1L (demo)', 'Uso en sala', 180, 10, 'litro', v_admin_id);

  insert into public.saved_products (user_id, product_id) values (v_client_id, v_prod_cera);

  raise notice 'Datos demo creados correctamente.';
end $$;

-- ── Verificación: reservas con el nombre del empleado y su estado ─────────
select booking_date, start_time, status, employee_name, service_name, client_name
from public.bookings_detailed
where notes like 'Reserva demo%'
order by booking_date;
