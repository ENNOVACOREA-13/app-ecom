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
// por tenant) — ver tenant_resolver.dart. Reemplaza el defaultValue cuando
// el servidor del control plane esté desplegado (ver repo control_plane).
const kControlPlaneUrl = String.fromEnvironment(
  'CONTROL_PLANE_URL',
  defaultValue: 'https://control.TUDOMINIO.xyz',
);

const kAvatarBucket = 'avatars';
const kServicesBucket = 'services';
const kProductsBucket = 'products';

const kUrlLogoBarberia =
    'https://nvqdxrcoobojrfiuamwn.supabase.co/storage/v1/object/public/services/shop-logo.png';
