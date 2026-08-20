-- Prepara la base de datos para el borrado "estilo Facebook" de una cuenta:
-- se borra la cuenta de Auth Y el perfil por completo (para que el correo
-- quede libre para un registro nuevo), pero el historial de negocio
-- (reservas, pedidos, comisiones, reseñas) NO se borra — queda "sin dueño"
-- (columna en null) en vez de bloquear el borrado o desaparecer junto con
-- la cuenta. Pedido explícito del usuario tras confirmar que prefiere
-- conservar los registros a perderlos.
--
-- Antes estas columnas eran RESTRICT (bookings/commission_cuts/
-- commission_entries/orders) o CASCADE (reviews) — RESTRICT bloqueaba el
-- borrado por completo si la cuenta tenía cualquier historial, y CASCADE en
-- reviews borraba la reseña entera con la cuenta.

alter table public.bookings alter column client_id drop not null;
alter table public.bookings alter column employee_id drop not null;
alter table public.bookings drop constraint bookings_client_id_fkey;
alter table public.bookings add constraint bookings_client_id_fkey
  foreign key (client_id) references public.profiles(id) on delete set null;
alter table public.bookings drop constraint bookings_employee_id_fkey;
alter table public.bookings add constraint bookings_employee_id_fkey
  foreign key (employee_id) references public.profiles(id) on delete set null;

alter table public.commission_cuts alter column employee_id drop not null;
alter table public.commission_cuts drop constraint commission_cuts_employee_id_fkey;
alter table public.commission_cuts add constraint commission_cuts_employee_id_fkey
  foreign key (employee_id) references public.profiles(id) on delete set null;

alter table public.commission_entries alter column employee_id drop not null;
alter table public.commission_entries drop constraint commission_entries_employee_id_fkey;
alter table public.commission_entries add constraint commission_entries_employee_id_fkey
  foreign key (employee_id) references public.profiles(id) on delete set null;

alter table public.orders alter column client_id drop not null;
alter table public.orders drop constraint orders_client_id_fkey;
alter table public.orders add constraint orders_client_id_fkey
  foreign key (client_id) references public.profiles(id) on delete set null;

alter table public.reviews alter column client_id drop not null;
alter table public.reviews alter column employee_id drop not null;
alter table public.reviews drop constraint reviews_client_id_fkey;
alter table public.reviews add constraint reviews_client_id_fkey
  foreign key (client_id) references public.profiles(id) on delete set null;
alter table public.reviews drop constraint reviews_employee_id_fkey;
alter table public.reviews add constraint reviews_employee_id_fkey
  foreign key (employee_id) references public.profiles(id) on delete set null;
