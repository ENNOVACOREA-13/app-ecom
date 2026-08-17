// Estos valores se pueden sobreescribir en build time con --dart-define
// (Vercel los inyecta desde las Environment Variables del proyecto).
const kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://nvqdxrcoobojrfiuamwn.supabase.co',
);
const kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_WNKT_g8mC8Lnj5dsQlKaeg_AluHO4EM',
);

// Stripe — reemplaza con tu clave publicable de https://dashboard.stripe.com/apikeys
const kStripePublishableKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: 'pk_test_XXXXXXXXXXXXXXXXXXXXXXXX',
);

// Control plane multi-tenant: resuelve a qué proyecto de Supabase pertenece
// el dominio desde el que se sirve la app. Fijo en cada deploy (no cambia
// por tenant) — ver tenant_resolver.dart. Servidor: Hetzner (repo separado
// control_plane). Usa sslip.io (dominio gratis basado en la IP) mientras no
// haya un dominio propio — reemplazar cuando se compre uno.
const kControlPlaneUrl = String.fromEnvironment(
  'CONTROL_PLANE_URL',
  defaultValue: 'https://62-238-55-196.sslip.io',
);

const kAvatarBucket = 'avatars';
const kServicesBucket = 'services';
const kProductsBucket = 'products';

const kUrlLogoBarberia =
    'https://mc-barber-api.62-238-60-24.sslip.io/storage/v1/object/public/services/shop-logo.png';
