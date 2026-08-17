// Proxy server-a-servidor hacia DiceBear: el navegador del cliente nunca le
// pega directo a api.dicebear.com (evita que Tracking Prevention de Edge/
// Safari/Firefox bloquee la imagen por ser un dominio de terceros).
// Función pública (sin verificación de JWT) — solo sirve una imagen.
const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, content-type, apikey',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });

  try {
    const url = new URL(req.url);
    const seed = url.searchParams.get('seed');
    const size = url.searchParams.get('size') ?? '128';
    const estilo = url.searchParams.get('style') ?? 'adventurer-neutral';
    if (!seed) throw new Error('missing_seed');

    const upstream = await fetch(
      `https://api.dicebear.com/10.x/${encodeURIComponent(estilo)}/png?seed=${encodeURIComponent(seed)}&size=${encodeURIComponent(size)}`,
    );
    if (!upstream.ok) throw new Error(`upstream_${upstream.status}`);

    const bytes = await upstream.arrayBuffer();
    return new Response(bytes, {
      headers: {
        ...cors,
        'Content-Type': 'image/png',
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
