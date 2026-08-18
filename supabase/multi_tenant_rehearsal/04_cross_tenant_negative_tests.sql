-- Suite de pruebas negativas cruzadas — gate obligatorio de Fase 4.
-- Logueado como Tenant A, confirma que NADA de Tenant B es visible/editable,
-- Y que Tenant A sigue viendo/editando lo suyo con normalidad (un RLS que
-- bloquea todo "pasaría" un chequeo de fugas sin servir para nada).

\set tenant_a 'a0000000-0000-0000-0000-000000000001'
\set tenant_b 'b0000000-0000-0000-0000-000000000001'
\set cliente_a 'a0000000-0000-0000-0000-0000000000c1'
\set empleado_a 'a0000000-0000-0000-0000-0000000000e1'
\set admin_a 'a0000000-0000-0000-0000-0000000000ad'
\set servicio_a 'a1000000-0000-0000-0000-000000000001'
\set producto_a 'a3000000-0000-0000-0000-000000000001'
\set booking_a 'a5000000-0000-0000-0000-000000000001'
\set orden_a 'a6000000-0000-0000-0000-000000000001'

\set cliente_b 'b0000000-0000-0000-0000-0000000000c1'
\set empleado_b 'b0000000-0000-0000-0000-0000000000e1'
\set servicio_b 'b1000000-0000-0000-0000-000000000001'
\set booking_b 'b5000000-0000-0000-0000-000000000001'
\set orden_b 'b6000000-0000-0000-0000-000000000001'

-- ── Simular sesión: authenticated, logueado como Cliente A ───────────────
set role authenticated;
select set_config('request.jwt.claims', json_build_object('sub', :'cliente_a')::text, false);

select '1. Cliente A ve su propia reserva (positivo)' as prueba,
  count(*) as filas, (count(*) = 1) as ok
from public.bookings where id = :'booking_a';

select '2. Cliente A NO ve la reserva de B (negativo)' as prueba,
  count(*) as filas, (count(*) = 0) as ok
from public.bookings where id = :'booking_b';

select '3. Cliente A ve solo servicios de su tenant en el catálogo' as prueba,
  count(*) filter (where tenant_id = :'tenant_b') as filas_de_b_visibles,
  (count(*) filter (where tenant_id = :'tenant_b') = 0) as ok
from public.services;

select '4. Cliente A NO puede leer profiles de otro tenant' as prueba,
  count(*) as filas, (count(*) = 0) as ok
from public.profiles where id = :'cliente_b';

select '5. Cliente A NO puede leer commission_entries de B' as prueba,
  count(*) as filas, (count(*) = 0) as ok
from public.commission_entries where tenant_id = :'tenant_b';

-- crear_reserva con employee_id/service_id de OTRO tenant debe fallar
do $$
begin
  perform public.crear_reserva(
    'b0000000-0000-0000-0000-0000000000e1'::uuid, -- empleado de B
    'a1000000-0000-0000-0000-000000000001'::uuid, -- servicio de A
    current_date + 1, '11:00'::time, null, null
  );
  raise notice '6. FALLO: crear_reserva con employee_id cruzado NO lanzó excepción (ok=false)';
exception when others then
  raise notice '6. OK: crear_reserva con employee_id cruzado fue rechazado (%) (ok=true)', sqlerrm;
end $$;

do $$
begin
  perform public.crear_reserva(
    'a0000000-0000-0000-0000-0000000000e1'::uuid, -- empleado de A (correcto)
    'b1000000-0000-0000-0000-000000000001'::uuid, -- servicio de B (cruzado)
    current_date + 1, '12:00'::time, null, null
  );
  raise notice '7. FALLO: crear_reserva con service_id cruzado NO lanzó excepción (ok=false)';
exception when others then
  raise notice '7. OK: crear_reserva con service_id cruzado fue rechazado (%) (ok=true)', sqlerrm;
end $$;

-- crear_reserva con datos 100% de A debe funcionar (positivo)
do $$
declare
  v_id uuid;
begin
  select id into v_id from public.crear_reserva(
    'a0000000-0000-0000-0000-0000000000e1'::uuid,
    'a1000000-0000-0000-0000-000000000001'::uuid,
    current_date + 2, '15:00'::time, 'prueba positiva', null
  );
  raise notice '8. OK: crear_reserva 100%% tenant A funcionó, booking % (ok=true)', v_id;
exception when others then
  raise notice '8. FALLO: crear_reserva 100%% tenant A fue rechazado (%) (ok=false)', sqlerrm;
end $$;

-- UPDATE directo (bypass RPC) contra una reserva de B como admin de A
set role authenticated;
select set_config('request.jwt.claims', json_build_object('sub', :'admin_a')::text, false);

do $$
declare
  v_filas int;
begin
  update public.bookings set status = 'cancelled' where id = 'b5000000-0000-0000-0000-000000000001';
  get diagnostics v_filas = row_count;
  if v_filas = 0 then
    raise notice '9. OK: UPDATE directo de admin A sobre booking de B afectó 0 filas (ok=true)';
  else
    raise notice '9. FALLO: UPDATE directo de admin A sobre booking de B afectó % filas (ok=false)', v_filas;
  end if;
end $$;

-- actualizar_estado_pedido sobre una orden de B, como admin de A
do $$
begin
  perform public.actualizar_estado_pedido('b6000000-0000-0000-0000-000000000001'::uuid, 'cancelled');
  raise notice '10. FALLO: actualizar_estado_pedido cruzado NO lanzó excepción (ok=false)';
exception when others then
  raise notice '10. OK: actualizar_estado_pedido cruzado fue rechazado (%) (ok=true)', sqlerrm;
end $$;

-- ajustar_puntos_lealtad sobre un cliente de B, como admin de A
do $$
begin
  perform public.ajustar_puntos_lealtad('b0000000-0000-0000-0000-0000000000c1'::uuid, 10, 'cruzado');
  raise notice '11. FALLO: ajustar_puntos_lealtad cruzado NO lanzó excepción (ok=false)';
exception when others then
  raise notice '11. OK: ajustar_puntos_lealtad cruzado fue rechazado (%) (ok=true)', sqlerrm;
end $$;

-- process_commission_cut como admin A: NO debe tocar entries de B
select public.process_commission_cut(current_date - 7, current_date + 7);
select '12. process_commission_cut de A no genera cortes para empleado de B' as prueba,
  count(*) as filas, (count(*) = 0) as ok
from public.commission_cuts where employee_id = 'b0000000-0000-0000-0000-0000000000e1';
select '12b. ...pero SI genera el corte del empleado de A (positivo)' as prueba,
  count(*) as filas, (count(*) = 1) as ok
from public.commission_cuts where employee_id = 'a0000000-0000-0000-0000-0000000000e1';

-- ── anon con header x-tenant-id = A: solo debe ver catálogo de A ─────────
reset role;
set role anon;
select set_config('request.jwt.claims', '{}', false);
select set_config('request.headers', json_build_object('x-tenant-id', :'tenant_a')::text, false);

select '13. anon con header tenant A solo ve productos de A' as prueba,
  count(*) filter (where tenant_id = :'tenant_b') as productos_de_b_visibles,
  count(*) filter (where tenant_id = :'tenant_a') as productos_de_a_visibles,
  (count(*) filter (where tenant_id = :'tenant_b') = 0 and count(*) filter (where tenant_id = :'tenant_a') = 1) as ok
from public.products;

reset role;
