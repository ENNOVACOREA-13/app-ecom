-- Hallazgo real (reproducido en vivo): TODA subida de imagen a productos/
-- servicios/categorías fallaba con "new row violates row-level security
-- policy" — no por el tenant ni por el rol (ambos correctos), sino porque
-- ftp_upload_service.dart siempre sube con upsert:true (para poder
-- reemplazar una imagen sin duplicar archivos), y para decidir entre
-- INSERT/UPDATE el endpoint de Storage necesita poder verificar primero si
-- el objeto ya existe — eso requiere una política de SELECT. El bucket
-- 'media' solo tenía INSERT/UPDATE/DELETE (20260819110000), nunca SELECT
-- para admin/sysadmin, así que esa verificación fallaba silenciosamente y
-- se reportaba como error de RLS en la escritura, aunque el tenant y el
-- rol de quien subía fueran perfectamente correctos.
--
-- Reproducido con curl usando una cuenta real: sin el header x-upsert la
-- subida funcionaba; con x-upsert:true (lo que manda siempre la app)
-- fallaba con exactamente este error.
create policy "media_select_admin" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'media'
    and is_admin_or_sysadmin()
    and (storage.foldername(name))[1] = current_tenant_id()::text
  );
