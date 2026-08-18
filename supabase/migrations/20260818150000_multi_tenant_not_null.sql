-- ============================================================================
-- Multi-tenant, Fase 6: tenant_id pasa a NOT NULL en las 27 tablas reales.
--
-- Solo segura de correr DESPUÉS de que el backfill de datos reales esté
-- 100% verificado (0 nulls, conteos/sumas de dinero idénticos al origen) —
-- ver supabase/multi_tenant_rehearsal/05_fase5_real_migration_procedure.md.
-- Aplicada por primera vez 2026-08-18 durante el corte real de MC-BARBER,
-- después del backfill real (no en este archivo — el backfill de datos no
-- es una migración de schema, se corrió aparte contra los datos ya
-- restaurados).
-- ============================================================================

alter table public.profiles alter column tenant_id set not null;
alter table public.services alter column tenant_id set not null;
alter table public.employee_services alter column tenant_id set not null;
alter table public.work_schedules alter column tenant_id set not null;
alter table public.bookings alter column tenant_id set not null;
alter table public.booking_extra_services alter column tenant_id set not null;
alter table public.reviews alter column tenant_id set not null;
alter table public.products alter column tenant_id set not null;
alter table public.saved_products alter column tenant_id set not null;
alter table public.orders alter column tenant_id set not null;
alter table public.order_items alter column tenant_id set not null;
alter table public.supplies alter column tenant_id set not null;
alter table public.supply_purchases alter column tenant_id set not null;
alter table public.app_config alter column tenant_id set not null;
alter table public.commission_configs alter column tenant_id set not null;
alter table public.commission_settings alter column tenant_id set not null;
alter table public.commission_cuts alter column tenant_id set not null;
alter table public.commission_entries alter column tenant_id set not null;
alter table public.session_logs alter column tenant_id set not null;
alter table public.activity_logs alter column tenant_id set not null;
alter table public.email_verification_tokens alter column tenant_id set not null;
alter table public.password_reset_tokens alter column tenant_id set not null;
alter table public.employee_time_off alter column tenant_id set not null;
alter table public.notifications alter column tenant_id set not null;
alter table public.product_categories alter column tenant_id set not null;
alter table public.loyalty_config alter column tenant_id set not null;
alter table public.loyalty_points alter column tenant_id set not null;
