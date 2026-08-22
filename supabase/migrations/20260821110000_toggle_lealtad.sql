-- Nuevo toggle independiente para el programa de lealtad, igual patrón
-- que store_enabled/bookings_enabled — se agrega para que sysadmin pueda
-- prenderlo/apagarlo desde "Diseñador de vista" sin depender de Tienda
-- ni de Reservas (el usuario pidió esto al notar que Tickets/Lealtad
-- seguían visibles aunque apagara Reservas).
alter table public.app_config
  add column if not exists loyalty_enabled boolean not null default true;
