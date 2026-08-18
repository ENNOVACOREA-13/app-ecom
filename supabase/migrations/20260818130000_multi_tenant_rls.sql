-- ============================================================================
-- Multi-tenant, Fase 4 (parte 1/2): RLS tenant-aware en las 27 tablas reales.
--
-- ⚠️ ESTA ES LA MIGRACIÓN DE MAYOR RIESGO DEL PROYECTO. No aplicar contra el
-- proyecto Cloud real hasta correr la suite de pruebas negativas cruzadas
-- (ver supabase/multi_tenant_rehearsal/) contra 2 tenants sintéticos y
-- confirmar 0 fugas. Ver plan: C:\Users\HP\.claude\plans\stateful-dreaming-breeze.md
--
-- Patrón: cada policy existente se reescribe agregando el filtro de tenant
-- como una cláusula SEPARADA y auditable (nunca escondida dentro de
-- is_admin()/is_sysadmin()/is_admin_or_sysadmin(), que siguen intocados y
-- solo verifican rol). Todas las policies se DROPean y recrean —
-- reproducible, no acumulativo.
--
-- tenant_id sigue siendo NULLABLE en este punto (la migración NOT NULL real
-- viene después del backfill de datos reales, Fase 5/6) — pero a partir de
-- aquí toda fila con tenant_id null deja de ser visible/editable para
-- cualquiera excepto un platform_admin explícito, así que el backfill real
-- debe completarse ANTES de que usuarios reales dependan de estas policies.
-- ============================================================================

-- ── Helpers de tenant para acceso anónimo (catálogo público) ─────────────
-- request_tenant_id(): lee el header x-tenant-id que pone el cliente Flutter
-- (tenant_resolver.dart) ANTES de tener sesión. Es spoofeable por diseño —
-- por eso solo se usa en tablas ya pensadas para ser públicas (catálogo),
-- nunca en nada con datos personales/dinero.
create or replace function public.request_tenant_id()
returns uuid language sql stable as $$
  select nullif(current_setting('request.headers', true)::json->>'x-tenant-id', '')::uuid;
$$;

-- effective_tenant_id(): el tenant real del usuario autenticado si lo hay
-- (a prueba de manipulación, viene de profiles server-side); si no hay
-- sesión, cae al header (solo relevante para anon en catálogo público).
create or replace function public.effective_tenant_id()
returns uuid language sql stable as $$
  select coalesce(public.current_tenant_id(), public.request_tenant_id());
$$;

-- ============================================================================
-- profiles
-- ============================================================================
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin" on public.profiles
  for select to authenticated
  using (id = auth.uid() or (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin()));

-- Sin cambio: la asignación real de tenant_id en el alta ocurre en
-- handle_new_user() (SECURITY DEFINER, bypassea RLS) — ver parte 2/2.
drop policy if exists "profiles_insert_self" on public.profiles;
create policy "profiles_insert_self" on public.profiles
  for insert to authenticated with check (id = auth.uid() and role = 'client');

drop policy if exists "profiles_update_self_or_admin" on public.profiles;
create policy "profiles_update_self_or_admin" on public.profiles
  for update to authenticated
  using (id = auth.uid() or (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin()))
  with check (
    (id = auth.uid() and role = public.my_profile_role() and tenant_id = public.current_tenant_id())
    or (public.is_admin_or_sysadmin() and tenant_id = public.current_tenant_id())
  );

drop policy if exists "profiles_delete_admin" on public.profiles;
create policy "profiles_delete_admin" on public.profiles
  for delete to authenticated using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

-- ============================================================================
-- services (catálogo público)
-- ============================================================================
drop policy if exists "services_select_public" on public.services;
create policy "services_select_public" on public.services
  for select to anon, authenticated using (tenant_id = public.effective_tenant_id());
drop policy if exists "services_write_admin" on public.services;
create policy "services_write_admin" on public.services
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

-- ============================================================================
-- employee_services
-- ============================================================================
drop policy if exists "employee_services_select_public" on public.employee_services;
create policy "employee_services_select_public" on public.employee_services
  for select to anon, authenticated using (tenant_id = public.effective_tenant_id());
drop policy if exists "employee_services_write_admin" on public.employee_services;
create policy "employee_services_write_admin" on public.employee_services
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

-- ============================================================================
-- work_schedules
-- ============================================================================
drop policy if exists "work_schedules_select" on public.work_schedules;
create policy "work_schedules_select" on public.work_schedules
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin()));
drop policy if exists "work_schedules_write_admin" on public.work_schedules;
create policy "work_schedules_write_admin" on public.work_schedules
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

