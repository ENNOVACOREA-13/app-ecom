import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const MEDIA_URL_SECRET = Deno.env.get('MEDIA_URL_SECRET')!;

// Función pública (sin verificación de JWT) — la cargan invitados sin
// sesión, igual que avatar-proxy. La única puerta es la firma HMAC (ver
// media-sign-url): sin ella nadie puede armar una URL válida para el
// bucket privado `media`, así que ya no hay forma de listar/adivinar
// imágenes de OTRO negocio (antes el bucket era público sin ninguna
// condición de carpeta — ver migración 20260819160000).
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

  try {
    const url = new URL(req.url);
    const path = url.searchParams.get('path');
    const sig = url.searchParams.get('sig');
    if (!path || !sig) throw new Error('missing_params');

    const esperada = await firmar(path);
    if (sig !== esperada) {
      return new Response('forbidden', { status: 403, headers: cors });
    }

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
    const { data, error } = await admin.storage.from('media').createSignedUrl(path, 60);
    if (error || !data) throw error ?? new Error('sign_failed');

    const upstream = await fetch(data.signedUrl);
    if (!upstream.ok) throw new Error(`upstream_${upstream.status}`);

    const bytes = await upstream.arrayBuffer();
    const contentType = upstream.headers.get('content-type') ?? 'application/octet-stream';
    return new Response(bytes, {
      headers: {
        ...cors,
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=31536000, immutable',
      },
    });
  } catch (error) {
    return new Response(String((error as Error)?.message ?? error), {
      status: 502,
      headers: cors,
    });
  }
});

async function firmar(path: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(MEDIA_URL_SECRET),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const firma = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(path));
  return Array.from(new Uint8Array(firma))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
