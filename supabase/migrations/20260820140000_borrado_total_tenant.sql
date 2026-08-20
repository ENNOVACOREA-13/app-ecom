-- Permite borrar un negocio por completo ("borrado total e irreversible",
-- pedido explícito del usuario) — hoy CUALQUIER tabla con datos del tenant
-- bloquea el borrado (RESTRICT), así que ni siquiera se podía intentar.
--
-- Cambia todas las FK tenant_id de RESTRICT a CASCADE: al borrar la fila
-- de tenants, TODO lo que le pertenece se borra en la misma operación
-- (reservas, pedidos, productos, servicios, comisiones, perfiles de sus
-- clientes/empleados/admins, etc.). Como cada una de estas tablas ya tiene
-- su propia columna tenant_id apuntando directo a tenants, no hace falta
-- tocar sus otras relaciones (profiles.id, services.id, etc.) — se barren
-- todas en el mismo cascade, sin dejar referencias colgando.
do $$
declare
  t text;
begin
  foreach t in array array[
    'activity_logs', 'app_config', 'booking_extra_services', 'bookings',
    'commission_configs', 'commission_cuts', 'commission_entries',
    'commission_settings', 'email_verification_tokens', 'employee_services',
    'employee_time_off', 'loyalty_config', 'loyalty_points', 'notifications',
    'order_items', 'orders', 'password_reset_tokens', 'product_categories',
    'products', 'profiles', 'reviews', 'saved_products', 'services',
    'session_logs', 'supplies', 'supply_purchases', 'work_schedules'
  ]
  loop
    execute format(
      'alter table public.%I drop constraint %I_tenant_id_fkey', t, t);
    execute format(
      'alter table public.%I add constraint %I_tenant_id_fkey '
      'foreign key (tenant_id) references public.tenants(id) on delete cascade',
      t, t);
  end loop;
end $$;

-- bloquear_eliminacion_sysadmin() bloquea SIEMPRE borrar un perfil
-- role='sysadmin' — correcto para un borrado individual (admin-delete-user),
-- pero también bloquearía por completo el borrado de un tenant que tenga
-- su propio sysadmin (cosa normal: "Invitar sysadmin" existe para eso).
-- Se agrega una válvula de escape vía un GUC de sesión que SOLO la Edge
-- Function admin-delete-tenant enciende explícitamente antes del borrado
-- en cascada — cualquier otro camino (RLS, admin-delete-user, SQL directo
-- sin ese GUC) sigue bloqueado exactamente igual que antes.
create or replace function public.bloquear_eliminacion_sysadmin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.role = 'sysadmin'
     and coalesce(current_setting('app.borrando_tenant_en_cascada', true), 'false') <> 'true' then
    raise exception 'No se puede eliminar una cuenta sysadmin';
  end if;
  return old;
end;
$$;
