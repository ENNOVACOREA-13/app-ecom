-- ============================================================================
-- BarberApp — Reconstrucción completa de la base de datos
-- Generado a partir de una lectura exhaustiva del código Flutter (lib/data,
-- lib/domain/models, lib/ui) para que el esquema concuerde exactamente con
-- las tablas, columnas, vistas, funciones RPC y buckets que la app espera.
--
-- Cómo aplicarlo:
--   1. Abre el SQL Editor de tu proyecto Supabase (debe ser un proyecto NUEVO
--      o una base vacía — el script no borra nada existente, pero asume que
--      no hay conflictos de nombres).
--   2. Pega TODO este archivo y ejecútalo de una sola vez.
--   3. Revisa la sección final "NOTAS" para los pasos manuales que quedan
--      fuera del alcance de SQL (Storage buckets ya se crean aquí, pero las
--      claves de Stripe y los providers de OAuth se configuran en el panel).
-- ============================================================================

-- ── Extensiones ──────────────────────────────────────────────────────────
create extension if not exists pgcrypto;

-- ============================================================================
-- 1. TABLAS
-- ============================================================================

-- ── profiles ─────────────────────────────────────────────────────────────
-- Extiende auth.users. role controla todo el acceso en la app.
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text,
  role         text not null default 'client'
               check (role in ('client','employee','admin','super_admin','sysadmin')),
  full_name    text not null default '',
  phone        text,
  avatar_url   text,
  bio          text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now()
);

-- ── services ─────────────────────────────────────────────────────────────
create table if not exists public.services (
  id            uuid primary key default gen_random_uuid(),
  name          text not null,
  description   text,
  duration_min  int not null default 30,
  price         numeric(10,2) not null default 0,
  image_url     text,
  is_active     boolean not null default true,
  created_at    timestamptz not null default now()
);

-- ── employee_services (qué empleado hace qué servicio) ──────────────────
create table if not exists public.employee_services (
  employee_id  uuid not null references public.profiles(id) on delete cascade,
  service_id   uuid not null references public.services(id) on delete cascade,
  primary key (employee_id, service_id)
);

-- ── work_schedules (horario semanal por empleado) ────────────────────────
create table if not exists public.work_schedules (
  id           uuid primary key default gen_random_uuid(),
  employee_id  uuid not null references public.profiles(id) on delete cascade,
  day_of_week  text not null check (day_of_week in
               ('monday','tuesday','wednesday','thursday','friday','saturday','sunday')),
  start_time   time not null,
  end_time     time not null,
  is_active    boolean not null default true,
  unique (employee_id, day_of_week)
);

-- ── bookings (reservas / citas) ───────────────────────────────────────────
create table if not exists public.bookings (
  id             uuid primary key default gen_random_uuid(),
  client_id      uuid not null references public.profiles(id) on delete restrict,
  employee_id    uuid not null references public.profiles(id) on delete restrict,
  service_id     uuid not null references public.services(id) on delete restrict,
  booking_date   date not null,
  start_time     time not null,
  end_time       time not null,
  status         text not null default 'pending'
                 check (status in ('pending','confirmed','completed','cancelled')),
  total_price    numeric(10,2) not null default 0,
  notes          text,
  cancel_reason  text,
  created_at     timestamptz not null default now()
);
create index if not exists idx_bookings_employee_date on public.bookings(employee_id, booking_date);
create index if not exists idx_bookings_client on public.bookings(client_id);

-- ── booking_extra_services (servicios extra agregados a una reserva) ─────
create table if not exists public.booking_extra_services (
  booking_id  uuid not null references public.bookings(id) on delete cascade,
  service_id  uuid not null references public.services(id) on delete restrict,
  primary key (booking_id, service_id)
);

-- ── reviews (reseñas de clientes a empleados) ─────────────────────────────
create table if not exists public.reviews (
  id           uuid primary key default gen_random_uuid(),
  booking_id   uuid not null references public.bookings(id) on delete cascade,
  client_id    uuid not null references public.profiles(id) on delete cascade,
  employee_id  uuid not null references public.profiles(id) on delete cascade,
  rating       int not null check (rating between 1 and 5),
  comment      text,
  created_at   timestamptz not null default now(),
  unique (booking_id)
);

