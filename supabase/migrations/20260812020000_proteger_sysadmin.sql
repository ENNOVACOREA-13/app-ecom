-- ── Proteger cuentas sysadmin y auto-desactivación accidental ─────────────
-- La pantalla de Configuración de sysadmin lista TODOS los usuarios (incluida
-- la propia cuenta sysadmin) con un switch de activar/desactivar sin ningún
-- resguardo. Esto permitió desactivar por accidente la propia cuenta sysadmin,
-- dejando al usuario sin poder iniciar sesión. Se agrega un resguardo a nivel
-- de base de datos (imposible de saltar desde la UI o la API):
--   1. Nunca se puede desactivar una cuenta con role = 'sysadmin'.
--   2. Nadie puede desactivar su propia cuenta (auth.uid() = id).
--   3. Nunca se puede eliminar una cuenta con role = 'sysadmin'.

create or replace function public.bloquear_desactivacion_critica()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.is_active = false and old.is_active = true then
    if old.role = 'sysadmin' then
      raise exception 'No se puede desactivar una cuenta sysadmin';
    end if;
    if old.id = auth.uid() then
      raise exception 'No puedes desactivar tu propia cuenta';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_bloquear_desactivacion_critica on public.profiles;
create trigger trg_bloquear_desactivacion_critica
  before update on public.profiles
  for each row execute function public.bloquear_desactivacion_critica();

create or replace function public.bloquear_eliminacion_sysadmin()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.role = 'sysadmin' then
    raise exception 'No se puede eliminar una cuenta sysadmin';
  end if;
  return old;
end;
$$;

drop trigger if exists trg_bloquear_eliminacion_sysadmin on public.profiles;
create trigger trg_bloquear_eliminacion_sysadmin
  before delete on public.profiles
  for each row execute function public.bloquear_eliminacion_sysadmin();
