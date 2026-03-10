-- ============================================================
-- FIX DEFINITIVO: Políticas sin recursión infinita
-- Ejecuta TODO esto de una vez en SQL Editor
-- ============================================================

-- 1. BORRAR todas las políticas problemáticas de profiles
DROP POLICY IF EXISTS "profiles_select_employees"      ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own"            ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own"            ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_admin"          ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_service_role"   ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete_super"          ON public.profiles;

-- 2. BORRAR funciones que causan recursión
DROP FUNCTION IF EXISTS public.is_admin()              CASCADE;
DROP FUNCTION IF EXISTS public.is_employee_or_above()  CASCADE;
DROP FUNCTION IF EXISTS public.current_user_role()     CASCADE;

-- 3. RECREAR funciones con SECURITY DEFINER + SET search_path
--    Esto hace que corran como superuser y NO activan RLS
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
    SELECT role::TEXT FROM public.profiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT COALESCE(
        (SELECT role IN ('admin', 'super_admin')
         FROM public.profiles
         WHERE id = auth.uid()
         LIMIT 1),
        FALSE
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_employee_or_above()
RETURNS BOOLEAN AS $$
    SELECT COALESCE(
        (SELECT role IN ('employee', 'admin', 'super_admin')
         FROM public.profiles
         WHERE id = auth.uid()
         LIMIT 1),
        FALSE
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- 4. NUEVAS políticas simples para profiles (sin recursión)
-- SELECT: cada quien ve su propio perfil; empleados/admin visibles para todos
CREATE POLICY "profiles_select"
    ON public.profiles FOR SELECT
    USING (
        auth.uid() = id
        OR role IN ('employee', 'admin', 'super_admin')
    );

-- INSERT: solo service_role (trigger) y admins
CREATE POLICY "profiles_insert"
    ON public.profiles FOR INSERT
    WITH CHECK (
        auth.uid() = id  -- el propio usuario al registrarse (fallback manual)
        OR public.is_admin()
    );

-- INSERT service_role (trigger on_auth_user_created)
CREATE POLICY "profiles_insert_trigger"
    ON public.profiles FOR INSERT
    TO service_role
    WITH CHECK (TRUE);

-- UPDATE: cada quien actualiza el suyo; admins actualizan cualquiera
CREATE POLICY "profiles_update"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id OR public.is_admin())
    WITH CHECK (auth.uid() = id OR public.is_admin());

-- DELETE: solo super_admin
CREATE POLICY "profiles_delete"
    ON public.profiles FOR DELETE
    USING (public.get_my_role() = 'super_admin');

-- ============================================================
-- ✅ Listo. Intenta registrarte de nuevo.
-- ============================================================
