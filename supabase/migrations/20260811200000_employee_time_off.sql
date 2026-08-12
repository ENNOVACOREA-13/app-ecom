-- ── employee_time_off (días libres puntuales por empleado) ───────────────────
create table if not exists public.employee_time_off (
  id           uuid primary key default gen_random_uuid(),
  employee_id  uuid not null references public.profiles(id) on delete cascade,
  date         date not null,
  reason       text,
  created_at   timestamptz not null default now(),
  unique (employee_id, date)
);

alter table public.employee_time_off enable row level security;

drop policy if exists "employee_time_off_select" on public.employee_time_off;
create policy "employee_time_off_select" on public.employee_time_off
  for select using (employee_id = auth.uid() or is_admin_or_sysadmin());

drop policy if exists "employee_time_off_insert" on public.employee_time_off;
create policy "employee_time_off_insert" on public.employee_time_off
  for insert with check (employee_id = auth.uid() or is_admin_or_sysadmin());

drop policy if exists "employee_time_off_delete" on public.employee_time_off;
create policy "employee_time_off_delete" on public.employee_time_off
  for delete using (employee_id = auth.uid() or is_admin_or_sysadmin());

-- ── get_available_slots: respetar días libres puntuales ──────────────────────
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
  if exists (
    select 1 from public.employee_time_off
    where employee_id = p_employee_id and date = p_date
  ) then
    return;
  end if;

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
