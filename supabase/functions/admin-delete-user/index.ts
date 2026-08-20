import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

// Borra una cuenta por completo — estilo "Facebook": el perfil Y la cuenta
// de Supabase Auth desaparecen, así que si la persona necesita volver a
// entrar tiene que registrarse de cero (el correo queda libre). Antes solo
// se borraba public.profiles desde el cliente: la cuenta de Auth quedaba
// viva (sesión "colgada" al intentar iniciar sesión — ver
// RepositorioAuth.iniciarSesion) y el correo no se podía volver a usar
// para un registro nuevo.
//
// El historial de negocio (reservas, pedidos, comisiones, reseñas) NO se
// borra — las columnas que apuntan a esta cuenta pasan a null (ver
// 20260820120000_borrado_completo_conserva_historial.sql), así que la
// UI debe mostrar un fallback tipo "Cuenta eliminada" donde antes había
// un nombre.
//
// Igual que admin-create-user: el permiso se valida server-side contra el
// rol REAL de quien llama (leído con service_role, nunca del JWT). Los
// triggers de la base de datos (bloquear_eliminacion_sysadmin,
// proteger_perfil_sysadmin_principal) siguen aplicando aunque esto corra
// con service_role — no se bypasean con RLS.
// Desplegar CON verificación de JWT (sin --no-verify-jwt).
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

  const responder = (status: number, body: Record<string, unknown>) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });

  try {
    const jwt = (req.headers.get('Authorization') ?? '').replace('Bearer ', '');
    if (!jwt) return responder(401, { success: false, error: 'missing_auth' });

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: userData, error: userError } = await admin.auth.getUser(jwt);
    const caller = userData?.user;
    if (userError || !caller) return responder(401, { success: false, error: 'invalid_session' });

    const { data: callerPerfil } = await admin
      .from('profiles')
      .select('role, tenant_id')
      .eq('id', caller.id)
      .maybeSingle();
    if (!callerPerfil) return responder(403, { success: false, error: 'forbidden' });

    const body = await req.json();
    const targetId = String(body.user_id ?? '').trim();
    if (!targetId) return responder(400, { success: false, error: 'missing_user_id' });
    if (targetId === caller.id) return responder(400, { success: false, error: 'cannot_delete_self' });

    const { data: target } = await admin
      .from('profiles')
      .select('id, role, tenant_id')
      .eq('id', targetId)
      .maybeSingle();
    if (!target) return responder(404, { success: false, error: 'user_not_found' });

    const callerRole = callerPerfil.role as string;
    const targetRole = target.role as string;

    if (targetRole === 'sysadmin') {
      // Bloqueado también por trigger a nivel de base de datos — este
      // chequeo solo da un error limpio en vez de dejar que se vea el
      // mensaje crudo de Postgres.
      return responder(403, { success: false, error: 'cannot_delete_sysadmin' });
    }

    if (callerRole === 'platform_admin') {
      if (!['admin', 'super_admin'].includes(targetRole)) {
        return responder(403, { success: false, error: 'role_not_allowed' });
      }
    } else if (['admin', 'super_admin', 'sysadmin'].includes(callerRole)) {
      if (targetRole === 'platform_admin') {
        return responder(403, { success: false, error: 'role_not_allowed' });
      }
      // Igual que admin-create-user: profiles.tenant_id es el tenant "de
      // casa" fijo de quien llama, pero una cuenta con membresía en varios
      // negocios (20260819170000_multitenant_membership) puede administrar
      // — y borrar cuentas de — cualquier negocio donde tenga membresía
      // admin-nivel, no solo el de casa.
      const targetTenantId = target.tenant_id as string;
      let tieneAcceso = targetTenantId === callerPerfil.tenant_id;
      if (!tieneAcceso) {
        const { data: membresia } = await admin
          .from('user_tenant_memberships')
          .select('role')
          .eq('user_id', caller.id)
          .eq('tenant_id', targetTenantId)
          .maybeSingle();
        tieneAcceso = !!membresia && ['admin', 'super_admin', 'sysadmin'].includes(membresia.role as string);
      }
      if (!tieneAcceso) {
        return responder(403, { success: false, error: 'forbidden' });
      }
    } else {
      return responder(403, { success: false, error: 'forbidden' });
    }

    const { error: deleteProfileError } = await admin.from('profiles').delete().eq('id', targetId);
    if (deleteProfileError) throw deleteProfileError;

    const { error: deleteAuthError } = await admin.auth.admin.deleteUser(targetId);
    if (deleteAuthError) throw deleteAuthError;

    return responder(200, { success: true });
  } catch (error) {
    return responder(500, { success: false, error: String((error as Error)?.message ?? error) });
  }
});
