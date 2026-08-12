-- Verificación de correo propia (SMTP de Hostinger vía Edge Function),
-- reemplaza el mailer nativo de Supabase para el flujo de registro.

alter table public.profiles
  add column if not exists email_verificado boolean not null default false;

-- Cuentas ya existentes no deben quedar bloqueadas por el nuevo requisito.
update public.profiles set email_verificado = true;

create table if not exists public.email_verification_tokens (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  token       text not null unique,
  expires_at  timestamptz not null,
  used        boolean not null default false,
  created_at  timestamptz not null default now()
);
create index if not exists idx_email_verification_tokens_token
  on public.email_verification_tokens(token);

-- Sin políticas: esta tabla solo la toca la service_role desde las Edge Functions.
alter table public.email_verification_tokens enable row level security;
