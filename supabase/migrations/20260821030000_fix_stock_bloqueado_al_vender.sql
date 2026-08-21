-- restringir_actualizacion_producto_sysadmin() bloqueaba CUALQUIER cambio
-- a products.stock hecho por alguien que no fuera admin/super_admin —
-- incluyendo el descuento automático de stock que hace crear_pedido()
-- cuando un CLIENTE compra un producto (la función es SECURITY DEFINER,
-- pero los triggers ven al llamador real, no al dueño de la función: un
-- cliente nunca es admin, así que el trigger tumbaba la compra misma con
-- SYSADMIN_SOLO_PUEDE_EDITAR_CATEGORIA). Bug real 2026-08-21: "no deja
-- meter pedidos".
--
-- stock no debería estar protegido aquí en absoluto: RLS ya bloquea
-- cualquier UPDATE directo a products a quien no sea admin/sysadmin
-- (products_write_admin, products_update_category_sysadmin), así que la
-- única forma de que un cliente toque esta fila es a través de funciones
-- SECURITY DEFINER ya validadas (crear_pedido, actualizar_estado_pedido).
-- El resto de campos (nombre, precio, descripción, etc.) siguen
-- protegidos igual que antes — esa restricción es a propósito.
create or replace function public.restringir_actualizacion_producto_sysadmin()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if public.is_admin() then
    return new;
  end if;

  if new.name is distinct from old.name
     or new.description is distinct from old.description
     or new.price is distinct from old.price
     or new.sale_price is distinct from old.sale_price
     or new.image_url is distinct from old.image_url
     or new.status is distinct from old.status
     or new.created_by is distinct from old.created_by then
    raise exception 'SYSADMIN_SOLO_PUEDE_EDITAR_CATEGORIA';
  end if;

  return new;
end;
$$;
