-- ============================================================
-- FIX: Permitir que el trigger cree perfiles al registrarse
-- ============================================================

-- 1. Política que permite al service_role insertar (el trigger lo usa)
CREATE POLICY "profiles_insert_service_role"
    ON public.profiles FOR INSERT
    TO service_role
    WITH CHECK (TRUE);

-- 2. Recrear la función con search_path explícito (fix de Supabase)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'client'::public.user_role)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ✅ Listo. Intenta registrarte de nuevo.
