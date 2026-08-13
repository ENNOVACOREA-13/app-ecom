-- ── Habilitar Realtime en profiles ─────────────────────────────────────────
-- Necesario para que el cliente detecte al instante cuando un admin/sysadmin
-- desactiva su cuenta (profiles.is_active = false) mientras la app está
-- abierta, y lo desconecte automáticamente.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profiles'
  ) then
    alter publication supabase_realtime add table public.profiles;
  end if;
end $$;
