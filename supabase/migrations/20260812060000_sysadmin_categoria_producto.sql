-- ── Permite a sysadmin asignar categoría a productos (solo category_id) ───
-- La política products_write_admin sólo permitía escribir en products a
-- is_admin(), que excluye a sysadmin. Por eso al asignar productos desde
-- "Categorías" (pantalla de sysadmin) el UPDATE se filtraba en silencio por
-- RLS (0 filas afectadas, sin error) y la app mostraba "guardado" sin haber
-- cambiado nada. Se agrega una política de UPDATE para sysadmin, restringida
-- por trigger a la columna category_id únicamente.

create policy "products_update_category_sysadmin" on public.products
  for update to authenticated
  using (public.is_admin_or_sysadmin())
  with check (public.is_admin_or_sysadmin());

create or replace function public.restringir_actualizacion_producto_sysadmin()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.is_admin() then
    return new;
  end if;

  if new.name is distinct from old.name
     or new.description is distinct from old.description
     or new.price is distinct from old.price
     or new.sale_price is distinct from old.sale_price
     or new.stock is distinct from old.stock
     or new.image_url is distinct from old.image_url
     or new.status is distinct from old.status
     or new.created_by is distinct from old.created_by then
    raise exception 'SYSADMIN_SOLO_PUEDE_EDITAR_CATEGORIA';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_restringir_producto_sysadmin on public.products;
create trigger trg_restringir_producto_sysadmin
  before update on public.products
  for each row execute function public.restringir_actualizacion_producto_sysadmin();
