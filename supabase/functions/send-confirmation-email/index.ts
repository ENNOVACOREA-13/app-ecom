import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';
import { SMTPClient } from 'https://deno.land/x/denomailer@1.6.0/mod.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SMTP_HOST = Deno.env.get('SMTP_HOST')!;
const SMTP_PORT = Number(Deno.env.get('SMTP_PORT') ?? '465');
const SMTP_USER = Deno.env.get('SMTP_USER')!;
const SMTP_PASSWORD = Deno.env.get('SMTP_PASSWORD')!;
const CONFIRM_URL_BASE =
  Deno.env.get('CONFIRM_URL_BASE') ?? 'https://prettycore.xyz/confirmar-cuenta.html';

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

  try {
    const jwt = (req.headers.get('Authorization') ?? '').replace('Bearer ', '');
    if (!jwt) throw new Error('missing_auth');

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data: userData, error: userError } = await admin.auth.getUser(jwt);
    const user = userData?.user;
    if (userError || !user || !user.email) throw new Error('invalid_session');

    const { data: perfil } = await admin
      .from('profiles')
      .select('full_name')
      .eq('id', user.id)
      .maybeSingle();

    const token = crypto.randomUUID() + crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

    const { error: insertError } = await admin.from('email_verification_tokens').insert({
      user_id: user.id,
      token,
      expires_at: expiresAt,
    });
    if (insertError) throw insertError;

    const link = `${CONFIRM_URL_BASE}?token=${token}`;
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
      to: user.email,
      subject: 'Confirma tu cuenta – Mil Cositas',
      content: `Confirma tu cuenta en Mil Cositas visitando este enlace: ${link}\n\nSi no creaste esta cuenta, ignora este correo. El enlace expira en 24 horas.`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;">
          <h2>¡Hola, ${nombre}!</h2>
          <p>Gracias por registrarte en <strong>Mil Cositas</strong>. Confirma tu correo para activar tu cuenta:</p>
          <p style="text-align:center;margin:28px 0;">
            <a href="${link}" style="background:#1C1C1E;color:#fff;padding:14px 28px;border-radius:8px;text-decoration:none;font-weight:bold;">Confirmar mi cuenta</a>
          </p>
          <p style="color:#888;font-size:12px;">Si no creaste esta cuenta, ignora este correo. El enlace expira en 24 horas.</p>
        </div>
      `,
    });
    await client.close();

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: String((error as Error)?.message ?? error) }),
      { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } },
    );
  }
});
