-- ============================================================================
-- Multi-tenant, Fase 2 (parte 2/2): agrega tenant_id (NULLABLE) a las 27
-- tablas existentes + índices. Aditivo y seguro: sin tenant_id NOT NULL y
-- sin RLS tenant-aware todavía, la app sigue funcionando exactamente igual
-- que antes de esta migración — nada la filtra ni la exige todavía.
--
-- Excepción necesaria: app_config y loyalty_config usan hoy un PK singleton
-- (`id boolean primary key default true`, máximo 1 fila en TODA la tabla).
-- Eso es incompatible con "una fila de config por tenant", así que en estas
-- dos tablas (y solo en estas dos) esta migración además retira ese tope de
-- una sola fila global — sigue sin haber más de 1 fila hoy (no se inserta
-- nada nuevo aquí), simplemente deja de estar prohibido a nivel de schema.
--
-- Ver plan completo: C:\Users\HP\.claude\plans\stateful-dreaming-breeze.md
-- ============================================================================

-- ============================================================================
-- Tablas normales: agregar tenant_id nullable + índice
-- ============================================================================

alter table public.profiles               add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.services                add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.employee_services       add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.work_schedules          add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.bookings                add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.booking_extra_services  add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.reviews                 add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.products                add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.saved_products          add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.orders                  add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.order_items             add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.supplies                add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.commission_configs      add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.commission_cuts         add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.commission_entries      add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.session_logs            add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.activity_logs           add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.supply_purchases        add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.email_verification_tokens add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.password_reset_tokens   add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.employee_time_off       add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.notifications           add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.product_categories      add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.loyalty_points          add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;

create index if not exists idx_profiles_tenant               on public.profiles(tenant_id);
create index if not exists idx_services_tenant                on public.services(tenant_id);
create index if not exists idx_employee_services_tenant       on public.employee_services(tenant_id);
create index if not exists idx_work_schedules_tenant          on public.work_schedules(tenant_id);
create index if not exists idx_bookings_tenant                on public.bookings(tenant_id);
create index if not exists idx_booking_extra_services_tenant  on public.booking_extra_services(tenant_id);
create index if not exists idx_reviews_tenant                 on public.reviews(tenant_id);
create index if not exists idx_products_tenant                on public.products(tenant_id);
create index if not exists idx_saved_products_tenant          on public.saved_products(tenant_id);
create index if not exists idx_orders_tenant                  on public.orders(tenant_id);
create index if not exists idx_order_items_tenant             on public.order_items(tenant_id);
create index if not exists idx_supplies_tenant                on public.supplies(tenant_id);
create index if not exists idx_commission_configs_tenant      on public.commission_configs(tenant_id);
create index if not exists idx_commission_cuts_tenant         on public.commission_cuts(tenant_id);
create index if not exists idx_commission_entries_tenant      on public.commission_entries(tenant_id);
create index if not exists idx_session_logs_tenant            on public.session_logs(tenant_id);
create index if not exists idx_activity_logs_tenant           on public.activity_logs(tenant_id);
create index if not exists idx_supply_purchases_tenant        on public.supply_purchases(tenant_id);
create index if not exists idx_email_verification_tenant      on public.email_verification_tokens(tenant_id);
create index if not exists idx_password_reset_tenant          on public.password_reset_tokens(tenant_id);
create index if not exists idx_employee_time_off_tenant       on public.employee_time_off(tenant_id);
create index if not exists idx_notifications_tenant           on public.notifications(tenant_id);
create index if not exists idx_product_categories_tenant      on public.product_categories(tenant_id);
create index if not exists idx_loyalty_points_tenant          on public.loyalty_points(tenant_id);

-- ============================================================================
-- commission_settings: PK real (uuid), no necesita cirugía — solo tenant_id
-- + único por tenant (hoy es "single row global", mañana "single row por
-- tenant"; con 0-1 tenants reales sigue comportándose igual que hoy).
-- ============================================================================
alter table public.commission_settings add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
create unique index if not exists uq_commission_settings_tenant on public.commission_settings(tenant_id);

-- ============================================================================
-- app_config / loyalty_config: retirar el PK-singleton booleano, tenant_id
-- pasa a ser la clave de "una fila por tenant" (único, nullable por ahora).
-- ============================================================================

alter table public.app_config add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.app_config drop constraint if exists app_config_singleton;
alter table public.app_config drop constraint if exists app_config_pkey;
create unique index if not exists uq_app_config_tenant on public.app_config(tenant_id);
-- La columna `id boolean` queda como artefacto legado (sigue en `true` en la
-- única fila real de hoy) — se retira en una migración de limpieza posterior,
-- una vez tenant_id ya sea NOT NULL y esté siendo la clave real.

alter table public.loyalty_config add column if not exists tenant_id uuid references public.tenants(id) on delete restrict;
alter table public.loyalty_config drop constraint if exists loyalty_config_singleton;
alter table public.loyalty_config drop constraint if exists loyalty_config_pkey;
create unique index if not exists uq_loyalty_config_tenant on public.loyalty_config(tenant_id);
