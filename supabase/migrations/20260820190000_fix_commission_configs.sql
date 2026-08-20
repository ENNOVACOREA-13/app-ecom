-- Dos bugs reales encontrados al reportar "no deja asignar comisiones a un
-- servicio":
--
-- 1. commission_configs.tenant_id es NOT NULL sin default, pero
--    RepositorioComision.guardarConfiguracion() nunca lo mandaba en el
--    upsert — la PRIMERA vez que se configuraba la comisión de un
--    servicio (sin fila previa para ese service_id) tronaba directo por
--    la restricción de la columna, antes de siquiera llegar a RLS. Ya se
--    corrigió en el cliente (Dart); esta migración es la mitad de
--    servidor.
--
-- 2. La política usaba is_admin() (solo 'admin'/'super_admin') en vez de
--    is_admin_or_sysadmin() — mismo patrón de bug ya visto varias veces
--    en este proyecto (ver feedback_rls_silent_failure en memoria):
--    bloqueaba silenciosamente a cualquier cuenta sysadmin.
drop policy if exists "commission_configs_all_admin" on public.commission_configs;
create policy "commission_configs_all_admin" on public.commission_configs
  for all to authenticated
  using (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin())
  with check (tenant_id = public.current_tenant_id() and public.is_admin_or_sysadmin());
