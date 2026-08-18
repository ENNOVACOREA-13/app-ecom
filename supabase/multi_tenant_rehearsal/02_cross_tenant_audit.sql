-- Auditoría de integridad cruzada: para cada FK "sensible" (booking->employee,
-- booking->service, order_items->order, etc.), confirmar que ambos lados
-- tienen el MISMO tenant_id. Cualquier fila que salga aquí es un bug real.

select 'bookings.employee_id != profiles.tenant_id' as chequeo, count(*) as filas_malas
from public.bookings b join public.profiles p on p.id = b.employee_id
where b.tenant_id is distinct from p.tenant_id
union all
select 'bookings.service_id != services.tenant_id', count(*)
from public.bookings b join public.services s on s.id = b.service_id
where b.tenant_id is distinct from s.tenant_id
union all
select 'bookings.client_id != profiles.tenant_id', count(*)
from public.bookings b join public.profiles p on p.id = b.client_id
where b.tenant_id is distinct from p.tenant_id
union all
select 'order_items.order_id != orders.tenant_id', count(*)
from public.order_items oi join public.orders o on o.id = oi.order_id
where oi.tenant_id is distinct from o.tenant_id
union all
select 'order_items.product_id != products.tenant_id', count(*)
from public.order_items oi join public.products pr on pr.id = oi.product_id
where oi.tenant_id is distinct from pr.tenant_id
union all
select 'commission_entries.employee_id != profiles.tenant_id', count(*)
from public.commission_entries ce join public.profiles p on p.id = ce.employee_id
where ce.tenant_id is distinct from p.tenant_id
union all
select 'employee_services cross-tenant', count(*)
from public.employee_services es
join public.profiles p on p.id = es.employee_id
join public.services s on s.id = es.service_id
where es.tenant_id is distinct from p.tenant_id or es.tenant_id is distinct from s.tenant_id
union all
select 'reviews.booking_id != bookings.tenant_id', count(*)
from public.reviews r join public.bookings b on b.id = r.booking_id
where r.tenant_id is distinct from b.tenant_id;