-- ============================================================================
-- bookings (mutaciones solo vía RPC security definer, ver parte 2/2)
-- ============================================================================
drop policy if exists "bookings_select" on public.bookings;
create policy "bookings_select" on public.bookings
  for select to authenticated
  using (tenant_id = public.current_tenant_id()
    and (client_id = auth.uid() or employee_id = auth.uid() or public.is_admin_or_sysadmin()));

drop policy if exists "bookings_update_admin" on public.bookings;
create policy "bookings_update_admin" on public.bookings
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

-- ============================================================================
-- booking_extra_services
-- ============================================================================
drop policy if exists "booking_extra_services_select" on public.booking_extra_services;
create policy "booking_extra_services_select" on public.booking_extra_services
  for select to authenticated using (
    tenant_id = public.current_tenant_id()
    and exists (
      select 1 from public.bookings b
      where b.id = booking_extra_services.booking_id
        and (b.client_id = auth.uid() or b.employee_id = auth.uid() or public.is_admin_or_sysadmin())
    )
  );

-- ============================================================================
-- reviews (catálogo público de lectura)
-- ============================================================================
drop policy if exists "reviews_select_public" on public.reviews;
create policy "reviews_select_public" on public.reviews
  for select to anon, authenticated using (tenant_id = public.effective_tenant_id());
drop policy if exists "reviews_insert_own" on public.reviews;
create policy "reviews_insert_own" on public.reviews
  for insert to authenticated with check (
    tenant_id = public.current_tenant_id()
    and client_id = auth.uid()
    and exists (select 1 from public.bookings b where b.id = booking_id and b.client_id = auth.uid()
                and b.tenant_id = public.current_tenant_id())
  );

-- ============================================================================
-- products (catálogo público)
-- ============================================================================
drop policy if exists "products_select_public" on public.products;
create policy "products_select_public" on public.products
  for select to anon, authenticated using (tenant_id = public.effective_tenant_id());
drop policy if exists "products_write_admin" on public.products;
create policy "products_write_admin" on public.products
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());
drop policy if exists "products_update_category_sysadmin" on public.products;
create policy "products_update_category_sysadmin" on public.products
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

-- ============================================================================
-- saved_products
-- ============================================================================
drop policy if exists "saved_products_own" on public.saved_products;
create policy "saved_products_own" on public.saved_products
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and user_id = auth.uid())
  with check (tenant_id = public.current_tenant_id() and user_id = auth.uid());

-- ============================================================================
-- orders / order_items (inserts solo vía crear_pedido(), ver parte 2/2)
-- ============================================================================
drop policy if exists "orders_select_own_or_admin" on public.orders;
create policy "orders_select_own_or_admin" on public.orders
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (client_id = auth.uid() or public.is_admin_or_sysadmin()));
drop policy if exists "orders_update_admin" on public.orders;
create policy "orders_update_admin" on public.orders
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

drop policy if exists "order_items_select" on public.order_items;
create policy "order_items_select" on public.order_items
  for select to authenticated using (
    tenant_id = public.current_tenant_id()
    and exists (select 1 from public.orders o where o.id = order_items.order_id
                and (o.client_id = auth.uid() or public.is_admin_or_sysadmin()))
  );

-- ============================================================================
-- supplies / supply_purchases (solo admin)
-- ============================================================================
drop policy if exists "supplies_all_admin" on public.supplies;
create policy "supplies_all_admin" on public.supplies
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

drop policy if exists "supply_purchases_all_admin" on public.supply_purchases;
create policy "supply_purchases_all_admin" on public.supply_purchases
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

-- ============================================================================
-- app_config (catálogo público, 1 fila por tenant)
-- ============================================================================
drop policy if exists "app_config_select_public" on public.app_config;
create policy "app_config_select_public" on public.app_config
  for select to anon, authenticated using (tenant_id = public.effective_tenant_id());
drop policy if exists "app_config_write_admin" on public.app_config;
create policy "app_config_write_admin" on public.app_config
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

-- ============================================================================
-- commission_configs / commission_settings (solo admin, 1 fila de settings
-- por tenant)
-- ============================================================================
drop policy if exists "commission_configs_all_admin" on public.commission_configs;
create policy "commission_configs_all_admin" on public.commission_configs
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

drop policy if exists "commission_settings_all_admin" on public.commission_settings;
create policy "commission_settings_all_admin" on public.commission_settings
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

-- ============================================================================
-- commission_cuts / commission_entries (inserts solo vía RPC, ver 2/2)
-- ============================================================================
drop policy if exists "commission_cuts_select" on public.commission_cuts;
create policy "commission_cuts_select" on public.commission_cuts
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin()));
drop policy if exists "commission_cuts_update_admin" on public.commission_cuts;
create policy "commission_cuts_update_admin" on public.commission_cuts
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin());

