-- ============================================================================
-- Solicitud de cancelación para reservas ya CONFIRMADAS.
-- El cliente ya no cancela directo una reserva confirmada — solo "solicita"
-- cancelarla, y el admin aprueba o rechaza desde el panel de Reservas.
-- (Las reservas 'pending' se siguen pudiendo cancelar directo, sin cambios.)
--
-- Corre esto en el SQL Editor de Supabase.
-- ============================================================================

alter table public.bookings
  add column if not exists cancel_requested boolean not null default false,
  add column if not exists cancel_requested_at timestamptz;

-- Vista actualizada: expone el nuevo campo
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
  b.cancel_requested, b.cancel_requested_at
from public.bookings b
join public.profiles c on c.id = b.client_id
join public.profiles e on e.id = b.employee_id
join public.services s on s.id = b.service_id;

-- Permite que admin/sysadmin actualicen bookings directamente
-- (lo usa el botón "Rechazar" para poner cancel_requested de vuelta en false)
drop policy if exists "bookings_update_admin" on public.bookings;
create policy "bookings_update_admin" on public.bookings
  for update to authenticated using (public.is_admin_or_sysadmin());

-- RPC: el cliente marca su reserva confirmada como "cancelación solicitada"
create or replace function public.solicitar_cancelacion_reserva(p_booking_id uuid)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  update public.bookings
  set cancel_requested = true, cancel_requested_at = now()
  where id = p_booking_id
    and client_id = v_uid
    and status = 'confirmed';

  if not found then
    raise exception 'NOT_AUTHORIZED_OR_NOT_FOUND';
  end if;
end;
$$;
grant execute on function public.solicitar_cancelacion_reserva(uuid) to authenticated;
