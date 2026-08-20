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
      .select('user_id, tenant_id, expires_at, used')
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

    // El correo/contraseña ya quedaron bien, pero si la persona intenta
    // iniciar sesión en un dominio que no es el de SU negocio, la app la
    // rechaza con el mismo mensaje que una contraseña incorrecta (a
    // propósito, para no filtrar en qué negocio existe una cuenta — ver
    // RepositorioAuth.iniciarSesion). Sin decirle a qué dominio ir, parece
    // que el cambio de contraseña no funcionó. Se manda el dominio de su
    // negocio para que la página de éxito pueda enlazarlo directamente.
    let dominio: string | null = null;
    if (fila.tenant_id) {
      const { data: filaDominio } = await admin
        .from('tenant_domains')
        .select('domain')
        .eq('tenant_id', fila.tenant_id as string)
        .limit(1)
        .maybeSingle();
      dominio = (filaDominio?.domain as string | undefined) ?? null;
    }

    return new Response(JSON.stringify({ success: true, domain: dominio }), {
      headers: { ...cors, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: String((error as Error)?.message ?? error) }),
      { status: 400, headers: { ...cors, 'Content-Type': 'application/json' } },
    );
  }
});
