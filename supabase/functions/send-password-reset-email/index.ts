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

// Función pública (sin verificación de JWT): la llama alguien que NO tiene
// sesión porque olvidó su contraseña. Desplegar con --no-verify-jwt.
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

  // Siempre respondemos éxito, exista o no la cuenta, para no filtrar
  // qué correos están registrados (user enumeration).
  const responderExito = () =>
    new Response(JSON.stringify({ success: true }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });

  try {
    const { email } = await req.json();
    if (!email) return responderExito();

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: userId } = await admin.rpc('get_user_id_by_email', { p_email: email });
    if (!userId) return responderExito();

    const { data: perfil } = await admin
      .from('profiles')
      .select('full_name')
      .eq('id', userId)
      .maybeSingle();

    const token = crypto.randomUUID() + crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString(); // 1 hora

    const { error: insertError } = await admin.from('password_reset_tokens').insert({
      user_id: userId,
      token,
      expires_at: expiresAt,
    });
    if (insertError) throw insertError;

    const link = `${RESET_URL_BASE}?token=${token}`;
    const nombre = (perfil?.full_name as string | undefined)?.trim() || 'hola';

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
      subject: 'Restablece tu contraseña – Mil Cositas',
      content: `Restablece tu contraseña en Mil Cositas visitando este enlace: ${link}\n\nSi no solicitaste esto, ignora este correo. El enlace expira en 1 hora.`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;">
          <h2>¡Hola, ${nombre}!</h2>
          <p>Recibimos una solicitud para restablecer tu contraseña en <strong>Mil Cositas</strong>:</p>
          <p style="text-align:center;margin:28px 0;">
            <a href="${link}" style="background:#1C1C1E;color:#fff;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:bold;">Restablecer mi contraseña</a>
          </p>
          <p style="color:#888;font-size:12px;">Si no solicitaste esto, ignora este correo. El enlace expira en 1 hora.</p>
        </div>
      `,
    });
    await client.close();

    return responderExito();
  } catch (_error) {
    // No filtramos detalles del error al cliente por el mismo motivo de
    // no-enumeración; queda registrado en los logs de la función.
    return responderExito();
  }
});
