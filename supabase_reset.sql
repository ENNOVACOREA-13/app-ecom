-- ============================================================
-- RESET TOTAL DE LA BASE DE DATOS
-- ⚠️  EJECUTA ESTO PRIMERO, luego supabase_schema_v2.sql
-- Borra tablas, vistas, funciones, triggers y tipos del schema
-- ============================================================

-- 1. ELIMINAR VISTAS
DROP VIEW IF EXISTS public.bookings_detailed   CASCADE;
DROP VIEW IF EXISTS public.employee_stats      CASCADE;
DROP VIEW IF EXISTS public.popular_services    CASCADE;

-- 2. ELIMINAR TABLAS (en orden para respetar FK)
DROP TABLE IF EXISTS public.notifications      CASCADE;
DROP TABLE IF EXISTS public.reviews            CASCADE;
DROP TABLE IF EXISTS public.booking_extras     CASCADE;
DROP TABLE IF EXISTS public.bookings           CASCADE;
DROP TABLE IF EXISTS public.schedule_overrides CASCADE;
DROP TABLE IF EXISTS public.work_schedules     CASCADE;
DROP TABLE IF EXISTS public.employee_services  CASCADE;
DROP TABLE IF EXISTS public.products           CASCADE;
DROP TABLE IF EXISTS public.services           CASCADE;
DROP TABLE IF EXISTS public.profiles           CASCADE;

-- Tablas del schema viejo (por si existen)
DROP TABLE IF EXISTS public.reservations       CASCADE;
DROP TABLE IF EXISTS public.employees          CASCADE;
DROP TABLE IF EXISTS public.business_hours     CASCADE;
DROP TABLE IF EXISTS public.categories         CASCADE;
DROP TABLE IF EXISTS public.orders             CASCADE;
DROP TABLE IF EXISTS public.order_items        CASCADE;
DROP TABLE IF EXISTS public.inventory          CASCADE;
DROP TABLE IF EXISTS public.app_config         CASCADE;
DROP TABLE IF EXISTS public.permissions        CASCADE;

-- 3. ELIMINAR FUNCIONES
DROP FUNCTION IF EXISTS public.handle_updated_at()         CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user()           CASCADE;
DROP FUNCTION IF EXISTS public.calculate_booking_end_time() CASCADE;
DROP FUNCTION IF EXISTS public.check_booking_conflict()    CASCADE;
DROP FUNCTION IF EXISTS public.get_available_slots(UUID, DATE, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_available_slots(UUID, DATE, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.get_booking_total(UUID)     CASCADE;
DROP FUNCTION IF EXISTS public.current_user_role()         CASCADE;
DROP FUNCTION IF EXISTS public.is_admin()                  CASCADE;
DROP FUNCTION IF EXISTS public.is_employee_or_above()      CASCADE;

-- Funciones del schema viejo
DROP FUNCTION IF EXISTS public.get_my_role()               CASCADE;
DROP FUNCTION IF EXISTS public.sbselect(TEXT, JSONB)       CASCADE;

-- 4. ELIMINAR TIPOS ENUM
DROP TYPE IF EXISTS public.user_role       CASCADE;
DROP TYPE IF EXISTS public.booking_status  CASCADE;
DROP TYPE IF EXISTS public.day_of_week     CASCADE;
DROP TYPE IF EXISTS public.product_status  CASCADE;

-- 5. ELIMINAR TRIGGER del schema de auth (se recrea solo)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 6. STORAGE BUCKETS
-- No se pueden borrar por SQL directo (Supabase lo protege).
-- Si quieres borrarlos: Dashboard → Storage → selecciona el bucket → Delete

-- ============================================================
-- ✅ Listo. Ahora ejecuta supabase_schema_v2.sql
-- ============================================================
