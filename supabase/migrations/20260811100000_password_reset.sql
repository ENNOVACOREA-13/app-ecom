-- "Olvidé mi contraseña": mismo patrón que la verificación de correo —
-- token propio + envío por el SMTP de Hostinger vía Edge Function.

create table if not exists public.password_reset_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  token       text not null unique,
  expires_at  timestamptz not null,
  used        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists idx_password_reset_tokens_token
  on public.password_reset_tokens(token);

-- Sin políticas: esta tabla solo la toca la service_role desde las Edge Functions.
alter table public.password_reset_tokens enable row level security;

-- Permite a las Edge Functions (service_role) encontrar el user_id de un correo
-- sin exponer auth.users vía la API REST pública.
create or replace function public.get_user_id_by_email(p_email text)
returns uuid
language sql security definer set search_path = public, auth as $$
  select id from auth.users where lower(email) = lower(p_email) limit 1;
$$;

revoke all on function public.get_user_id_by_email(text) from public, anon, authenticated;
grant execute on function public.get_user_id_by_email(text) to service_role;
