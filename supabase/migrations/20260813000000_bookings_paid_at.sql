-- Registra la fecha real de pago de una reserva (distinta de la fecha de la
-- cita), para poder mostrarla en el ticket del cliente.

alter table public.bookings
  add column if not exists paid_at timestamptz;

create or replace function public.fn_bookings_set_paid_at()
returns trigger
language plpgsql
as $$
begin
  if new.status = 'completed'
     and (old.status is distinct from 'completed')
     and new.paid_at is null then
    new.paid_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists trg_bookings_set_paid_at on public.bookings;
create trigger trg_bookings_set_paid_at
  before update on public.bookings
  for each row execute function public.fn_bookings_set_paid_at();

-- CREATE OR REPLACE VIEW no permite insertar una columna en medio de las
-- existentes (solo agregar al final) — por eso paid_at va al final, no junto
-- a las demás columnas de bookings.
create or replace view public.bookings_detailed
with (security_invoker = true) as
select
  b.id, b.client_id, b.employee_id, b.service_id,
  b.booking_date, b.start_time, b.end_time,
  b.status, b.total_price, b.notes, b.cancel_reason, b.created_at,
  c.full_name  as client_name,
  e.full_name  as employee_name,
  s.name       as service_name,
  s.duration_min,
  b.cancel_requested, b.cancel_requested_at,
  b.paid_at
from public.bookings b
join public.profiles_public c on c.id = b.client_id
join public.profiles_public e on e.id = b.employee_id
join public.services s on s.id = b.service_id;
