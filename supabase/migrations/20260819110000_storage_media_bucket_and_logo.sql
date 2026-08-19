-- ============================================================================
-- Migra la subida de imágenes de un script PHP en el Hetzner/Hostinger viejo
-- (ServicioFTP -> https://prettycore.xyz/upload.php, que ya no existe porque
-- ese dominio ahora sirve la app Flutter vía Vercel, no PHP) a Supabase
-- Storage. Bucket público único `media`, con rutas prefijadas por tenant
-- (`{tenant_id}/...`) para que RLS pueda filtrar por negocio igual que en
-- el resto de las tablas.
--
-- De paso, agrega `logo_url` a app_config: cada negocio va a poder tener su
-- propio logo (antes estaba hardcodeado a uno solo para toda la plataforma).
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

-- Lectura pública (logos, banners, fotos de producto son parte del catálogo
-- público de cada negocio — mismo criterio que products_select_public etc.)
drop policy if exists "media_select_public" on storage.objects;
create policy "media_select_public" on storage.objects
  for select to anon, authenticated using (bucket_id = 'media');

-- Escritura: solo admin/sysadmin del tenant dueño del primer segmento de la
-- ruta (`{tenant_id}/...`). platform_admin no necesita subir aquí (no tiene
-- tenant_id real), así que no se incluye en esta política.
drop policy if exists "media_insert_admin" on storage.objects;
create policy "media_insert_admin" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'media'
    and public.is_admin_or_sysadmin()
    and (storage.foldername(name))[1] = public.current_tenant_id()::text
  );

drop policy if exists "media_update_admin" on storage.objects;
create policy "media_update_admin" on storage.objects
  for update to authenticated using (
    bucket_id = 'media'
    and public.is_admin_or_sysadmin()
    and (storage.foldername(name))[1] = public.current_tenant_id()::text
  );

drop policy if exists "media_delete_admin" on storage.objects;
create policy "media_delete_admin" on storage.objects
  for delete to authenticated using (
    bucket_id = 'media'
    and public.is_admin_or_sysadmin()
    and (storage.foldername(name))[1] = public.current_tenant_id()::text
  );

alter table public.app_config add column if not exists logo_url text;
