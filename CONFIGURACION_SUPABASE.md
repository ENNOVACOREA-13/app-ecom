# Configuración de Supabase para Barber App

## Paso 1: Obtener credenciales de Supabase

1. Ve a https://supabase.com y crea una cuenta (o inicia sesión)
2. Crea un nuevo proyecto
3. Ve a **Settings** > **API**
4. Copia:
   - **Project URL** (ejemplo: https://tu-proyecto.supabase.co)
   - **anon/public key** (es una clave larga que empieza con "eyJ...")

## Paso 2: Configurar credenciales en la app

Abre el archivo `lib/main.dart` y busca las líneas 31-38:

```dart
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'TU_SUPABASE_URL_AQUI', // ← Reemplazar aquí
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'TU_SUPABASE_ANON_KEY_AQUI', // ← Reemplazar aquí
);
```

**Reemplaza con tus credenciales:**

```dart
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://tu-proyecto.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
);
```

## Paso 3: Configurar Base de Datos

Ejecuta el siguiente SQL en Supabase SQL Editor:

```sql
-- 1. Crear tabla de perfiles
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'usuario',
  display_name TEXT,
  phone TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Habilitar Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 3. Políticas de seguridad
CREATE POLICY "Los usuarios pueden ver su propio perfil"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Los usuarios pueden actualizar su propio perfil"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

-- 4. Crear tabla de productos (para la tienda)
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  app_id TEXT NOT NULL,
  name TEXT NOT NULL,
  short_desc TEXT,
  image_url TEXT,
  price NUMERIC NOT NULL DEFAULT 0,
  stock INTEGER NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT true,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos pueden ver productos activos"
  ON products FOR SELECT
  USING (active = true);

-- 5. Crear vista de contexto actual
CREATE OR REPLACE VIEW v_current_context AS
SELECT
  auth.uid() as user_id,
  p.role,
  ARRAY['default']::text[] as app_ids
FROM profiles p
WHERE p.id = auth.uid();

-- 6. Función trigger para crear perfil automáticamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, display_name)
  VALUES (
    NEW.id,
    'usuario',
    COALESCE(NEW.email, 'Usuario')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Trigger para auto-crear perfil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

## Paso 4: Habilitar autenticación por email

1. Ve a **Authentication** > **Providers**
2. Habilita **Email** provider
3. Desactiva "Confirm email" si quieres hacer pruebas rápidas (opcional)

## Paso 5: Crear usuario de prueba

Opción A - Desde la app:
1. Ejecuta la app
2. Haz clic en "Crear cuenta"
3. Ingresa correo y contraseña

Opción B - Desde Supabase Dashboard:
1. Ve a **Authentication** > **Users**
2. Haz clic en "Add user"
3. Ingresa email y contraseña
4. El trigger creará automáticamente el perfil

## Verificación

Para verificar que todo funciona:

```sql
-- Ver usuarios
SELECT * FROM auth.users;

-- Ver perfiles
SELECT * FROM profiles;

-- Ver productos
SELECT * FROM products;
```

## Solución de problemas

### Error: "Invalid login credentials"
- Verifica que el usuario existe en la base de datos
- Verifica que la contraseña es correcta

### Error: "Error de configuración"
- Verifica que las credenciales en `main.dart` son correctas
- Verifica que el Project URL termina en `.supabase.co`
- Verifica que la anon key es la correcta (no uses la service_role key)

### Error: "Email not confirmed"
- Ve a Authentication > Settings > Email Auth
- Desactiva "Enable email confirmations" para desarrollo

### No aparecen productos
- Inserta algunos productos de prueba:

```sql
INSERT INTO products (app_id, name, price, stock, active)
VALUES
  ('default', 'Corte de cabello', 150, 100, true),
  ('Afeitado', 80, 100, true),
  ('Tinte', 250, 50, true);
```
