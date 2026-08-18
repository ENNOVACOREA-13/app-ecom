// Estos valores se pueden sobreescribir en build time con --dart-define
// (Vercel los inyecta desde las Environment Variables del proyecto).
//
// Desde la migración a multi-tenant compartido (2026-08-18), esta es la
// URL/key de UN SOLO proyecto Supabase Cloud que sirve a todos los
// tenants — ya no varía por dominio. Lo que sí varía por dominio es el
// tenant_id, resuelto en runtime por tenant_resolver.dart y mandado como
// header x-tenant-id (ver main.dart) para que RLS filtre por negocio.
const kSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://pzugebugnbrzgobruncg.supabase.co',
);
const kSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6dWdlYnVnbmJyemdvYnJ1bmNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODcwOTEyMzUsImV4cCI6MjEwMjY2NzIzNX0.qbwEi6XZ1DjhQH_4Kj_KIv-cP7Mvq3kn_6Tq7S01sv4',
);

// Stripe — reemplaza con tu clave publicable de https://dashboard.stripe.com/apikeys
const kStripePublishableKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: 'pk_test_XXXXXXXXXXXXXXXXXXXXXXXX',
);

/// tenant_id resuelto para el dominio actual (ver tenant_resolver.dart).
/// `main.dart` lo fija justo antes de `Supabase.initialize` y lo manda
/// como header x-tenant-id — auth_repository.dart lo usa también para
/// mandarlo en `raw_user_meta_data` al registrar un usuario nuevo, porque
/// handle_new_user() (SQL) exige un tenant_id válido para crear el
/// profile.
String? kTenantIdActivo;

const kAvatarBucket = 'avatars';
const kServicesBucket = 'services';
const kProductsBucket = 'products';

// TODO: el logo de splash sigue hardcodeado al de MC-BARBER — con más de
// un tenant esto debería salir de app_config por dominio, no ser un
// const global. Sigue funcionando hoy porque el Hetzner viejo de
// MC-BARBER se deja encendido (periodo de gracia) después del corte.
const kUrlLogoBarberia =
    'https://mc-barber-api.62-238-60-24.sslip.io/storage/v1/object/public/services/shop-logo.png';
