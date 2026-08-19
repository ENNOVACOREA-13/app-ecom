import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;
const MEDIA_URL_SECRET = Deno.env.get('MEDIA_URL_SECRET')!;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

// Firma un path del bucket `media` (tenantId/archivo.ext) para armar la URL
// permanente que se guarda en la base (logo_url, products.image_url, etc.)
// — ver media-proxy, que valida esta misma firma antes de servir el
// archivo. El bucket es privado (migración 20260819160000), así que sin
// esta función nadie puede generar una URL válida.
//
// La autorización reusa is_admin_or_sysadmin()/current_tenant_id() vía RPC
// (mandando el JWT del caller + x-tenant-id = primer segmento del path) en
// vez de reimplementar la lógica de membresías multi-tenant aquí — mismo
// criterio que ya valida la escritura real en storage.objects.
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

    const body = await req.json();
    const path = String(body.path ?? '').trim();
    const tenantId = path.split('/')[0];
    if (!path || !tenantId || path.split('/').length < 2) {
      return responder(400, { success: false, error: 'invalid_path' });
    }

    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${jwt}`, 'x-tenant-id': tenantId } },
    });

    const [esAdmin, miTenant] = await Promise.all([
      userClient.rpc('is_admin_or_sysadmin'),
      userClient.rpc('current_tenant_id'),
    ]);
    if (esAdmin.error || miTenant.error) throw esAdmin.error ?? miTenant.error;
    if (!esAdmin.data || miTenant.data !== tenantId) {
      return responder(403, { success: false, error: 'forbidden' });
    }

    const sig = await firmar(path);
    const url = `${SUPABASE_URL}/functions/v1/media-proxy?path=${encodeURIComponent(path)}&sig=${sig}`;
    return responder(200, { success: true, url });
  } catch (error) {
    return responder(500, { success: false, error: String((error as Error)?.message ?? error) });
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