-- ── products (tienda) ─────────────────────────────────────────────────────
create table if not exists public.products (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  description  text,
  price        numeric(10,2) not null default 0,
  sale_price   numeric(10,2),
  stock        int not null default 0,
  image_url    text,
  status       text not null default 'active'
               check (status in ('active','inactive','out_of_stock')),
  created_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now()
);
create index if not exists idx_products_status on public.products(status);

-- ── saved_products (favoritos) ────────────────────────────────────────────
create table if not exists public.saved_products (
  user_id     uuid not null references public.profiles(id) on delete cascade,
  product_id  uuid not null references public.products(id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (user_id, product_id)
);

-- ── orders / order_items (pedidos de tienda) ──────────────────────────────
create table if not exists public.orders (
  id                 uuid primary key default gen_random_uuid(),
  client_id          uuid not null references public.profiles(id) on delete restrict,
  total              numeric(10,2) not null default 0,
  status             text not null default 'pending'
                     check (status in ('pending','confirmed','ready','delivered','cancelled')),
  payment_method     text not null default 'cash'
                     check (payment_method in ('cash','card','transfer')),
  payment_status     text not null default 'pending'
                     check (payment_status in ('pending','paid')),
  stripe_payment_id  text,
  notes              text,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz
);
create index if not exists idx_orders_client on public.orders(client_id);

create table if not exists public.order_items (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references public.orders(id) on delete cascade,
  product_id     uuid references public.products(id) on delete set null,
  product_name   text not null,
  quantity       int not null,
  unit_price     numeric(10,2) not null
);
create index if not exists idx_order_items_order on public.order_items(order_id);

-- ── supplies (insumos internos) ───────────────────────────────────────────
create table if not exists public.supplies (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  description  text,
  price        numeric(10,2) not null default 0,
  stock        int not null default 0,
  unit         text not null default 'unidad',
  status       text not null default 'active',
  created_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now()
);

-- ── app_config (fila única: color de la app) ──────────────────────────────
create table if not exists public.app_config (
  id             boolean primary key default true,
  primary_color  text,
  updated_at     timestamptz default now(),
  constraint app_config_singleton check (id)
);

-- ── commission_configs (comisión fija por servicio) ───────────────────────
create table if not exists public.commission_configs (
  id           uuid primary key default gen_random_uuid(),
  service_id   uuid not null unique references public.services(id) on delete cascade,
  amount       numeric(10,2) not null default 0,
  updated_at   timestamptz not null default now()
);

-- ── commission_settings (fila única: día/hora de corte semanal) ──────────
create table if not exists public.commission_settings (
  id             uuid primary key default gen_random_uuid(),
  cutoff_day     int not null default 0,   -- 0=Domingo ... 6=Sábado
  cutoff_hour    int not null default 23,
  cutoff_minute  int not null default 59,
  updated_at     timestamptz not null default now()
);

-- ── commission_cuts (corte semanal de comisiones por empleado) ───────────
create table if not exists public.commission_cuts (
  id               uuid primary key default gen_random_uuid(),
  employee_id      uuid not null references public.profiles(id) on delete restrict,
  week_start       date not null,
  week_end         date not null,
  total_amount     numeric(10,2) not null default 0,
  services_count   int not null default 0,
  status           text not null default 'pending' check (status in ('pending','paid')),
  notes            text,
  created_at       timestamptz not null default now()
);
create index if not exists idx_commission_cuts_employee on public.commission_cuts(employee_id);

-- ── commission_entries (comisión ganada por reserva completada) ──────────
create table if not exists public.commission_entries (
  id                 uuid primary key default gen_random_uuid(),
  employee_id        uuid not null references public.profiles(id) on delete restrict,
  booking_id         uuid not null references public.bookings(id) on delete cascade,
  service_id         uuid references public.services(id) on delete set null,
  service_name       text not null default 'Servicio',
  service_price      numeric(10,2) not null default 0,
  commission_amount  numeric(10,2) not null default 0,
  cut_id             uuid references public.commission_cuts(id) on delete set null,
  earned_at          timestamptz not null default now()
);
create index if not exists idx_commission_entries_employee on public.commission_entries(employee_id);
create index if not exists idx_commission_entries_cut on public.commission_entries(cut_id);

-- ── session_logs (sesiones activas por dispositivo, panel sysadmin) ──────
create table if not exists public.session_logs (
  id              uuid primary key default gen_random_uuid(),
  profile_id      uuid not null references public.profiles(id) on delete cascade,
  platform        text,
  device          text,
  is_active       boolean not null default true,
  login_at        timestamptz not null default now(),
  last_active_at  timestamptz,
  logout_at       timestamptz
);
create index if not exists idx_session_logs_profile on public.session_logs(profile_id);

-- ── activity_logs (eventos de uso, panel sysadmin) ────────────────────────
create table if not exists public.activity_logs (
  id           uuid primary key default gen_random_uuid(),
  profile_id   uuid not null references public.profiles(id) on delete cascade,
  session_id   uuid references public.session_logs(id) on delete cascade,
  event_type   text not null check (event_type in ('screen_view','tap','feature')),
  event_name   text not null,
  extra        jsonb,
  created_at   timestamptz not null default now()
);
create index if not exists idx_activity_logs_profile on public.activity_logs(profile_id);
create index if not exists idx_activity_logs_session on public.activity_logs(session_id);

-- ============================================================================
-- 2. FUNCIONES AUXILIARES (SECURITY DEFINER para evitar recursión en RLS)
-- ============================================================================

create or replace function public.my_profile_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role from public.profiles where id = auth.uid()) in ('admin','super_admin'), false);
$$;

