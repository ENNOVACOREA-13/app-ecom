-- ============================================================================
-- Crea los 3 usuarios iniciales directamente en auth.users (+ profiles vía el
-- trigger on_auth_user_created que ya quedó instalado en la migración anterior)
--
-- Pégalo y ejecútalo UNA vez en el SQL Editor de Supabase, DESPUÉS de haber
-- corrido 20260807120000_rebuild_schema.sql.
--
-- Usuarios creados (contraseña igual para los 3: PRETTYCORE13):
--   juremaguilar@icloud.com    -> role: client   (usuario)
--   ennovajesus@gmail.com      -> role: employee (empleado)
--   sysadmin@prettycore.xyz    -> role: sysadmin (panel de administración total)
--
-- Nota: el email "sysadmin@prettycore.xyz" sugiere que ese es el rol
-- 'sysadmin' (acceso al panel SysAdmin). Si en realidad querías 'admin' o
-- 'super_admin' en su lugar, corre después:
--   update public.profiles set role = 'admin' where email = 'sysadmin@prettycore.xyz';
-- ============================================================================

create extension if not exists pgcrypto;

do $$
declare
  v_instance_id uuid := '00000000-0000-0000-0000-000000000000';
  v_password    text := 'PRETTYCORE13';
  v_user_id     uuid;
  v_row         record;
begin
  for v_row in
    select * from (values
      ('juremaguilar@icloud.com', 'Cliente',   'client'),
      ('ennovajesus@gmail.com',   'Empleado',  'employee'),
      ('sysadmin@prettycore.xyz','Administrador', 'sysadmin')
    ) as t(email, full_name, role)
  loop
    if exists (select 1 from auth.users where email = v_row.email) then
      raise notice 'Ya existe %, se omite.', v_row.email;
      continue;
    end if;

    v_user_id := gen_random_uuid();

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token,
      email_change, email_change_token_new, email_change_token_current,
      phone_change, phone_change_token, reauthentication_token
    ) values (
      v_instance_id, v_user_id, 'authenticated', 'authenticated',
      v_row.email, crypt(v_password, gen_salt('bf')),
      now(), now(),
      jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
      jsonb_build_object('full_name', v_row.full_name, 'role', v_row.role),
      now(), now(),
      '', '', '', '', '', '', '', ''
    );

    insert into auth.identities (
      id, provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_user_id::text, v_user_id,
      jsonb_build_object('sub', v_user_id::text, 'email', v_row.email,
                          'email_verified', true, 'phone_verified', false),
      'email', now(), now(), now()
    );

    raise notice 'Creado % con role %', v_row.email, v_row.role;
  end loop;
end $$;

-- Verificación rápida
select p.email, p.role, p.full_name, p.is_active
from public.profiles p
where p.email in ('juremaguilar@icloud.com','ennovajesus@gmail.com','sysadmin@prettycore.xyz');
