import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const PRINCIPAL_SYSADMIN_EMAIL = 'sysadmin@prettycore.xyz';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

// Borra un negocio (tenant) COMPLETO e irreversiblemente — pedido explícito
// del usuario: "también deben poder eliminarse apps, no solo suspender".
// Borra en cascada TODO lo que pertenece al tenant (reservas, pedidos,
// productos, servicios, comisiones, perfiles de sus clientes/empleados/
// admins — ver 20260820140000_borrado_total_tenant.sql) y además la cuenta
// de Supabase Auth de cada uno de esos perfiles (la cascada de SQL solo
// llega hasta public.profiles, no hasta auth.users).
//
// Dos protecciones que ni siquiera esta función puede saltarse:
// 1. La cuenta sysadmin@prettycore.xyz (sysadmin principal de la
//    plataforma) nunca se borra — si es "de casa" de este tenant, se
//    rechaza el borrado completo del negocio (trigger
//    proteger_perfil_sysadmin_principal, sin válvula de escape).
// 2. Solo platform_admin puede llamar esto — borrar un negocio entero es
//    una operación de plataforma, no de un tenant individual.
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
      .select('role')
      .eq('id', caller.id)
      .maybeSingle();
    if (callerPerfil?.role !== 'platform_admin') {
      return responder(403, { success: false, error: 'forbidden' });
    }

    const body = await req.json();
    const tenantId = String(body.tenant_id ?? '').trim();
    const slugConfirmacion = String(body.slug_confirmacion ?? '').trim();
    if (!tenantId) return responder(400, { success: false, error: 'missing_tenant_id' });

    const { data: tenant } = await admin
      .from('tenants')
      .select('id, slug, business_name')
      .eq('id', tenantId)
      .maybeSingle();
    if (!tenant) return responder(404, { success: false, error: 'tenant_not_found' });

    // El cliente debe mandar el slug tecleado por quien confirma — un
    // candado extra en el borrado más destructivo de toda la app, aparte
    // del diálogo de confirmación en la UI.
    if (slugConfirmacion !== tenant.slug) {
      return responder(400, { success: false, error: 'slug_mismatch' });
    }

    // Cuentas "de casa" de este tenant — hay que borrar su auth.users
    // aparte, porque el cascade de SQL solo llega hasta public.profiles.
    const { data: perfilesDeCasa } = await admin
      .from('profiles')
      .select('id, email, role')
      .eq('tenant_id', tenantId);
    const perfiles = perfilesDeCasa ?? [];

    if (perfiles.some((p) => p.email === PRINCIPAL_SYSADMIN_EMAIL)) {
      return responder(409, { success: false, error: 'contains_principal_sysadmin' });
    }
    // tenant_id de un platform_admin es solo un valor de relleno técnico
    // (nunca un negocio "de casa" real — ver Perfil.perteneceATenant), pero
    // por casualidad puede coincidir con un tenant real cualquiera. Sin este
    // chequeo, borrar ESE tenant borraría también la cuenta de ese
    // platform_admin como efecto secundario.
    if (perfiles.some((p) => p.role === 'platform_admin')) {
      return responder(409, { success: false, error: 'contains_platform_admin' });
    }

    const idsPerfiles = perfiles.map((p) => p.id as string);

    // Membresías que estas cuentas tienen en OTROS negocios (no se borran
    // solas con el cascade de este tenant, porque su tenant_id apunta a
    // otro negocio) — quedarían apuntando a un usuario que ya no existe.
    if (idsPerfiles.length > 0) {
      await admin
        .from('user_tenant_memberships')
        .delete()
        .in('user_id', idsPerfiles)
        .neq('tenant_id', tenantId);
    }

    // Enciende la válvula de escape del trigger bloquear_eliminacion_sysadmin
    // SOLO para esta transacción — permite que el cascade borre las cuentas
    // sysadmin propias de este tenant (si las tiene), sin abrir la puerta a
    // que ningún otro camino borre un sysadmin suelto.
    const { error: cascadeError } = await admin.rpc('borrar_tenant_en_cascada', {
      p_tenant_id: tenantId,
    });
    if (cascadeError) throw cascadeError;

    // Perfiles ya no existen en SQL — ahora limpiar sus cuentas de Auth.
    // Best-effort: si una falla, sigue con las demás (los datos de SQL ya
    // se borraron; una cuenta de Auth huérfana sin perfil es recuperable
    // a mano, no corrompe nada).
    const fallosAuth: string[] = [];
    for (const id of idsPerfiles) {
      const { error } = await admin.auth.admin.deleteUser(id);
      if (error) fallosAuth.push(id);
    }

    return responder(200, {
      success: true,
      cuentas_eliminadas: idsPerfiles.length,
      fallos_auth: fallosAuth.length,
    });
  } catch (error) {
    return responder(500, { success: false, error: String((error as Error)?.message ?? error) });
  }
});
