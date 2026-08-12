-- ============================================================================
-- Borra TODO lo que metió 20260807141000_demo_data.sql (y a los 2 empleados
-- demo que creó), sin tocar tus 3 cuentas reales
-- (juremaguilar@icloud.com, ennovajesus@gmail.com, sysadmin@prettycore.xyz)
-- ni sus reservas/horarios/bio reales.
--
-- Corre esto en el SQL Editor cuando ya hayas terminado de ver la demo.
-- ============================================================================

do $$
declare
  v_emp_carlos uuid;
  v_emp_miguel uuid;
begin
  select id into v_emp_carlos from auth.users where email = 'carlos.demo@example.com';
  select id into v_emp_miguel from auth.users where email = 'miguel.demo@example.com';

  -- Hijos de las reservas demo (por notes)
  delete from public.commission_entries
    where booking_id in (select id from public.bookings where notes like 'Reserva demo%');
  delete from public.reviews
    where booking_id in (select id from public.bookings where notes like 'Reserva demo%');
  delete from public.booking_extra_services
    where booking_id in (select id from public.bookings where notes like 'Reserva demo%');
  delete from public.bookings where notes like 'Reserva demo%';

  -- Comisiones configuradas para los servicios demo
  delete from public.commission_configs
    where service_id in (select id from public.services where name like '%(demo)%');

  -- Pedido y favorito demo
  delete from public.order_items
    where product_id in (select id from public.products where name like '%(demo)%');
  delete from public.orders where notes = 'Pedido demo';
  delete from public.saved_products
    where product_id in (select id from public.products where name like '%(demo)%');

  -- Relaciones empleado-servicio y horarios de los empleados demo
  if v_emp_carlos is not null or v_emp_miguel is not null then
    delete from public.work_schedules where employee_id in (v_emp_carlos, v_emp_miguel);
    delete from public.employee_services where employee_id in (v_emp_carlos, v_emp_miguel);
  end if;
  -- También el horario que se le agregó al empleado real (ennovajesus)
  delete from public.work_schedules
    where employee_id = (select id from auth.users where email = 'ennovajesus@gmail.com');
  delete from public.employee_services
    where employee_id = (select id from auth.users where email = 'ennovajesus@gmail.com')
      and service_id in (select id from public.services where name like '%(demo)%');

  -- Insumos, productos y servicios demo
  delete from public.supplies where name like '%(demo)%';
  delete from public.products where name like '%(demo)%';
  delete from public.services where name like '%(demo)%';

  -- Los 2 empleados demo (auth.users -> profiles cae por ON DELETE CASCADE)
  if v_emp_carlos is not null then delete from auth.users where id = v_emp_carlos; end if;
  if v_emp_miguel is not null then delete from auth.users where id = v_emp_miguel; end if;

  raise notice 'Datos demo eliminados.';
end $$;
