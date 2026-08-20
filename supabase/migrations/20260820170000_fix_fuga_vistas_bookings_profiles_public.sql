-- HALLAZGO CRÍTICO (reportado por el usuario, verificado en vivo): las
-- vistas bookings_detailed y profiles_public son dueñas de "postgres" y NO
-- tienen security_invoker=true — en Postgres, una vista sin
-- security_invoker corre con los permisos de su DUEÑO, no de quien
-- consulta, así que ROW LEVEL SECURITY DE LA TABLA BASE SE IGNORA POR
-- COMPLETO. Cualquier usuario autenticado (o incluso anónimo, ambos tienen
-- GRANT SELECT) podía ver reservas y nombres/roles de perfiles de TODOS
-- los negocios, no solo el suyo. No es algo introducido hoy — ya existía
-- desde que se crearon estas vistas — pero se detectó hoy al ver reservas
-- demo de MC-BARBER apareciendo en pretty.prettycore.xyz.
--
-- Confirmado que otras dos vistas (employee_stats, popular_services) SÍ
-- tenían security_invoker=true desde su creación — el patrón correcto ya
-- se conocía en este proyecto, solo faltó aplicarlo a estas dos.

-- bookings_detailed: con security_invoker=true, hereda tal cual la política
-- bookings_select de la tabla bookings (ya correctamente filtrada por
-- current_tenant_id() + dueño/empleado/admin) — no necesita nada más.
alter view public.bookings_detailed set (security_invoker = true);

-- profiles_public: a diferencia de bookings, esta vista existe para que
-- CUALQUIER cliente (incluso invitado, sin sesión) pueda ver el nombre/
-- avatar de los empleados de SU negocio al reservar — la política RLS de
-- profiles (profiles_select_own_or_admin) es demasiado restrictiva para
-- ese caso de uso (un cliente normal no es admin/sysadmin, así que con
-- security_invoker=true dejaría de ver a nadie más que a sí mismo). Se
-- mantiene sin invoker, pero se le agrega el filtro de tenant directo en
-- la vista — basado en el DOMINIO de la solicitud (request_tenant_id(),
-- el header x-tenant-id), no en la cuenta de quien pregunta, para que
-- siga funcionando igual para invitados sin sesión.
create or replace view public.profiles_public as
select id, full_name, avatar_url, role, bio, is_active, created_at
from public.profiles
where tenant_id = public.request_tenant_id();
