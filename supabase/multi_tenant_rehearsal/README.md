# Ensayo local de la migración multi-tenant (Fases 3 y 4)

Scripts para probar, contra un Postgres local desechable (no Docker — este
entorno no lo tiene; usa el `postgres.exe`/`psql` nativo de Windows), que el
mecanismo de tenant_id/backfill/NOT NULL funciona **antes** de tocar
cualquier proyecto real. Ver el plan completo en
`C:\Users\HP\.claude\plans\stateful-dreaming-breeze.md` (Fase 3).

No son migraciones reales — no van numeradas como las de `supabase/migrations/`
y nunca se aplican a un proyecto Supabase real tal cual. `00_local_supabase_stub.sql`
en particular NO debe aplicarse a un proyecto Supabase real (crea roles/tablas
falsas que ya existen de verdad ahí).

## Cómo reproducir

Requiere PostgreSQL instalado localmente (`psql`/`pg_ctl`/`initdb` en el PATH).

```powershell
$env:PATH = "C:\Program Files\PostgreSQL\18\bin;" + $env:PATH
$PGDATA = "C:\pgtest_data"   # o cualquier ruta corta — el socket unix falla
                              # con rutas largas (límite de 107 bytes)
$SCRIPTS = "d:\FLUTTER\barber_app\supabase\multi_tenant_rehearsal"

# 1. Levantar un Postgres desechable
initdb -D $PGDATA -U postgres -A trust --locale=C --encoding=UTF8
New-Item -ItemType Directory -Force -Path C:\pgsock | Out-Null
pg_ctl -D $PGDATA -o "-p 54329 -k C:\pgsock" -l "$PGDATA\..\pg_log.txt" start

# 2. Roles + stub de lo que Supabase provee (auth/storage/realtime)
psql -h 127.0.0.1 -p 54329 -U postgres -d postgres -c "create role anon; create role authenticated; create role service_role;"
createdb -h 127.0.0.1 -p 54329 -U postgres barber_test
psql -h 127.0.0.1 -p 54329 -U postgres -d barber_test -v ON_ERROR_STOP=1 -f "$SCRIPTS\00_local_supabase_stub.sql"
psql -h 127.0.0.1 -p 54329 -U postgres -d barber_test -c "create publication supabase_realtime;"

# 3. Las migraciones reales (excluyendo los 3 seeds de desarrollo) + las de
#    Fase 2 (multi_tenant_*), en orden
Set-Location "d:\FLUTTER\barber_app\supabase\migrations"
$exclude = @("20260807130000_seed_users.sql", "20260807141000_demo_data.sql", "20260807150000_seed_admin_user.sql")
Get-ChildItem -Filter "*.sql" | Sort-Object Name | Where-Object { $exclude -notcontains $_.Name } | ForEach-Object {
    psql -h 127.0.0.1 -p 54329 -U postgres -d barber_test -v ON_ERROR_STOP=1 -f $_.FullName
}

# 4. El ensayo de Fase 3 en sí
psql -h 127.0.0.1 -p 54329 -U postgres -d barber_test -v ON_ERROR_STOP=1 -f "$SCRIPTS\01_seed_synthetic_tenants.sql"
psql -h 127.0.0.1 -p 54329 -U postgres -d barber_test -f "$SCRIPTS\02_cross_tenant_audit.sql"   # todas las filas en 0 = bien
psql -h 127.0.0.1 -p 54329 -U postgres -d barber_test -v ON_ERROR_STOP=1 -f "$SCRIPTS\03_backfill_rehearsal.sql"

# 4b. El gate de Fase 4: pruebas negativas cruzadas (simula sesiones reales
#     con SET ROLE + request.jwt.claims/request.headers — ver 00_local_supabase_stub.sql,
#     auth.uid() ahora lee esa GUC igual que Supabase real lee el JWT de PostgREST)
psql -h 127.0.0.1 -p 54329 -U postgres -d barber_test -f "$SCRIPTS\04_cross_tenant_negative_tests.sql"
# Cada línea "NOTICE: N. OK: ..." o la columna `ok` de cada SELECT debe ser
# true — cualquier "FALLO"/false es una fuga real de datos entre negocios.

# 5. Limpiar al terminar
pg_ctl -D $PGDATA stop -m fast
Remove-Item -Recurse -Force $PGDATA
```

## Qué prueba cada archivo

- **`01_seed_synthetic_tenants.sql`** — Tenant A y Tenant B con datos en las
  25 de 27 tablas reales (omite `booking_extra_services`/`commission_cuts`,
  mismo patrón que sus tablas hermanas, bajo riesgo incremental). Confirma
  que `tenants`/`provision_tenant_defaults()` funcionan de punta a punta:
  insertar un tenant siembra automáticamente `app_config`/
  `commission_settings`/`loyalty_config` para ese tenant.
- **`02_cross_tenant_audit.sql`** — para cada FK sensible (booking→empleado,
  booking→servicio, order_items→producto, etc.), confirma que ambos lados
  tienen el mismo `tenant_id`. Cualquier fila con `filas_malas > 0` es un bug
  real de aislamiento entre negocios.
- **`03_backfill_rehearsal.sql`** — simula datos "legacy" (sin `tenant_id`,
  como estarán los de MC-BARBER de verdad antes de la Fase 5) y corre el
  backfill. Última corrida real (2026-08-18): 0 nulls tras el backfill, y un
  `alter column tenant_id set not null` posterior + intento de insert sin
  tenant_id confirmó que la restricción rechaza correctamente la fila.

- **`04_cross_tenant_negative_tests.sql`** — el gate real de Fase 4. Logueado
  como Cliente A/Admin A (`SET ROLE authenticated` + `request.jwt.claims`
  simulando el JWT que pondría PostgREST), confirma que NADA de Tenant B es
  visible ni editable: lectura directa de tablas (bookings, profiles,
  commission_entries), las RPC de dinero (`crear_reserva`,
  `actualizar_estado_pedido`, `ajustar_puntos_lealtad`) rechazan IDs
  cruzados, un UPDATE directo (bypass RPC) sobre una fila de otro tenant
  afecta 0 filas, y `process_commission_cut` nunca mezcla comisiones entre
  negocios. También prueba el catálogo público como `anon` con el header
  `x-tenant-id`. Cada chequeo tiene su contraparte positiva (que Tenant A
  siga viendo/pudiendo hacer lo suyo con normalidad) — un RLS que bloquea
  todo "pasaría" un chequeo de fugas sin servir para nada.

## Resultado de la última corrida (2026-08-18)
Fase 3: 45/45 migraciones (42 reales + 3 de Fase 2) aplicaron limpio desde
cero. Seed de 2 tenants: OK. Auditoría cruzada: 0 filas malas en las 8
verificaciones. Backfill + NOT NULL: 0 nulls, constraint verificado real.

Fase 4: 47/47 migraciones (+ RLS y RPC tenant-aware) aplicaron limpio.
Suite de pruebas negativas cruzadas: **14/14 chequeos en OK, 0 fugas de
datos entre Tenant A y Tenant B**, incluyendo los 3 caminos que existían
para saltarse RLS (RPC con IDs cruzados, UPDATE directo bypaseando la RPC,
agregación sin filtrar en `process_commission_cut`).