create or replace function public.is_sysadmin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role from public.profiles where id = auth.uid()) = 'sysadmin', false);
$$;

create or replace function public.is_admin_or_sysadmin()
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select role from public.profiles where id = auth.uid()) in ('admin','super_admin','sysadmin'), false);
$$;

-- ============================================================================
-- 3. TRIGGER: crear profile automáticamente al registrar un usuario
-- ============================================================================

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, full_name, role, is_active)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    coalesce(new.raw_user_meta_data->>'role', 'client'),
    true
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- 4. VISTAS
-- ============================================================================

create or replace view public.bookings_detailed
with (security_invoker = true) as
select
  b.id, b.client_id, b.employee_id, b.service_id,
  b.booking_date, b.start_time, b.end_time,
  b.status, b.total_price, b.notes, b.cancel_reason, b.created_at,
  c.full_name  as client_name,
  e.full_name  as employee_name,
  s.name       as service_name,
  s.duration_min
from public.bookings b
join public.profiles c on c.id = b.client_id
join public.profiles e on e.id = b.employee_id
join public.services s on s.id = b.service_id;

create or replace view public.employee_stats
with (security_invoker = true) as
select
  p.id as employee_id,
  p.full_name,
  count(*) filter (where b.status = 'completed')                              as total_completadas,
  count(*) filter (where b.status = 'pending')                                as total_pendientes,
  count(*) filter (where b.status = 'cancelled')                              as total_canceladas,
  coalesce(sum(b.total_price) filter (where b.status = 'completed'), 0)       as ingresos_totales,
  (select round(avg(r.rating)::numeric, 1) from public.reviews r where r.employee_id = p.id) as rating_promedio,
  (select count(*) from public.reviews r where r.employee_id = p.id)          as total_reviews
from public.profiles p
left join public.bookings b on b.employee_id = p.id
where p.role = 'employee'
group by p.id, p.full_name;

create or replace view public.popular_services
with (security_invoker = true) as
select
  s.id as service_id,
  s.name,
  count(b.id) filter (where b.status <> 'cancelled') as veces_reservado
from public.services s
left join public.bookings b on b.service_id = s.id
group by s.id, s.name
order by veces_reservado desc;

-- ============================================================================
-- 5. FUNCIONES RPC usadas por la app (SECURITY DEFINER, ver comentarios Dart)
-- ============================================================================

