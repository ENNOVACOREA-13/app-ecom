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

// Registro público de clientes (self-service), en un solo correo: en vez
// de mandar un correo para "confirmar tu cuenta" y hacer que la persona
// ya haya puesto una contraseña en el formulario (que luego resultaba
// redundante, y ese correo aparte no estaba llegando bien), esto crea la
// cuenta sin contraseña y reusa exactamente el mismo mecanismo de
// password_reset_tokens + reset-password + restablecer-contrasena.html ya
// probado con las invitaciones de admin-create-user — un solo enlace
// confirma el correo Y deja poner la contraseña.
// Función pública (sin verificación de JWT, como reset-password):
// desplegar con --no-verify-jwt.
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

  const responder = (status: number, body: Record<string, unknown>) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, 'Content-Type': 'application/json' },
    });

  try {
    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const body = await req.json();
    const email = String(body.email ?? '').trim().toLowerCase();
    const fullName = String(body.full_name ?? '').trim();
    const phone = String(body.phone ?? '').trim();
    const tenantId = String(body.tenant_id ?? '').trim();

    if (!email || !email.includes('@')) return responder(400, { success: false, error: 'invalid_email' });
    if (!fullName) return responder(400, { success: false, error: 'invalid_name' });
    if (!tenantId) return responder(400, { success: false, error: 'missing_tenant_id' });

    const { data: tenant } = await admin
      .from('tenants').select('business_name, status').eq('id', tenantId).maybeSingle();
    if (!tenant || tenant.status !== 'active') {
      return responder(400, { success: false, error: 'invalid_tenant' });
    }

    const { data: existingUserId } = await admin.rpc('get_user_id_by_email', { p_email: email });
    if (existingUserId) return responder(409, { success: false, error: 'email_already_exists' });

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email,
      password: crypto.randomUUID() + crypto.randomUUID(),
      email_confirm: true,
      user_metadata: { full_name: fullName, tenant_id: tenantId },
    });
    if (createError || !created?.user) {
      const msg = String(createError?.message ?? '');
      if (msg.toLowerCase().includes('already') || msg.toLowerCase().includes('registered')) {
        return responder(409, { success: false, error: 'email_already_exists' });
      }
      throw createError ?? new Error('create_user_failed');
    }

    const newUserId = created.user.id;

    if (phone) {
      await admin.from('profiles').update({ phone }).eq('id', newUserId);
    }

    const token = crypto.randomUUID() + crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString(); // 72 horas
    const { error: tokenError } = await admin.from('password_reset_tokens').insert({
      user_id: newUserId,
      tenant_id: tenantId,
      token,
      expires_at: expiresAt,
    });
    if (tokenError) throw tokenError;

    const link = `${RESET_URL_BASE}?token=${token}`;
    const negocio = (tenant.business_name as string | undefined) || 'tu negocio';

    const client = new SMTPClient({
      connection: {
        hostname: SMTP_HOST,
        port: SMTP_PORT,
        tls: SMTP_PORT === 465,
        auth: { username: SMTP_USER, password: SMTP_PASSWORD },
      },
    });

    await client.send({
      from: SMTP_USER,
      to: email,
      subject: `Confirma tu cuenta en ${negocio}`,
      content: `¡Hola ${fullName}! Confirma tu cuenta en ${negocio} y crea tu contraseña aquí: ${link}\n\nEste enlace expira en 72 horas.`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;">
          <h2>¡Hola, ${fullName}!</h2>
          <p>Gracias por registrarte en <strong>${negocio}</strong>. Confirma tu cuenta y crea tu contraseña para entrar:</p>
          <p style="text-align:center;margin:28px 0;">
            <a href="${link}" style="background:#1C1C1E;color:#fff;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:bold;">Confirmar y crear mi contraseña</a>
          </p>
          <p style="color:#888;font-size:12px;">Si no creaste esta cuenta, ignora este correo. Este enlace expira en 72 horas.</p>
        </div>
      `,
    });
    await client.close();

    return responder(200, { success: true, id: newUserId });
  } catch (error) {
    return responder(500, { success: false, error: String((error as Error)?.message ?? error) });
  }
});
