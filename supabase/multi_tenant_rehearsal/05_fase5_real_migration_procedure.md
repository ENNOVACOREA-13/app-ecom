# Fase 5/6: procedimiento real de migración (MC-BARBER Hetzner → Cloud)

Ensayado con éxito 2026-08-18 contra un Postgres local, usando un dump real
de solo lectura del Hetzner de MC-BARBER (`62.238.60.24`). Resultado: 27/27
tablas con conteos idénticos, 4/4 sumas de dinero idénticas, 0 nulls tras
backfill, 0 filas malas en la auditoría cruzada, prueba de humo con el admin
real viendo sus 8 reservas/1 pedido reales. Este archivo documenta el
procedimiento exacto para cuando se ejecute el corte real (Fase 6) — sin
datos reales, solo el patrón.

## 1. Dump de solo lectura del origen (no modifica el Hetzner)

```bash
ssh -i ~/.ssh/control_plane_hetzner root@62.238.60.24 \
  "docker exec supabase-db pg_dump -U postgres -d postgres --data-only --no-owner --no-acl --schema=public" \
  > public_dump.sql

ssh -i ~/.ssh/control_plane_hetzner root@62.238.60.24 \
  "docker exec supabase-db pg_dump -U postgres -d postgres --data-only --no-owner --no-acl \
    --table=auth.users --table=auth.identities --table=auth.sessions \
    --table=auth.refresh_tokens --table=auth.mfa_amr_claims --table=auth.audit_log_entries" \
  > auth_dump.sql
```
(Dos comandos separados — mezclar `--schema=public` con `--table=auth.x` en
uno solo descarta silenciosamente la parte de schema completo. Se excluye
deliberadamente `auth.schema_migrations`, que pertenece al GoTrue propio
del proyecto Cloud destino, no al origen.)

**Antes de esto**: capturar conteos reales por tabla y sumas de columnas de
dinero del origen (`select count(*)`/`select sum(...)`) para poder verificar
después — nunca confiar en `pg_stat_user_tables.n_live_tup`, miente/tarda
justo después de una transacción.

**Cuidado con `commission_settings`**: en la corrida real de MC-BARBER
apareció con 2 filas (nunca tuvo un PK-singleton real a nivel de BD, solo
convención de la app) con valores idénticos — verificar antes de asumir 1
sola fila; si hay duplicados, confirmar con el usuario cuál conservar antes
de descartar el resto en el backfill.

## 2. Restore contra el proyecto Cloud real

```sql
set session_replication_role = replica;  -- desactiva TODOS los triggers,
                                          -- incluyendo handle_new_user()
                                          -- (que desde Fase 4 exige
                                          -- tenant_id y fallaría) y las
                                          -- protecciones de sysadmin.

-- Limpiar las filas default que Fase 1 ya sembró en las 3 tablas
-- singleton (existen en CUALQUIER proyecto recién migrado, ver
-- 20260807120000_rebuild_schema.sql sección 9 "DATOS INICIALES").
truncate table public.app_config, public.commission_settings, public.loyalty_config;

\i auth_dump.sql
\i public_dump.sql

set session_replication_role = origin;
```

## 3. Backfill del tenant_id real

```sql
insert into public.tenants (id, slug, business_name) values
  (gen_random_uuid(), 'mc-barber', 'MC-BARBER')
returning id \gset tenant_

insert into public.tenant_domains (tenant_id, domain) values
  (:'tenant_id', 'app-mc.vercel.app');

-- provision_tenant_defaults() acaba de sembrar OTRA fila default para este
-- tenant_id recién creado (el trigger no sabe que ya vienen datos reales
-- restaurados) — se borra antes del backfill real.
delete from public.app_config where tenant_id = :'tenant_id';
delete from public.commission_settings where tenant_id = :'tenant_id';
delete from public.loyalty_config where tenant_id = :'tenant_id';

-- Un UPDATE sin WHERE (todo lo restaurado pertenece a este único tenant)
-- por cada una de las 27 tablas reales. Ver 01_seed_synthetic_tenants.sql
-- para la lista completa de nombres de tabla.
update public.profiles set tenant_id = :'tenant_id';
-- ... (repetir para las 26 tablas restantes)
```

## 4. Verificación (gate duro antes de cutover)

```sql
-- 0 nulls en las 27 tablas
select table_name, (xpath('/row/c/text()', query_to_xml(
  format('select count(*) as c from public.%I where tenant_id is null', table_name),
  false, true, '')))[1]::text::int as nulls
from information_schema.tables where table_schema='public' and table_type='BASE TABLE'
and table_name not in ('tenants','tenant_domains');
```
Comparar contra los conteos/sumas capturados en el paso 1. Correr también
`02_cross_tenant_audit.sql` contra los datos reales ya backfilleados.

## 5. Cutover (Fase 6, ventana de mantenimiento corta)

1. Congelar escrituras: `status='maintenance'` en el control plane VIEJO
   para el tenant MC-BARBER (la app ya muestra `PaginaTenantNoDisponible`
   sin tocar el Hetzner).
2. Repetir los pasos 1-4 de arriba (ya cronometrados en el ensayo) contra
   el proyecto Cloud real, con datos frescos (puede haber cambiado algo
   desde el ensayo).
3. Checklist de humo manual: login real, ver reservas, crear/cancelar una
   reserva de prueba, crear un pedido de prueba, confirmar que comisiones
   y puntos de lealtad calculan igual.
4. Cambiar `tenant_resolver.dart`/`constants.dart` (Fase 6, cambio de
   código Flutter aparte) para apuntar al proyecto compartido en vez del
   control plane viejo, y redeploy.
5. Periodo de gracia de 14-30 días con el Hetzner viejo encendido sin
   tráfico antes de decomisionar — ver Fase 7 del plan completo.
