-- Mismo patrón que store_enabled (20260811170000): permite a sysadmin
-- apagar las reservas en toda la app sin tocar la tienda de productos.
alter table app_config
  add column if not exists bookings_enabled boolean not null default true;