drop policy if exists "commission_entries_select" on public.commission_entries;
create policy "commission_entries_select" on public.commission_entries
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin()));

-- ============================================================================
-- session_logs / activity_logs
-- ============================================================================
drop policy if exists "session_logs_select" on public.session_logs;
create policy "session_logs_select" on public.session_logs
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (profile_id = auth.uid() or public.is_sysadmin()));
drop policy if exists "session_logs_insert_self" on public.session_logs;
create policy "session_logs_insert_self" on public.session_logs
  for insert to authenticated
  with check (tenant_id = public.current_tenant_id() and profile_id = auth.uid());
drop policy if exists "session_logs_update" on public.session_logs;
create policy "session_logs_update" on public.session_logs
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and (profile_id = auth.uid() or public.is_sysadmin()))
  with check (tenant_id = public.current_tenant_id() and (profile_id = auth.uid() or public.is_sysadmin()));
drop policy if exists "session_logs_delete_sysadmin" on public.session_logs;
create policy "session_logs_delete_sysadmin" on public.session_logs
  for delete to authenticated using (tenant_id = public.current_tenant_id() and public.is_sysadmin());

drop policy if exists "activity_logs_select_sysadmin" on public.activity_logs;
create policy "activity_logs_select_sysadmin" on public.activity_logs
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (profile_id = auth.uid() or public.is_sysadmin()));
drop policy if exists "activity_logs_insert_self" on public.activity_logs;
create policy "activity_logs_insert_self" on public.activity_logs
  for insert to authenticated
  with check (tenant_id = public.current_tenant_id() and profile_id = auth.uid());
drop policy if exists "activity_logs_delete_sysadmin" on public.activity_logs;
create policy "activity_logs_delete_sysadmin" on public.activity_logs
  for delete to authenticated using (tenant_id = public.current_tenant_id() and public.is_sysadmin());

-- ============================================================================
-- employee_time_off — se corrige de paso que aplicaba a PUBLIC (sin "to
-- authenticated"), no solo se le agrega tenant_id.
-- ============================================================================
drop policy if exists "employee_time_off_select" on public.employee_time_off;
create policy "employee_time_off_select" on public.employee_time_off
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin_or_sysadmin()));
drop policy if exists "employee_time_off_insert" on public.employee_time_off;
create policy "employee_time_off_insert" on public.employee_time_off
  for insert to authenticated
  with check (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin_or_sysadmin()));
drop policy if exists "employee_time_off_delete" on public.employee_time_off;
create policy "employee_time_off_delete" on public.employee_time_off
  for delete to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin_or_sysadmin()));

-- ============================================================================
-- notifications — mismo fix de scoping (PUBLIC -> authenticated) de paso.
-- Inserts solo vía triggers SECURITY DEFINER (ver parte 2/2).
-- ============================================================================
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own" on public.notifications
  for select to authenticated using (tenant_id = public.current_tenant_id() and user_id = auth.uid());
drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own" on public.notifications
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and user_id = auth.uid())
  with check (tenant_id = public.current_tenant_id() and user_id = auth.uid());

-- ============================================================================
-- product_categories — mismo fix de scoping (PUBLIC -> anon,authenticated
-- explícito) de paso.
-- ============================================================================
drop policy if exists "product_categories_select_public" on public.product_categories;
create policy "product_categories_select_public" on public.product_categories
  for select to anon, authenticated using (tenant_id = public.effective_tenant_id());
drop policy if exists "product_categories_write_admin" on public.product_categories;
create policy "product_categories_write_admin" on public.product_categories
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

-- ============================================================================
-- loyalty_config (catálogo público, 1 fila por tenant) / loyalty_points
-- ============================================================================
drop policy if exists "loyalty_config_select_public" on public.loyalty_config;
create policy "loyalty_config_select_public" on public.loyalty_config
  for select to anon, authenticated using (tenant_id = public.effective_tenant_id());
drop policy if exists "loyalty_config_write_admin" on public.loyalty_config;
create policy "loyalty_config_write_admin" on public.loyalty_config
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "loyalty_points_select" on public.loyalty_points;
create policy "loyalty_points_select" on public.loyalty_points
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (profile_id = auth.uid() or public.is_admin_or_sysadmin()));

-- ============================================================================
-- email_verification_tokens / password_reset_tokens: siguen SIN policies
-- (deny-by-default para anon/authenticated, solo service_role las toca desde
-- las Edge Functions, que ya bypassean RLS) — nada que cambiar aquí. El
-- filtrado por tenant de esas Edge Functions es un cambio de código aparte
-- (Fase 6), no de SQL.
-- ============================================================================
