#!/bin/bash
set -e

git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter_sdk
export PATH="$PATH:$(pwd)/_flutter_sdk/bin"

flutter config --enable-web
flutter pub get

# Las Environment Variables se configuran en Vercel → Settings → Environment
# Variables. Si una no está definida se omite el --dart-define para que el
# valor por defecto del código (String.fromEnvironment) siga funcionando en
# vez de pisarlo con un string vacío.
DEFINES=()
[ -n "$SUPABASE_URL" ] && DEFINES+=(--dart-define=SUPABASE_URL="$SUPABASE_URL")
[ -n "$SUPABASE_ANON_KEY" ] && DEFINES+=(--dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY")
[ -n "$STRIPE_PUBLISHABLE_KEY" ] && DEFINES+=(--dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_PUBLISHABLE_KEY")


# --pwa-strategy=none: sin service worker cacheando el shell de la app.
# Esta app siempre necesita red (reservas, pagos, etc.), así que no hay
# beneficio real de soporte offline, y sí el costo de que los usuarios se
# queden atorados en una versión vieja hasta que el service worker decida
# actualizarse solo. Con esto, cada carga trae siempre el build más reciente.
flutter build web --release --pwa-strategy=none "${DEFINES[@]}"

# Páginas estáticas fuera de la app Flutter (enlaces de correo, políticas)
# — sin esto, Vercel no tiene el archivo físico en build/web/ y el rewrite
# catch-all de vercel.json ("/(.*)" -> "/index.html") sirve el shell de la
# app en su lugar. Como el dominio raíz prettycore.xyz no tiene tenant
# asignado, eso terminaba mandando a cualquiera que abriera estos enlaces
# al login del control plane en vez de a la página que debía cargar.
cp confirmar-cuenta.html build/web/confirmar-cuenta.html
cp restablecer-contrasena.html build/web/restablecer-contrasena.html
cp delete_account.html build/web/delete_account.html
cp privacy_policy.html build/web/privacy_policy.html
cp membresias.html build/web/membresias.html
