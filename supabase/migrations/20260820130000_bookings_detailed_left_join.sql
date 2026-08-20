-- bookings_detailed usaba JOIN (inner) contra profiles_public para
-- client_id/employee_id — desde que esas columnas de bookings pueden ser
-- null (cuenta eliminada, ver 20260820120000), una reserva de un cliente o
-- empleado eliminado desaparecía POR COMPLETO de todas las consultas que
-- leen esta vista (dashboard, mis reservas, reservas del empleado, e
-- incluso el lookup del escaneo de QR), en vez de solo mostrar "Cuenta
-- eliminada" en el nombre. Cambiado a LEFT JOIN para que la reserva se
-- siga viendo con client_name/employee_name en null.
create or replace view public.bookings_detailed as
select
  b.id,
  b.client_id,
  b.employee_id,
  b.service_id,
  b.booking_date,
  b.start_time,
  b.end_time,
  b.status,
  b.total_price,
  b.notes,
  b.cancel_reason,
  b.created_at,
  c.full_name as client_name,
  e.full_name as employee_name,
  s.name as service_name,
  s.duration_min,
  b.cancel_requested,
  b.cancel_requested_at,
  b.paid_at
from public.bookings b
left join public.profiles_public c on c.id = b.client_id
left join public.profiles_public e on e.id = b.employee_id
join public.services s on s.id = b.service_id;