-- ── get_available_slots ───────────────────────────────────────────────────
create or replace function public.get_available_slots(
  p_employee_id uuid,
  p_date date,
  p_duration_min int
)
returns table(slot_start time, slot_end time)
language plpgsql security definer set search_path = public as $$
declare
  v_dow text;
  v_start time;
  v_end time;
  v_cursor time;
  v_step interval := interval '30 minutes';
begin
  v_dow := case extract(dow from p_date)::int
    when 0 then 'sunday'
    when 1 then 'monday'
    when 2 then 'tuesday'
    when 3 then 'wednesday'
    when 4 then 'thursday'
    when 5 then 'friday'
    when 6 then 'saturday'
  end;

  select start_time, end_time into v_start, v_end
  from public.work_schedules
  where employee_id = p_employee_id and day_of_week = v_dow and is_active = true
  limit 1;

  if v_start is null then
    return;
  end if;

  v_cursor := v_start;
  while v_cursor + (p_duration_min || ' minutes')::interval <= v_end loop
    if (p_date > current_date or v_cursor > current_time) and not exists (
      select 1 from public.bookings b
      where b.employee_id = p_employee_id
        and b.booking_date = p_date
        and b.status in ('pending','confirmed')
        and (v_cursor, v_cursor + (p_duration_min || ' minutes')::interval) overlaps (b.start_time, b.end_time)
    ) then
      slot_start := v_cursor;
      slot_end := v_cursor + (p_duration_min || ' minutes')::interval;
      return next;
    end if;
    v_cursor := v_cursor + v_step;
  end loop;
end;
$$;
grant execute on function public.get_available_slots(uuid, date, int) to authenticated;

-- ── crear_reserva ─────────────────────────────────────────────────────────
create or replace function public.crear_reserva(
  p_employee_id uuid,
  p_service_id uuid,
  p_date date,
  p_start_time time,
  p_total_price numeric,
  p_notes text,
  p_extra_ids uuid[]
)
returns setof public.bookings
language plpgsql security definer set search_path = public as $$
declare
  v_client_id uuid := auth.uid();
  v_duration int;
  v_end_time time;
  v_booking_id uuid;
begin
  if v_client_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select duration_min into v_duration from public.services where id = p_service_id;
  if v_duration is null then
    raise exception 'SERVICE_NOT_FOUND';
  end if;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    select v_duration + coalesce(sum(duration_min), 0) into v_duration
    from public.services where id = any(p_extra_ids);
  end if;

  v_end_time := p_start_time + (v_duration || ' minutes')::interval;

  if exists (
    select 1 from public.bookings b
    where b.employee_id = p_employee_id
      and b.booking_date = p_date
      and b.status in ('pending','confirmed')
      and (p_start_time, v_end_time) overlaps (b.start_time, b.end_time)
  ) then
    raise exception 'BOOKING_CONFLICT';
  end if;

  insert into public.bookings
    (client_id, employee_id, service_id, booking_date, start_time, end_time, total_price, notes)
  values
    (v_client_id, p_employee_id, p_service_id, p_date, p_start_time, v_end_time, p_total_price, p_notes)
  returning id into v_booking_id;

  if p_extra_ids is not null and array_length(p_extra_ids, 1) > 0 then
    insert into public.booking_extra_services (booking_id, service_id)
    select v_booking_id, unnest(p_extra_ids);
  end if;

  return query select * from public.bookings where id = v_booking_id;
end;
$$;
grant execute on function public.crear_reserva(uuid, uuid, date, time, numeric, text, uuid[]) to authenticated;

