import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { SMTPClient } from 'https://deno.land/x/denomailer@1.6.0/mod.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SMTP_HOST = Deno.env.get('SMTP_HOST')!;
const SMTP_PORT = Number(Deno.env.get('SMTP_PORT') ?? '465');
const SMTP_USER = Deno.env.get('SMTP_USER')!;
const SMTP_PASSWORD = Deno.env.get('SMTP_PASSWORD')!;
const RESET_URL_BASE =
  Deno.env.get('RESET_URL_BASE') ?? 'https://prettycore.xyz/restablecer-contrasena.html';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

// Crea cuentas con rol elevado (employee/admin/sysadmin de un tenant, o
// admin/sysadmin de un tenant nuevo si quien llama es platform_admin).
// Nunca confía en un rol mandado por el cliente sin validarlo server-side
// contra el rol REAL de quien llama (leído de profiles con service_role,
// no de la metadata del JWT) — ver migración 20260819100000 para el
// contexto de la vulnerabilidad que reemplaza este flujo.
// Desplegar CON verificación de JWT (sin --no-verify-jwt): además de nuestra
// propia validación, el gateway de Supabase debe rechazar tokens inválidos.
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
    const email = String(body.email ?? '').trim().toLowerCase();
    const fullName = String(body.full_name ?? '').trim();
    const role = String(body.role ?? '').trim();

    if (!email || !email.includes('@')) return responder(400, { success: false, error: 'invalid_email' });
    if (!fullName) return responder(400, { success: false, error: 'invalid_name' });

    const callerRole = callerPerfil.role as string;
    let targetTenantId: string;
    let allowedRoles: string[];

    if (callerRole === 'platform_admin') {
      allowedRoles = ['admin', 'sysadmin'];
      targetTenantId = String(body.tenant_id ?? '');
      if (!targetTenantId) return responder(400, { success: false, error: 'missing_tenant_id' });
      const { data: tenant } = await admin
        .from('tenants').select('id').eq('id', targetTenantId).maybeSingle();
      if (!tenant) return responder(400, { success: false, error: 'invalid_tenant' });
    } else if (['admin', 'super_admin', 'sysadmin'].includes(callerRole)) {
      allowedRoles = callerRole === 'sysadmin'
        ? ['client', 'employee', 'admin', 'super_admin', 'sysadmin']
        : ['client', 'employee', 'admin'];
      targetTenantId = callerPerfil.tenant_id as string;
    } else {
      return responder(403, { success: false, error: 'forbidden' });
    }

    if (!allowedRoles.includes(role)) {
      return responder(403, { success: false, error: 'role_not_allowed' });
    }

    const { data: tenantInfo } = await admin
      .from('tenants').select('business_name').eq('id', targetTenantId).maybeSingle();
    const negocio = (tenantInfo?.business_name as string | undefined) || 'tu negocio';

    const esRolAdminNivel = ['admin', 'super_admin', 'sysadmin'].includes(role);
    const etiquetasRol: Record<string, string> = {
      client: 'cliente', employee: 'empleado', admin: 'administrador',
      super_admin: 'administrador', sysadmin: 'sysadmin',
    };

    const client = new SMTPClient({
      connection: {
        hostname: SMTP_HOST,
        port: SMTP_PORT,
        tls: SMTP_PORT === 465,
        auth: { username: SMTP_USER, password: SMTP_PASSWORD },
      },
    });

    // Correo ya existe: solo se puede otorgar acceso adicional si el rol es
    // admin-nivel (una misma cuenta administrando varios negocios). Para
    // client/employee sigue sin poder haber dos cuentas con el mismo correo
    // — eso queda fuera de alcance (ver migración 20260819130000).
    const { data: existingUserId } = await admin.rpc('get_user_id_by_email', { p_email: email });
    if (existingUserId) {
      if (!esRolAdminNivel) {
        return responder(409, { success: false, error: 'email_already_exists' });
      }

      const { error: membershipError } = await admin
        .from('user_tenant_memberships')
        .upsert({ user_id: existingUserId, tenant_id: targetTenantId, role },
          { onConflict: 'user_id,tenant_id' });
      if (membershipError) throw membershipError;

      await client.send({
        from: SMTP_USER,
        to: email,
        subject: `Ahora también administras ${negocio}`,
        content: `¡Hola ${fullName}! Te dieron acceso a ${negocio} como ${etiquetasRol[role] ?? role}. Entra con tu contraseña de siempre desde el dominio de ese negocio.`,
        html: `
          <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;">
            <h2>¡Hola, ${fullName}!</h2>
            <p>Te dieron acceso a <strong>${negocio}</strong> como <strong>${etiquetasRol[role] ?? role}</strong>.</p>
            <p>No necesitas configurar nada nuevo — entra con tu contraseña de siempre desde el dominio de ese negocio.</p>
          </div>
        `,
      });
      await client.close();

      return responder(200, { success: true, id: existingUserId as string });
    }

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email,
      password: crypto.randomUUID() + crypto.randomUUID(),
      email_confirm: true,
      user_metadata: { full_name: fullName, tenant_id: targetTenantId },
    });
    if (createError || !created?.user) {
      const msg = String(createError?.message ?? '');
      if (msg.toLowerCase().includes('already') || msg.toLowerCase().includes('registered')) {
        return responder(409, { success: false, error: 'email_already_exists' });
      }
      throw createError ?? new Error('create_user_failed');
    }

    const newUserId = created.user.id;

    const { error: roleUpdateError } = await admin
      .from('profiles').update({ role }).eq('id', newUserId);
    if (roleUpdateError) throw roleUpdateError;

    if (esRolAdminNivel) {
      // Siembra su membresía "de casa" para que quede consistente con
      // futuras invitaciones a otros negocios.
      const { error: seedError } = await admin
        .from('user_tenant_memberships')
        .upsert({ user_id: newUserId, tenant_id: targetTenantId, role },
          { onConflict: 'user_id,tenant_id' });
      if (seedError) throw seedError;
    }

    const token = crypto.randomUUID() + crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString(); // 72 horas
    const { error: tokenError } = await admin.from('password_reset_tokens').insert({
      user_id: newUserId,
      tenant_id: targetTenantId,
      token,
      expires_at: expiresAt,
    });
    if (tokenError) throw tokenError;

    const link = `${RESET_URL_BASE}?token=${token}`;

    await client.send({
      from: SMTP_USER,
      to: email,
      subject: `Te invitaron a administrar ${negocio}`,
      content: `¡Hola ${fullName}! Te dieron acceso a ${negocio} como ${etiquetasRol[role] ?? role}. Configura tu contraseña aquí: ${link}\n\nEste enlace expira en 72 horas.`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;">
          <h2>¡Hola, ${fullName}!</h2>
          <p>Te dieron acceso a <strong>${negocio}</strong> como <strong>${etiquetasRol[role] ?? role}</strong>. Configura tu contraseña para entrar:</p>
          <p style="text-align:center;margin:28px 0;">
            <a href="${link}" style="background:#1C1C1E;color:#fff;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:bold;">Configurar mi contraseña</a>
          </p>
          <p style="color:#888;font-size:12px;">Este enlace expira en 72 horas.</p>
        </div>
      `,
    });
    await client.close();

    return responder(200, { success: true, id: newUserId });
  } catch (error) {
    return responder(500, { success: false, error: String((error as Error)?.message ?? error) });
  }
});
