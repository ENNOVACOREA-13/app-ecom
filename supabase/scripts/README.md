# Auditoría de aislamiento entre tenants

Tres consultas de solo lectura (`auditoria_1_*.sql`, `auditoria_2_*.sql`,
`auditoria_3_*.sql`) que revisan las causas raíz reales que ya produjeron
fugas o bugs de aislamiento en este proyecto (2026-08-20). Si cualquiera
regresa filas, hay un hueco real que revisar antes de seguir.

Corren automáticamente en cada push a `main` (job `auditoria-aislamiento`
en `.github/workflows/ci.yml`), pero también se pueden pegar directo en el
SQL Editor de Supabase o mandar por la Management API en cualquier
momento — sobre todo después de agregar una tabla, vista o bucket nuevo.

1. **`auditoria_1_tablas_sin_rls.sql`** — toda tabla con `tenant_id` debe
   tener RLS encendido y al menos una política que lo use (excepciones
   documentadas dentro del archivo).
2. **`auditoria_2_vistas_sin_invoker.sql`** — toda vista debe tener
   `security_invoker=true` o filtrar explícitamente por tenant en su
   definición.
3. **`auditoria_3_buckets_incompletos.sql`** — todo bucket privado de
   Storage debe tener las 4 políticas (SELECT/INSERT/UPDATE/DELETE).

## Configurar el secreto en GitHub (una sola vez)

El job de CI necesita `SUPABASE_ACCESS_TOKEN` como secreto del
repositorio para poder consultar la base real:

1. Genera un token en <https://supabase.com/dashboard/account/tokens> (o
   reusa uno existente) — es un token de tu CUENTA de Supabase, no solo de
   este proyecto (Supabase no ofrece tokens más limitados que eso).
2. En GitHub: Settings → Secrets and variables → Actions → New repository
   secret.
3. Nombre: `SUPABASE_ACCESS_TOKEN`. Valor: el token del paso 1.

Sin este secreto configurado, el job no falla — solo avisa (`::warning::`)
que se omitió la auditoría automática, así que el resto del CI sigue
funcionando igual mientras tanto.
