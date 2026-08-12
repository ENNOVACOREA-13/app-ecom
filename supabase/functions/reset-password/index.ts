import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

// Función pública (sin verificación de JWT): la llama la página estática de
// restablecimiento, sin sesión iniciada. Desplegar con --no-verify-jwt.
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

  try {
    const { token, new_password } = await req.json();
    if (!token) throw new Error('missing_token');
    if (!new_password || String(new_password).length < 6) throw new Error('weak_password');

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    const { data: fila, error } = await admin
      .from('password_reset_tokens')
      .select('user_id, expires_at, used')
      .eq('token', token)
      .maybeSingle();

    if (error || !fila) throw new Error('invalid_token');
    if (fila.used) throw new Error('token_already_used');
    if (new Date(fila.expires_at as string).getTime() < Date.now()) throw new Error('token_expired');

    const { error: updateError } = await admin.auth.admin.updateUserById(fila.user_id as string, {
      password: new_password,
    });
    if (updateError) throw updateError;

    await admin.from('password_reset_tokens').update({ used: true }).eq('token', token);

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
