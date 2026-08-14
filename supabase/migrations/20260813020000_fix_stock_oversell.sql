-- crear_pedido descontaba stock con:
--   update products set stock = greatest(stock - cantidad, 0) where id = ...
-- Eso nunca falla: si piden más unidades de las que hay, igual crea el
-- pedido y el stock simplemente se queda en 0 (venta fantasma / oversell).
-- La app sí valida en el cliente (producto/tienda/carrito), pero eso no
-- protege contra dos compradores concurrentes agotando el mismo último
-- stock, ni contra un cliente que llame la función directo sin pasar por
-- la UI. El UPDATE condicional de abajo es atómico: solo descuenta si en
-- ese instante alcanza el stock (Postgres bloquea la fila del producto
-- durante la transacción, así que dos compras concurrentes del último
-- artículo se resuelven una a la vez, no ambas a la vez).

create or replace function public.crear_pedido(
  p_items jsonb,
  p_notes text default null,
  p_payment_method text default 'cash',
  p_payment_status text default 'pending',
  p_stripe_payment_id text default null
)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_client_id uuid := auth.uid();
  v_order_id uuid;
  v_total numeric := 0;
  v_item jsonb;
  v_product_id uuid;
  v_cantidad int;
  v_nombre text;
  v_precio numeric;
  v_precio_oferta numeric;
  v_precio_efectivo numeric;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_CART';
  end if;

  insert into public.orders (client_id, total, payment_method, payment_status, stripe_payment_id, notes)
  values (v_client_id, 0, p_payment_method, p_payment_status, p_stripe_payment_id, p_notes)
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := (v_item->>'product_id')::uuid;
    v_cantidad := (v_item->>'cantidad')::int;
    if v_cantidad is null or v_cantidad <= 0 then
      raise exception 'INVALID_QUANTITY';
    end if;

    select name, price, sale_price into v_nombre, v_precio, v_precio_oferta
    from public.products where id = v_product_id;
    if v_nombre is null then
      raise exception 'PRODUCT_NOT_FOUND';
    end if;

    v_precio_efectivo := coalesce(v_precio_oferta, v_precio);
    v_total := v_total + (v_precio_efectivo * v_cantidad);

    insert into public.order_items (order_id, product_id, product_name, quantity, unit_price)
    values (v_order_id, v_product_id, v_nombre, v_cantidad, v_precio_efectivo);

    -- Descuento atómico: solo aplica si en este instante hay stock suficiente.
    update public.products
    set stock = stock - v_cantidad
    where id = v_product_id and stock >= v_cantidad;

    if not found then
      raise exception 'INSUFFICIENT_STOCK: %', v_nombre;
    end if;
  end loop;

  update public.orders set total = v_total where id = v_order_id;

  return v_order_id;
end;
$$;
