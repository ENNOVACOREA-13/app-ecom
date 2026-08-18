create schema if not exists auth;
create table if not exists auth.users (id uuid primary key default gen_random_uuid(), email text, raw_user_meta_data jsonb not null default '{}'::jsonb);
-- En Supabase real, auth.uid() lee el JWT de la sesion PostgREST
-- (request.jwt.claims). Lo simulamos igual, vía una GUC seteable con
-- select set_config('request.jwt.claims', '{"sub":"<uuid>"}', true|false);
-- (true = solo esta transaccion, false = toda la sesion) para poder probar
-- "como si fuera este usuario logueado".
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid;
$$;

-- Columnas/tablas extra de auth.* que trae un pg_dump real de Supabase
-- (necesarias solo para el ensayo de Fase 5 con datos reales — el stub
-- mínimo de arriba basta para las Fases 2-4).
alter table auth.users
  add column if not exists instance_id uuid,
  add column if not exists aud text,
  add column if not exists role text,
  add column if not exists encrypted_password text,
  add column if not exists email_confirmed_at timestamptz,
  add column if not exists invited_at timestamptz,
  add column if not exists confirmation_token text,
  add column if not exists confirmation_sent_at timestamptz,
  add column if not exists recovery_token text,
  add column if not exists recovery_sent_at timestamptz,
  add column if not exists email_change_token_new text,
  add column if not exists email_change text,
  add column if not exists email_change_sent_at timestamptz,
  add column if not exists last_sign_in_at timestamptz,
  add column if not exists raw_app_meta_data jsonb,
  add column if not exists is_super_admin boolean,
  add column if not exists created_at timestamptz,
  add column if not exists updated_at timestamptz,
  add column if not exists phone text,
  add column if not exists phone_confirmed_at timestamptz,
  add column if not exists phone_change text,
  add column if not exists phone_change_token text,
  add column if not exists phone_change_sent_at timestamptz,
  add column if not exists email_change_token_current text,
  add column if not exists email_change_confirm_status smallint,
  add column if not exists banned_until timestamptz,
  add column if not exists reauthentication_token text,
  add column if not exists reauthentication_sent_at timestamptz,
  add column if not exists is_sso_user boolean not null default false,
  add column if not exists deleted_at timestamptz,
  add column if not exists is_anonymous boolean not null default false;

create table if not exists auth.audit_log_entries (
  instance_id uuid, id uuid primary key, payload jsonb, created_at timestamptz, ip_address text
);
create table if not exists auth.identities (
  provider_id text, user_id uuid, identity_data jsonb, provider text,
  last_sign_in_at timestamptz, created_at timestamptz, updated_at timestamptz, id uuid primary key
);
create table if not exists auth.sessions (
  id uuid primary key, user_id uuid, created_at timestamptz, updated_at timestamptz,
  factor_id uuid, aal text, not_after timestamptz, refreshed_at timestamptz,
  user_agent text, ip text, tag text, oauth_client_id uuid,
  refresh_token_hmac_key text, refresh_token_counter bigint, scopes text
);
create table if not exists auth.mfa_amr_claims (
  session_id uuid, created_at timestamptz, updated_at timestamptz,
  authentication_method text, id uuid primary key
);
create table if not exists auth.refresh_tokens (
  instance_id uuid, id bigserial primary key, token text, user_id uuid,
  revoked boolean, created_at timestamptz, updated_at timestamptz,
  parent text, session_id uuid
);
create schema if not exists storage;
create table if not exists storage.buckets (id text primary key, name text not null, public boolean not null default false);
create table if not exists storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets(id), name text);
create or replace function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name, '/'); $$;
create extension if not exists pgcrypto;
