-- actualizarEstado() (order_repository.dart) restauraba el stock al
-- cancelar un pedido haciendo, desde el cliente: select stock -> update
-- stock = stockLeido + cantidad, en un loop por cada producto del pedido.
-- Eso es un "lost update": si dos pedidos que comparten un producto se
-- cancelan casi al mismo tiempo, ambos pueden leer el mismo stock viejo y
-- la segunda escritura pisa a la primera, perdiendo unidades restauradas.
--
-- Se mueve todo (cambiar estado + restaurar stock si aplica) a un solo RPC
-- atómico del lado del servidor: el UPDATE con "stock = stock + cantidad"
-- se evalúa contra el valor real de la fila bajo lock, así que no hay
-- forma de perder una restitución aunque se cancelen pedidos en paralelo.

create or replace function public.actualizar_estado_pedido(
  p_order_id uuid,
  p_status text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_estado_actual text;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select status into v_estado_actual from public.orders where id = p_order_id;
  if v_estado_actual is null then
    raise exception 'NOT_FOUND';
  end if;

  update public.orders
  set status = p_status, updated_at = now()
  where id = p_order_id;

  -- Restaurar stock solo si se cancela y no estaba ya cancelado.
  if p_status = 'cancelled' and v_estado_actual is distinct from 'cancelled' then
    update public.products p
    set stock = p.stock + oi.quantity
    from public.order_items oi
    where oi.order_id = p_order_id and oi.product_id = p.id;
  end if;
end;
$$;
grant execute on function public.actualizar_estado_pedido(uuid, text) to authenticated;