-- ── cancelar_reserva ──────────────────────────────────────────────────────
create or replace function public.cancelar_reserva(
  p_booking_id uuid,
  p_cancel_reason text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
begin
  update public.bookings
  set status = 'cancelled', cancel_reason = p_cancel_reason
  where id = p_booking_id
    and (client_id = v_uid or employee_id = v_uid or public.is_admin_or_sysadmin());

  if not found then
    raise exception 'NOT_AUTHORIZED_OR_NOT_FOUND';
  end if;
end;
$$;
grant execute on function public.cancelar_reserva(uuid, text) to authenticated;

-- ── actualizar_estado_reserva ─────────────────────────────────────────────
create or replace function public.actualizar_estado_reserva(
  p_booking_id uuid,
  p_status text
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_booking public.bookings%rowtype;
  v_commission numeric;
begin
  select * into v_booking from public.bookings where id = p_booking_id;
  if v_booking.id is null then
    raise exception 'NOT_FOUND';
  end if;
  if not (v_booking.employee_id = v_uid or public.is_admin_or_sysadmin()) then
    raise exception 'NOT_AUTHORIZED';
  end if;

  update public.bookings set status = p_status where id = p_booking_id;

  if p_status = 'completed' then
    select amount into v_commission from public.commission_configs where service_id = v_booking.service_id;
    if v_commission is not null and v_commission > 0 then
      insert into public.commission_entries
        (employee_id, booking_id, service_id, service_name, service_price, commission_amount)
      select v_booking.employee_id, v_booking.id, s.id, s.name, s.price, v_commission
      from public.services s where s.id = v_booking.service_id;
    end if;

    insert into public.commission_entries
      (employee_id, booking_id, service_id, service_name, service_price, commission_amount)
    select v_booking.employee_id, v_booking.id, s.id, s.name, s.price, cc.amount
    from public.booking_extra_services bes
    join public.services s on s.id = bes.service_id
    join public.commission_configs cc on cc.service_id = s.id and cc.amount > 0
    where bes.booking_id = v_booking.id;
  end if;
end;
$$;
grant execute on function public.actualizar_estado_reserva(uuid, text) to authenticated;

-- ── process_commission_cut ────────────────────────────────────────────────
create or replace function public.process_commission_cut(
  p_week_start date,
  p_week_end date
)
returns void
language plpgsql security definer set search_path = public as $$
declare
  v_emp record;
  v_cut_id uuid;
begin
  if not public.is_admin_or_sysadmin() then
    raise exception 'NOT_AUTHORIZED';
  end if;

  for v_emp in
    select employee_id, sum(commission_amount) as total, count(*) as cnt
    from public.commission_entries
    where cut_id is null
      and earned_at >= p_week_start::timestamptz
      and earned_at < (p_week_end + 1)::timestamptz
    group by employee_id
  loop
    insert into public.commission_cuts
      (employee_id, week_start, week_end, total_amount, services_count, status)
    values
      (v_emp.employee_id, p_week_start, p_week_end, v_emp.total, v_emp.cnt, 'pending')
    returning id into v_cut_id;

    update public.commission_entries
    set cut_id = v_cut_id
    where cut_id is null
      and employee_id = v_emp.employee_id
      and earned_at >= p_week_start::timestamptz
      and earned_at < (p_week_end + 1)::timestamptz;
  end loop;
end;
$$;
grant execute on function public.process_commission_cut(date, date) to authenticated;

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ============================================================================

alter table public.profiles                enable row level security;
alter table public.services                enable row level security;
alter table public.employee_services       enable row level security;
alter table public.work_schedules          enable row level security;
alter table public.bookings                enable row level security;
alter table public.booking_extra_services  enable row level security;
alter table public.reviews                 enable row level security;
alter table public.products                enable row level security;
alter table public.saved_products          enable row level security;
alter table public.orders                  enable row level security;
alter table public.order_items             enable row level security;
alter table public.supplies                enable row level security;
alter table public.app_config              enable row level security;
alter table public.commission_configs      enable row level security;
alter table public.commission_settings     enable row level security;
alter table public.commission_cuts         enable row level security;
alter table public.commission_entries      enable row level security;
alter table public.session_logs            enable row level security;
alter table public.activity_logs           enable row level security;

-- ── profiles ─────────────────────────────────────────────────────────────
create policy "profiles_select_authenticated" on public.profiles
  for select to authenticated using (true);
create policy "profiles_insert_self" on public.profiles
  for insert to authenticated with check (id = auth.uid());
create policy "profiles_update_self_or_admin" on public.profiles
  for update to authenticated using (id = auth.uid() or public.is_admin_or_sysadmin());
create policy "profiles_delete_admin" on public.profiles
  for delete to authenticated using (public.is_admin_or_sysadmin());

-- ── services (catálogo público) ────────────────────────────────────────────
create policy "services_select_public" on public.services
  for select to anon, authenticated using (true);
create policy "services_write_admin" on public.services
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── employee_services ───────────────────────────────────────────────────
create policy "employee_services_select_public" on public.employee_services
  for select to anon, authenticated using (true);
create policy "employee_services_write_admin" on public.employee_services
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── work_schedules ───────────────────────────────────────────────────────
create policy "work_schedules_select" on public.work_schedules
  for select to authenticated using (employee_id = auth.uid() or public.is_admin());
create policy "work_schedules_write_admin" on public.work_schedules
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── bookings (mutaciones sólo vía funciones RPC security definer) ────────
create policy "bookings_select" on public.bookings
  for select to authenticated
  using (client_id = auth.uid() or employee_id = auth.uid() or public.is_admin_or_sysadmin());

-- ── booking_extra_services ────────────────────────────────────────────────
create policy "booking_extra_services_select" on public.booking_extra_services
  for select to authenticated using (
    exists (
      select 1 from public.bookings b
      where b.id = booking_extra_services.booking_id
        and (b.client_id = auth.uid() or b.employee_id = auth.uid() or public.is_admin_or_sysadmin())
    )
  );

-- ── reviews ──────────────────────────────────────────────────────────────
create policy "reviews_select_public" on public.reviews
  for select to anon, authenticated using (true);
create policy "reviews_insert_own" on public.reviews
  for insert to authenticated with check (
    client_id = auth.uid()
    and exists (select 1 from public.bookings b where b.id = booking_id and b.client_id = auth.uid())
  );

-- ── products (catálogo público) ────────────────────────────────────────────
create policy "products_select_public" on public.products
  for select to anon, authenticated using (true);
create policy "products_write_admin" on public.products
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── saved_products ───────────────────────────────────────────────────────
create policy "saved_products_own" on public.saved_products
  for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ── orders / order_items ────────────────────────────────────────────────
create policy "orders_select_own_or_admin" on public.orders
  for select to authenticated using (client_id = auth.uid() or public.is_admin());
create policy "orders_insert_own" on public.orders
  for insert to authenticated with check (client_id = auth.uid());
create policy "orders_update_admin" on public.orders
  for update to authenticated using (public.is_admin());

create policy "order_items_select" on public.order_items
  for select to authenticated using (
    exists (select 1 from public.orders o where o.id = order_items.order_id
            and (o.client_id = auth.uid() or public.is_admin()))
  );
create policy "order_items_insert" on public.order_items
  for insert to authenticated with check (
    exists (select 1 from public.orders o where o.id = order_items.order_id and o.client_id = auth.uid())
  );

-- ── supplies (sólo admin) ───────────────────────────────────────────────
create policy "supplies_all_admin" on public.supplies
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── app_config ───────────────────────────────────────────────────────────
create policy "app_config_select_public" on public.app_config
  for select to anon, authenticated using (true);
create policy "app_config_write_admin" on public.app_config
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── commission_configs / commission_settings (sólo admin) ────────────────
create policy "commission_configs_all_admin" on public.commission_configs
  for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "commission_settings_all_admin" on public.commission_settings
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- ── commission_cuts ──────────────────────────────────────────────────────
create policy "commission_cuts_select" on public.commission_cuts
  for select to authenticated using (employee_id = auth.uid() or public.is_admin());
create policy "commission_cuts_update_admin" on public.commission_cuts
  for update to authenticated using (public.is_admin());

-- ── commission_entries ───────────────────────────────────────────────────
create policy "commission_entries_select" on public.commission_entries
  for select to authenticated using (employee_id = auth.uid() or public.is_admin());

-- ── session_logs ─────────────────────────────────────────────────────────
create policy "session_logs_select" on public.session_logs
  for select to authenticated using (profile_id = auth.uid() or public.is_sysadmin());
create policy "session_logs_insert_self" on public.session_logs
  for insert to authenticated with check (profile_id = auth.uid());
create policy "session_logs_update" on public.session_logs
  for update to authenticated using (profile_id = auth.uid() or public.is_sysadmin());
create policy "session_logs_delete_sysadmin" on public.session_logs
  for delete to authenticated using (public.is_sysadmin());

-- ── activity_logs ────────────────────────────────────────────────────────
create policy "activity_logs_select_sysadmin" on public.activity_logs
  for select to authenticated using (profile_id = auth.uid() or public.is_sysadmin());
create policy "activity_logs_insert_self" on public.activity_logs
  for insert to authenticated with check (profile_id = auth.uid());
create policy "activity_logs_delete_sysadmin" on public.activity_logs
  for delete to authenticated using (public.is_sysadmin());

-- ============================================================================
-- 7. PERMISOS BASE (necesarios además de RLS)
-- ============================================================================

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;
alter default privileges in schema public grant select, insert, update, delete on tables to authenticated;
alter default privileges in schema public grant select on tables to anon;

-- ============================================================================
-- 8. STORAGE (buckets usados por la app)
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('services', 'services', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('products', 'products', true)
on conflict (id) do nothing;

-- Lectura pública de los 3 buckets
create policy "public_read_avatars" on storage.objects
  for select using (bucket_id = 'avatars');
create policy "public_read_services" on storage.objects
  for select using (bucket_id = 'services');
create policy "public_read_products" on storage.objects
  for select using (bucket_id = 'products');

-- avatars: cada usuario sólo puede escribir dentro de su propia carpeta "{uid}/..."
create policy "avatars_write_own_folder" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "avatars_update_own_folder" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

-- services / products: sólo admin sube/edita imágenes
create policy "services_write_admin" on storage.objects
  for insert to authenticated with check (bucket_id = 'services' and public.is_admin());
create policy "services_update_admin" on storage.objects
  for update to authenticated using (bucket_id = 'services' and public.is_admin());
create policy "products_write_admin" on storage.objects
  for insert to authenticated with check (bucket_id = 'products' and public.is_admin());
create policy "products_update_admin" on storage.objects
  for update to authenticated using (bucket_id = 'products' and public.is_admin());

-- ============================================================================
-- 9. DATOS INICIALES (necesarios para que la app no truene al arrancar)
-- ============================================================================

insert into public.app_config (id, primary_color)
values (true, '#4ECDC4')
on conflict (id) do nothing;

insert into public.commission_settings (cutoff_day, cutoff_hour, cutoff_minute)
select 0, 23, 59
where not exists (select 1 from public.commission_settings);

-- ============================================================================
-- NOTAS
-- ============================================================================
-- 1. Tu primer usuario NO tendrá rol admin automáticamente. Regístrate desde
--    la app y luego, en el SQL Editor, ejecuta:
--      update public.profiles set role = 'sysadmin' where email = 'tu-correo@ejemplo.com';
--    (usa 'admin' o 'sysadmin' según el panel al que quieras entrar).
--
-- 2. OAuth (Google/Facebook): actívalos en Authentication > Providers con tus
--    propias credenciales; el código ya usa el redirect
--    'io.supabase.barbershop://login-callback' (ver providers/auth_provider.dart).
--
-- 3. Edge Function de Stripe (supabase/functions/create-payment-intent) sigue
--    pendiente de desplegar y de la variable de entorno STRIPE_SECRET_KEY
--    (ver memoria del proyecto: aún no tienes cuenta de Stripe).
--
-- 4. Tablas/repositorios que existen en el código pero NO están conectados a
--    ninguna pantalla real (código muerto) y por lo tanto NO se recrearon:
--    'reservations'/'employees'/'apps'/'app_configs'/'app_permissions'
--    (lib/data/reservation_repository.dart y app_config_repository.dart),
--    y la vista 'v_current_context' (lib/data/session_context.dart).
--    Si esas pantallas llegan a activarse algún día, avísame y las agrego.
-- ============================================================================
