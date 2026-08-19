-- El bucket `media` era público y su policy de lectura no tenía NINGUNA
-- condición de carpeta/tenant (bucket_id = 'media', sin más) — cualquiera
-- podía listar (storage.objects respeta RLS aunque el bucket sea público)
-- y leer directamente las imágenes de CUALQUIER negocio, no solo del que
-- visitaba. Pedido explícito del usuario tras la auditoría de aislamiento
-- del 2026-08-19: "NO DEBEN DE FILTRARSE NADA POR NADA DEL MUNDO DATOS".
--
-- Ahora el bucket es privado y el único lector es la Edge Function
-- media-proxy (usa service_role, pasa por encima de RLS) — las URLs que
-- sirve solo se generan si media-sign-url confirmó que quien las pide es
-- admin/sysadmin de ESE tenant (ver ambas funciones). Las policies de
-- escritura (ya scoped a current_tenant_id()) no cambian.
update storage.buckets set public = false where id = 'media';

drop policy if exists "media_select_public" on storage.objects;
