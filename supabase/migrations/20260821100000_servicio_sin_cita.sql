-- "Sin cita": un empleado que hizo un servicio a un cliente sin haber
-- creado una reserva (walk-in que no se registró en el sistema) puede
-- avisarle al admin desde su propio panel, para que meta la reserva
-- correspondiente manualmente y así el corte semanal cuadre con lo que
-- de verdad se cobró. No crea ninguna reserva ni mueve dinero por sí
-- solo — es únicamente una notificación con el detalle necesario para
-- que el admin actúe.
create or replace function public.reportar_servicio_sin_cita(
  p_service_id uuid,
  p_nota text default null
)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  v_tenant_id uuid;
  v_uid uuid := auth.uid();
  v_empleado_nombre text;
  v_servicio_nombre text;
  v_cuerpo text;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  v_tenant_id := public.current_tenant_id();
  if v_tenant_id is null then
    raise exception 'NO_TENANT';
  end if;

  select full_name into v_empleado_nombre
  from public.profiles where id = v_uid and tenant_id = v_tenant_id;
  if v_empleado_nombre is null then
    raise exception 'NOT_AUTHORIZED';
  end if;

  select name into v_servicio_nombre
  from public.services where id = p_service_id and tenant_id = v_tenant_id;
  if v_servicio_nombre is null then
    raise exception 'SERVICE_NOT_FOUND';
  end if;

  v_cuerpo := v_empleado_nombre || ' hizo "' || v_servicio_nombre ||
    '" sin cita registrada — agrega una reserva con ese servicio para que cuadre el corte semanal.';
  if p_nota is not null and length(trim(p_nota)) > 0 then
    v_cuerpo := v_cuerpo || ' Nota: ' || trim(p_nota);
  end if;

  insert into public.notifications (user_id, title, body, type, related_id, tenant_id)
  select id, 'Servicio sin cita', v_cuerpo, 'servicio_sin_cita', p_service_id, v_tenant_id
  from public.profiles
  where role in ('admin','super_admin','sysadmin') and tenant_id = v_tenant_id;
end;
$$;
