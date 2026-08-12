-- ============================================================================
-- Crea la cuenta con role 'admin' (panel de negocio: dashboard/reservas/
-- pedidos/insumos/config), distinta del panel 'sysadmin'.
--
-- admin@gmail.com / PRETTYCORE13
--
-- Corre esto en el SQL Editor de Supabase (después de las migraciones
-- anteriores, no importa el orden respecto a demo_data.sql).
-- ============================================================================

create extension if not exists pgcrypto;

do $$
declare
  v_instance_id uuid := '00000000-0000-0000-0000-000000000000';
  v_password    text := 'PRETTYCORE13';
  v_email       text := 'admin@gmail.com';
  v_user_id     uuid;
begin
  if exists (select 1 from auth.users where email = v_email) then
    raise notice 'Ya existe %, no se creó de nuevo.', v_email;
    return;
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
    v_email, crypt(v_password, gen_salt('bf')),
    now(), now(),
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('full_name', 'Administrador Negocio', 'role', 'admin'),
    now(), now(),
    '', '', '', '', '', '', '', ''
  );

  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), v_user_id::text, v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', v_email,
                        'email_verified', true, 'phone_verified', false),
    'email', now(), now(), now()
  );

  raise notice 'Creado % con role admin', v_email;
end $$;

select email, role, full_name from public.profiles where email = 'admin@gmail.com';
