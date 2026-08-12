-- El sysadmin monitorea toda la app (incluso al admin), pero las políticas de
-- orders/order_items solo permitían lectura a is_admin(), dejando a sysadmin
-- sin ver pedidos de tienda → "Ingresos totales del sistema" salía incompleto.

drop policy if exists "orders_select_own_or_admin" on public.orders;
create policy "orders_select_own_or_admin" on public.orders
  for select to authenticated using (client_id = auth.uid() or public.is_admin_or_sysadmin());

drop policy if exists "order_items_select" on public.order_items;
create policy "order_items_select" on public.order_items
  for select to authenticated using (
    exists (select 1 from public.orders o where o.id = order_items.order_id
            and (o.client_id = auth.uid() or public.is_admin_or_sysadmin()))
  );
