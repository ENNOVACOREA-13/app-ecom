-- Arregla la CAUSA, no solo los síntomas ya encontrados (comisiones,
-- horarios, servicios de empleado, días libres): tenant_id era NOT NULL
-- sin default en cada tabla operativa, así que CUALQUIER insert/upsert
-- del cliente que olvidara mandarlo tronaba — un error fácil de cometer y
-- fácil de no notar en desarrollo (las filas de prueba casi siempre ya
-- existen, así que solo se nota la PRIMERA vez que alguien crea algo
-- nuevo de verdad). Con este default, si el cliente no lo manda, se
-- rellena solo con el tenant de quien hace la petición — mismo criterio
-- que ya usa toda la RLS del proyecto. No cambia nada para el código que
-- YA manda tenant_id explícito (la mayoría) — el default nunca se activa
-- ahí.
--
-- A propósito NO se les puso a: profiles (current_tenant_id() lee de
-- profiles.tenant_id como último recurso — ponerle el default a la misma
-- columna que la función consulta sería circular), password_reset_tokens
-- y email_verification_tokens (los crean Edge Functions con service_role,
-- sin un usuario "actual" real, y ya mandan tenant_id explícito siempre),
-- ni tenant_domains/user_tenant_memberships (los crea platform_admin, que
-- no tiene "un" tenant propio — current_tenant_id() no sería el valor
-- correcto ahí).
do $$
declare
  t text;
begin
  foreach t in array array[
    'activity_logs', 'app_config', 'booking_extra_services', 'bookings',
    'commission_configs', 'commission_cuts', 'commission_entries',
    'commission_settings', 'employee_services', 'employee_time_off',
    'loyalty_config', 'loyalty_points', 'notifications', 'order_items',
    'orders', 'product_categories', 'products', 'reviews',
    'saved_products', 'services', 'session_logs', 'supplies',
    'supply_purchases', 'work_schedules'
  ]
  loop
    execute format(
      'alter table public.%I alter column tenant_id set default public.current_tenant_id()',
      t);
  end loop;
end $$;
