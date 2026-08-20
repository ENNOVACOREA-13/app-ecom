-- Auditoría sistemática pedida por el usuario tras encontrar el mismo bug
-- de commission_configs (is_admin() en vez de is_admin_or_sysadmin(),
-- patrón ya documentado en memoria de este proyecto) repetido en OTRAS 10
-- tablas — 12 políticas en total. is_admin() excluye 'sysadmin', así que
-- cualquier cuenta sysadmin quedaba silenciosamente bloqueada de manejar
-- productos, servicios, insumos, pedidos, horarios y comisiones — no una
-- fuga de datos (nunca exponía nada a nadie más), pero sí la misma clase
-- de "guardé pero no pasó nada" que ya se había visto antes.
drop policy if exists "commission_cuts_update_admin" on public.commission_cuts;
create policy "commission_cuts_update_admin" on public.commission_cuts
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "commission_cuts_select" on public.commission_cuts;
create policy "commission_cuts_select" on public.commission_cuts
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin_or_sysadmin()));

drop policy if exists "commission_entries_select" on public.commission_entries;
create policy "commission_entries_select" on public.commission_entries
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin_or_sysadmin()));

drop policy if exists "commission_settings_all_admin" on public.commission_settings;
create policy "commission_settings_all_admin" on public.commission_settings
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "employee_services_write_admin" on public.employee_services;
create policy "employee_services_write_admin" on public.employee_services
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "orders_update_admin" on public.orders;
create policy "orders_update_admin" on public.orders
  for update to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "products_write_admin" on public.products;
create policy "products_write_admin" on public.products
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "services_write_admin" on public.services;
create policy "services_write_admin" on public.services
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "supplies_all_admin" on public.supplies;
create policy "supplies_all_admin" on public.supplies
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "supply_purchases_all_admin" on public.supply_purchases;
create policy "supply_purchases_all_admin" on public.supply_purchases
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "work_schedules_write_admin" on public.work_schedules;
create policy "work_schedules_write_admin" on public.work_schedules
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());

drop policy if exists "work_schedules_select" on public.work_schedules;
create policy "work_schedules_select" on public.work_schedules
  for select to authenticated
  using (tenant_id = public.current_tenant_id() and (employee_id = auth.uid() or public.is_admin_or_sysadmin()));
