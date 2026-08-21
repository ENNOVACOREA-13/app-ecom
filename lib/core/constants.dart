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

// Sentry — captura errores no manejados en producción. Un DSN no es un
// secreto (está diseñado para ir embebido en clientes), así que es
// seguro tenerlo como default aquí igual que la anon key de Supabase.
const kSentryDsn = String.fromEnvironment(
  'SENTRY_DSN',
  defaultValue:
      'https://ce3314564da153d437ee943154c2d87b@o4511946542874624.ingest.us.sentry.io/4511946551656448',
);

/// tenant_id resuelto para el dominio actual (ver tenant_resolver.dart).
/// `main.dart` lo fija justo antes de `Supabase.initialize` y lo manda
/// como header x-tenant-id — auth_repository.dart lo usa también para
/// mandarlo en `raw_user_meta_data` al registrar un usuario nuevo, porque
/// handle_new_user() (SQL) exige un tenant_id válido para crear el
/// profile.
String? kTenantIdActivo;

// Sysadmin "de fábrica" de la plataforma: se siembra automáticamente en
// TODO negocio nuevo (trigger sembrar_sysadmin_principal(), migración
// 20260819150000) y la base rechaza cualquier intento de quitarle el
// acceso (trigger proteger_sysadmin_principal()) — este valor solo se usa
// para no mostrarle el botón de "quitar acceso" en el panel, que de
// cualquier forma fallaría contra la base.
const kEmailSysadminPrincipal = 'sysadmin@prettycore.xyz';

const kAvatarBucket = 'avatars';
const kServicesBucket = 'services';
const kProductsBucket = 'products';

// TODO: logo genérico mientras no hay branding por tenant en app_config —
// el Hetzner viejo de MC-BARBER que servía este logo ya no responde
// (dado de baja), así que usamos un asset local en vez de una URL muerta.
const kLogoBarberiaAsset = 'IMG/LOGOp.png';

// Wordmark "PRETTYCORE" (fondo negro incluido en el PNG) — marca de la
// plataforma, para el login y el panel del control plane, nunca para un
// negocio individual.
const kLogoPrettycoreAsset = 'IMG/LOGO_MENU.png';
