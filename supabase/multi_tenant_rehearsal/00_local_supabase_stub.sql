create schema if not exists auth;
create table if not exists auth.users (id uuid primary key default gen_random_uuid(), email text, raw_user_meta_data jsonb not null default '{}'::jsonb);
-- En Supabase real, auth.uid() lee el JWT de la sesion PostgREST
-- (request.jwt.claims). Lo simulamos igual, vía una GUC seteable con
-- select set_config('request.jwt.claims', '{"sub":"<uuid>"}', true);
-- por transaccion, para poder probar "como si fuera este usuario logueado".
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claims', true)::json->>'sub', '')::uuid;
$$;
create schema if not exists storage;
create table if not exists storage.buckets (id text primary key, name text not null, public boolean not null default false);
create table if not exists storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets(id), name text);
create or replace function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name, '/'); $$;
create extension if not exists pgcrypto;
