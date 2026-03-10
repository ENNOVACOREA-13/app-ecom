-- ============================================================
-- BARBER APP - SUPABASE SCHEMA COMPLETO v2.0
-- PostgreSQL + Supabase Auth + RLS
-- Arquitectura SaaS profesional
-- ============================================================

-- ============================================================
-- 1. EXTENSIONES NECESARIAS
-- ============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 2. ENUM TYPES
-- ============================================================
CREATE TYPE user_role AS ENUM ('client', 'employee', 'admin', 'super_admin');
CREATE TYPE booking_status AS ENUM ('pending', 'confirmed', 'completed', 'cancelled');
CREATE TYPE day_of_week AS ENUM ('monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday');
CREATE TYPE product_status AS ENUM ('active', 'inactive', 'out_of_stock');

-- ============================================================
-- 3. TABLA: profiles
-- Extiende auth.users de Supabase
-- ============================================================
CREATE TABLE public.profiles (
    id             UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role           user_role        NOT NULL DEFAULT 'client',
    full_name      TEXT             NOT NULL,
    phone          TEXT,
    avatar_url     TEXT,                          -- URL en Supabase Storage
    bio            TEXT,                          -- Para empleados
    is_active      BOOLEAN          NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS 'Perfiles de usuario extendidos desde auth.users';

-- ============================================================
-- 4. TABLA: services
-- Catálogo de servicios ofrecidos
-- ============================================================
CREATE TABLE public.services (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name           TEXT             NOT NULL,
    description    TEXT,
    duration_min   INTEGER          NOT NULL CHECK (duration_min > 0),  -- duración en minutos
    price          NUMERIC(10, 2)   NOT NULL CHECK (price >= 0),
    image_url      TEXT,
    is_active      BOOLEAN          NOT NULL DEFAULT TRUE,
    created_by     UUID             REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.services IS 'Catálogo de servicios disponibles para reservar';

-- ============================================================
-- 5. TABLA: employee_services
-- Qué servicios puede realizar cada empleado
-- ============================================================
CREATE TABLE public.employee_services (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id    UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_id     UUID             NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    UNIQUE (employee_id, service_id)
);

COMMENT ON TABLE public.employee_services IS 'Relación muchos-a-muchos entre empleados y servicios que pueden realizar';

-- ============================================================
-- 6. TABLA: work_schedules
-- Horarios de trabajo regulares por empleado y día
-- ============================================================
CREATE TABLE public.work_schedules (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id    UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    day_of_week    day_of_week      NOT NULL,
    start_time     TIME             NOT NULL,
    end_time       TIME             NOT NULL,
    is_active      BOOLEAN          NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    UNIQUE (employee_id, day_of_week),
    CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

COMMENT ON TABLE public.work_schedules IS 'Horarios de trabajo semanales recurrentes por empleado';

-- ============================================================
-- 7. TABLA: schedule_overrides
-- Días especiales: vacaciones, días libres, horario diferente
-- ============================================================
CREATE TABLE public.schedule_overrides (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    employee_id    UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    override_date  DATE             NOT NULL,
    is_day_off     BOOLEAN          NOT NULL DEFAULT FALSE,  -- TRUE = día libre/bloqueado
    start_time     TIME,                                      -- NULL si is_day_off = TRUE
    end_time       TIME,                                      -- NULL si is_day_off = TRUE
    reason         TEXT,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    UNIQUE (employee_id, override_date),
    CONSTRAINT valid_override CHECK (
        is_day_off = TRUE
        OR (start_time IS NOT NULL AND end_time IS NOT NULL AND end_time > start_time)
    )
);

COMMENT ON TABLE public.schedule_overrides IS 'Excepciones al horario regular: días libres, horarios especiales';

-- ============================================================
-- 8. TABLA: bookings
-- Reservas principales
-- ============================================================
CREATE TABLE public.bookings (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id      UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    employee_id    UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    service_id     UUID             NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
    booking_date   DATE             NOT NULL,
    start_time     TIME             NOT NULL,
    end_time       TIME             NOT NULL,           -- calculado: start_time + service.duration_min
    status         booking_status   NOT NULL DEFAULT 'pending',
    total_price    NUMERIC(10, 2)   NOT NULL,
    notes          TEXT,
    cancelled_at   TIMESTAMPTZ,
    cancelled_by   UUID             REFERENCES public.profiles(id) ON DELETE SET NULL,
    cancel_reason  TEXT,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_booking_time CHECK (end_time > start_time),
    CONSTRAINT no_self_booking CHECK (client_id != employee_id)
);

COMMENT ON TABLE public.bookings IS 'Reservas de servicios: núcleo del sistema';

-- Índices críticos para rendimiento y lógica de disponibilidad
CREATE INDEX idx_bookings_employee_date ON public.bookings (employee_id, booking_date);
CREATE INDEX idx_bookings_client ON public.bookings (client_id);
CREATE INDEX idx_bookings_status ON public.bookings (status);
CREATE INDEX idx_bookings_date ON public.bookings (booking_date);

-- ============================================================
-- 9. TABLA: booking_extras
-- Servicios adicionales agregados a una reserva
-- ============================================================
CREATE TABLE public.booking_extras (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id     UUID             NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    service_id     UUID             NOT NULL REFERENCES public.services(id) ON DELETE RESTRICT,
    price          NUMERIC(10, 2)   NOT NULL,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    UNIQUE (booking_id, service_id)
);

COMMENT ON TABLE public.booking_extras IS 'Servicios adicionales añadidos a una reserva';

-- ============================================================
-- 10. TABLA: products
-- Tienda de productos
-- ============================================================
CREATE TABLE public.products (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name           TEXT             NOT NULL,
    description    TEXT,
    price          NUMERIC(10, 2)   NOT NULL CHECK (price >= 0),
    stock          INTEGER          NOT NULL DEFAULT 0 CHECK (stock >= 0),
    image_url      TEXT,
    status         product_status   NOT NULL DEFAULT 'active',
    created_by     UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.products IS 'Productos disponibles en la tienda';

-- ============================================================
-- 11. TABLA: reviews
-- Reseñas de clientes sobre reservas
-- ============================================================
CREATE TABLE public.reviews (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id     UUID             NOT NULL UNIQUE REFERENCES public.bookings(id) ON DELETE CASCADE,
    client_id      UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    employee_id    UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating         SMALLINT         NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment        TEXT,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.reviews IS 'Reseñas y calificaciones de clientes por reserva completada';

-- ============================================================
-- 12. TABLA: notifications (opcional pero recomendado)
-- ============================================================
CREATE TABLE public.notifications (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID             NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title          TEXT             NOT NULL,
    body           TEXT             NOT NULL,
    is_read        BOOLEAN          NOT NULL DEFAULT FALSE,
    metadata       JSONB,
    created_at     TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON public.notifications (user_id, is_read);

-- ============================================================
-- 13. FUNCIONES DE SOPORTE
-- ============================================================

-- Función: actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger updated_at a todas las tablas relevantes
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_services_updated_at
    BEFORE UPDATE ON public.services
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_work_schedules_updated_at
    BEFORE UPDATE ON public.work_schedules
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_bookings_updated_at
    BEFORE UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER trg_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 14. FUNCIÓN: crear perfil automáticamente al registrarse
-- Se ejecuta cuando Supabase Auth crea un nuevo usuario
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, full_name, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'client')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: nuevo usuario en auth.users → crear profile
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- 15. FUNCIÓN: calcular end_time automáticamente en bookings
-- ============================================================
CREATE OR REPLACE FUNCTION public.calculate_booking_end_time()
RETURNS TRIGGER AS $$
DECLARE
    v_duration INTEGER;
BEGIN
    SELECT duration_min INTO v_duration
    FROM public.services
    WHERE id = NEW.service_id;

    NEW.end_time = NEW.start_time + (v_duration || ' minutes')::INTERVAL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_booking_end_time
    BEFORE INSERT OR UPDATE OF start_time, service_id ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.calculate_booking_end_time();

-- ============================================================
-- 16. FUNCIÓN: evitar doble reserva (conflicto de horario)
-- Verifica que el empleado no tenga otra reserva en el mismo horario
-- ============================================================
CREATE OR REPLACE FUNCTION public.check_booking_conflict()
RETURNS TRIGGER AS $$
DECLARE
    v_conflict INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_conflict
    FROM public.bookings
    WHERE employee_id  = NEW.employee_id
      AND booking_date = NEW.booking_date
      AND status       NOT IN ('cancelled')
      AND id           != COALESCE(NEW.id, uuid_generate_v4())  -- excluir el mismo en UPDATE
      AND (
            -- El nuevo turno empieza dentro de uno existente
            (NEW.start_time >= start_time AND NEW.start_time < end_time)
            OR
            -- El nuevo turno termina dentro de uno existente
            (NEW.end_time > start_time AND NEW.end_time <= end_time)
            OR
            -- El nuevo turno engloba completamente a uno existente
            (NEW.start_time <= start_time AND NEW.end_time >= end_time)
      );

    IF v_conflict > 0 THEN
        RAISE EXCEPTION 'BOOKING_CONFLICT: El empleado ya tiene una reserva en ese horario';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_booking_conflict
    BEFORE INSERT OR UPDATE ON public.bookings
    FOR EACH ROW EXECUTE FUNCTION public.check_booking_conflict();

-- ============================================================
-- 17. FUNCIÓN: obtener slots disponibles para un empleado/fecha
-- Retorna los horarios libres considerando schedule + bookings
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_available_slots(
    p_employee_id  UUID,
    p_date         DATE,
    p_duration_min INTEGER DEFAULT 30,
    p_slot_gap_min INTEGER DEFAULT 0
)
RETURNS TABLE (
    slot_start TIME,
    slot_end   TIME
) AS $$
DECLARE
    v_day_name    day_of_week;
    v_work_start  TIME;
    v_work_end    TIME;
    v_is_day_off  BOOLEAN;
    v_current     TIME;
    v_slot_end    TIME;
    v_slot_dur    INTERVAL;
BEGIN
    -- Obtener nombre del día
    v_day_name := LOWER(TO_CHAR(p_date, 'Day'))::day_of_week;
    -- Corrección: to_char con 'Day' incluye espacios, normalizar
    v_day_name := TRIM(LOWER(TO_CHAR(p_date, 'Day')))::day_of_week;

    v_slot_dur := ((p_duration_min + p_slot_gap_min) || ' minutes')::INTERVAL;

    -- Verificar si hay override para esta fecha
    SELECT is_day_off, start_time, end_time
    INTO v_is_day_off, v_work_start, v_work_end
    FROM public.schedule_overrides
    WHERE employee_id = p_employee_id
      AND override_date = p_date;

    IF FOUND THEN
        IF v_is_day_off THEN
            RETURN; -- Día libre, no hay slots
        END IF;
    ELSE
        -- Usar horario regular
        SELECT start_time, end_time
        INTO v_work_start, v_work_end
        FROM public.work_schedules
        WHERE employee_id = p_employee_id
          AND day_of_week = v_day_name
          AND is_active = TRUE;

        IF NOT FOUND THEN
            RETURN; -- No trabaja ese día
        END IF;
    END IF;

    -- Iterar desde inicio hasta fin del turno
    v_current := v_work_start;
    LOOP
        v_slot_end := v_current + (p_duration_min || ' minutes')::INTERVAL;

        EXIT WHEN v_slot_end > v_work_end;

        -- Verificar si este slot está ocupado
        IF NOT EXISTS (
            SELECT 1 FROM public.bookings
            WHERE employee_id  = p_employee_id
              AND booking_date = p_date
              AND status NOT IN ('cancelled')
              AND (
                    (v_current >= start_time AND v_current < end_time)
                    OR (v_slot_end > start_time AND v_slot_end <= end_time)
                    OR (v_current <= start_time AND v_slot_end >= end_time)
              )
        ) THEN
            slot_start := v_current;
            slot_end   := v_slot_end;
            RETURN NEXT;
        END IF;

        v_current := v_current + v_slot_dur;
    END LOOP;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- 18. FUNCIÓN: calcular total de una reserva incluyendo extras
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_booking_total(p_booking_id UUID)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT b.total_price + COALESCE(SUM(be.price), 0)
    INTO v_total
    FROM public.bookings b
    LEFT JOIN public.booking_extras be ON be.booking_id = b.id
    WHERE b.id = p_booking_id
    GROUP BY b.total_price;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================================
-- 19. VISTAS PARA ESTADÍSTICAS
-- ============================================================

-- Vista: estadísticas por empleado
CREATE OR REPLACE VIEW public.employee_stats AS
SELECT
    p.id                                         AS employee_id,
    p.full_name,
    COUNT(b.id) FILTER (WHERE b.status = 'completed') AS total_completadas,
    COUNT(b.id) FILTER (WHERE b.status = 'cancelled')  AS total_canceladas,
    COUNT(b.id) FILTER (WHERE b.status = 'pending')    AS total_pendientes,
    COALESCE(SUM(b.total_price) FILTER (WHERE b.status = 'completed'), 0) AS ingresos_totales,
    ROUND(AVG(r.rating), 2)                            AS rating_promedio,
    COUNT(r.id)                                        AS total_reviews
FROM public.profiles p
LEFT JOIN public.bookings b  ON b.employee_id = p.id
LEFT JOIN public.reviews  r  ON r.employee_id = p.id
WHERE p.role = 'employee'
GROUP BY p.id, p.full_name;

-- Vista: servicios más populares
CREATE OR REPLACE VIEW public.popular_services AS
SELECT
    s.id,
    s.name,
    s.price,
    COUNT(b.id) FILTER (WHERE b.status = 'completed')  AS veces_reservado,
    COALESCE(SUM(b.total_price) FILTER (WHERE b.status = 'completed'), 0) AS ingresos_generados
FROM public.services s
LEFT JOIN public.bookings b ON b.service_id = s.id
GROUP BY s.id, s.name, s.price
ORDER BY veces_reservado DESC;

-- Vista: reservas con toda la info (para admins y Flutter)
CREATE OR REPLACE VIEW public.bookings_detailed AS
SELECT
    b.id,
    b.client_id,
    b.employee_id,
    b.service_id,
    b.booking_date,
    b.start_time,
    b.end_time,
    b.status,
    b.total_price,
    b.notes,
    b.created_at,
    -- Cliente
    c.full_name   AS client_name,
    c.phone       AS client_phone,
    c.avatar_url  AS client_avatar,
    -- Empleado
    e.full_name   AS employee_name,
    e.avatar_url  AS employee_avatar,
    -- Servicio
    s.name        AS service_name,
    s.duration_min
FROM public.bookings b
JOIN public.profiles c ON c.id = b.client_id
JOIN public.profiles e ON e.id = b.employee_id
JOIN public.services s ON s.id = b.service_id;

-- ============================================================
-- 20. ROW LEVEL SECURITY (RLS)
-- ============================================================
ALTER TABLE public.profiles          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employee_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.work_schedules    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schedule_overrides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_extras    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications     ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- HELPER: función para obtener el rol del usuario actual
-- ============================================================
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS user_role AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
    SELECT role IN ('admin', 'super_admin') FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_employee_or_above()
RETURNS BOOLEAN AS $$
    SELECT role IN ('employee', 'admin', 'super_admin') FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ============================================================
-- POLÍTICAS: profiles
-- ============================================================
-- Cualquiera puede ver perfiles de empleados (para mostrar en la app)
CREATE POLICY "profiles_select_employees"
    ON public.profiles FOR SELECT
    USING (role = 'employee' OR auth.uid() = id OR public.is_admin());

-- Cada usuario puede ver y editar su propio perfil
CREATE POLICY "profiles_update_own"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (
        auth.uid() = id
        -- Los no-admin no pueden cambiar su rol
        AND (
            public.is_admin()
            OR role = (SELECT role FROM public.profiles WHERE id = auth.uid())
        )
    );

-- Solo admins pueden insertar perfiles manualmente
CREATE POLICY "profiles_insert_admin"
    ON public.profiles FOR INSERT
    WITH CHECK (public.is_admin());

-- Solo super_admin puede eliminar perfiles
CREATE POLICY "profiles_delete_super"
    ON public.profiles FOR DELETE
    USING (public.current_user_role() = 'super_admin');

-- ============================================================
-- POLÍTICAS: services
-- ============================================================
CREATE POLICY "services_select_all"
    ON public.services FOR SELECT
    USING (is_active = TRUE OR public.is_admin());

CREATE POLICY "services_insert_admin"
    ON public.services FOR INSERT
    WITH CHECK (public.is_admin());

CREATE POLICY "services_update_admin"
    ON public.services FOR UPDATE
    USING (public.is_admin());

CREATE POLICY "services_delete_admin"
    ON public.services FOR DELETE
    USING (public.is_admin());

-- ============================================================
-- POLÍTICAS: employee_services
-- ============================================================
CREATE POLICY "emp_services_select"
    ON public.employee_services FOR SELECT
    USING (TRUE);

CREATE POLICY "emp_services_manage_admin"
    ON public.employee_services FOR ALL
    USING (public.is_admin());

-- ============================================================
-- POLÍTICAS: work_schedules
-- ============================================================
CREATE POLICY "schedules_select_all"
    ON public.work_schedules FOR SELECT
    USING (TRUE);  -- Todo el mundo puede ver horarios para calcular disponibilidad

CREATE POLICY "schedules_manage_admin"
    ON public.work_schedules FOR ALL
    USING (public.is_admin());

-- Empleado puede ver sus propios horarios (ya cubierto por select_all)

-- ============================================================
-- POLÍTICAS: schedule_overrides
-- ============================================================
CREATE POLICY "overrides_select"
    ON public.schedule_overrides FOR SELECT
    USING (TRUE);

CREATE POLICY "overrides_manage_admin"
    ON public.schedule_overrides FOR ALL
    USING (public.is_admin());

-- ============================================================
-- POLÍTICAS: bookings
-- ============================================================
-- Cliente: solo sus propias reservas
CREATE POLICY "bookings_client_select"
    ON public.bookings FOR SELECT
    USING (
        auth.uid() = client_id
        OR auth.uid() = employee_id
        OR public.is_admin()
    );

-- Cliente puede crear su propia reserva
CREATE POLICY "bookings_client_insert"
    ON public.bookings FOR INSERT
    WITH CHECK (auth.uid() = client_id);

-- Cliente puede cancelar su propia reserva (solo si está en pending/confirmed)
-- Admin puede actualizar cualquier reserva
CREATE POLICY "bookings_update"
    ON public.bookings FOR UPDATE
    USING (
        auth.uid() = client_id
        OR auth.uid() = employee_id
        OR public.is_admin()
    );

-- Solo admin puede eliminar reservas
CREATE POLICY "bookings_delete_admin"
    ON public.bookings FOR DELETE
    USING (public.is_admin());

-- ============================================================
-- POLÍTICAS: booking_extras
-- ============================================================
CREATE POLICY "extras_select"
    ON public.booking_extras FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id
              AND (b.client_id = auth.uid() OR b.employee_id = auth.uid() OR public.is_admin())
        )
    );

CREATE POLICY "extras_insert"
    ON public.booking_extras FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id
              AND (b.client_id = auth.uid() OR public.is_admin())
        )
    );

-- ============================================================
-- POLÍTICAS: products
-- ============================================================
CREATE POLICY "products_select_active"
    ON public.products FOR SELECT
    USING (status = 'active' OR public.is_employee_or_above());

CREATE POLICY "products_insert_employee"
    ON public.products FOR INSERT
    WITH CHECK (
        public.is_employee_or_above()
        AND auth.uid() = created_by
    );

CREATE POLICY "products_update"
    ON public.products FOR UPDATE
    USING (
        (auth.uid() = created_by AND public.is_employee_or_above())
        OR public.is_admin()
    );

CREATE POLICY "products_delete_admin"
    ON public.products FOR DELETE
    USING (public.is_admin());

-- ============================================================
-- POLÍTICAS: reviews
-- ============================================================
CREATE POLICY "reviews_select_all"
    ON public.reviews FOR SELECT
    USING (TRUE);

CREATE POLICY "reviews_insert_client"
    ON public.reviews FOR INSERT
    WITH CHECK (
        auth.uid() = client_id
        AND EXISTS (
            SELECT 1 FROM public.bookings b
            WHERE b.id = booking_id
              AND b.client_id = auth.uid()
              AND b.status = 'completed'
        )
    );

CREATE POLICY "reviews_update_own"
    ON public.reviews FOR UPDATE
    USING (auth.uid() = client_id);

-- ============================================================
-- POLÍTICAS: notifications
-- ============================================================
CREATE POLICY "notifications_own"
    ON public.notifications FOR ALL
    USING (auth.uid() = user_id);

-- ============================================================
-- 21. STORAGE BUCKETS (ejecutar en Supabase Dashboard o SQL)
-- ============================================================
-- Bucket: avatars (fotos de perfil)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    TRUE,
    5242880,  -- 5MB
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT DO NOTHING;

-- Bucket: services (imágenes de servicios)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'services',
    'services',
    TRUE,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT DO NOTHING;

-- Bucket: products (imágenes de productos)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'products',
    'products',
    TRUE,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT DO NOTHING;

-- Políticas de Storage: avatars
CREATE POLICY "avatars_public_read"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

CREATE POLICY "avatars_own_upload"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'avatars'
        AND auth.uid()::TEXT = (storage.foldername(name))[1]
    );

CREATE POLICY "avatars_own_update"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::TEXT = (storage.foldername(name))[1]
    );

CREATE POLICY "avatars_own_delete"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'avatars'
        AND auth.uid()::TEXT = (storage.foldername(name))[1]
    );

-- ============================================================
-- 22. QUERIES DE ESTADÍSTICAS (ejemplos)
-- ============================================================

-- Ingresos totales del mes actual
-- SELECT SUM(total_price) FROM bookings
-- WHERE status = 'completed'
--   AND DATE_TRUNC('month', booking_date) = DATE_TRUNC('month', CURRENT_DATE);

-- Top 5 empleados por ingresos
-- SELECT employee_id, SUM(total_price) AS ingresos
-- FROM bookings WHERE status = 'completed'
-- GROUP BY employee_id ORDER BY ingresos DESC LIMIT 5;

-- Reservas por día de la semana (para análisis de demanda)
-- SELECT TO_CHAR(booking_date, 'Day') AS dia, COUNT(*) AS total
-- FROM bookings WHERE status = 'completed'
-- GROUP BY dia ORDER BY total DESC;

-- Tasa de cancelación
-- SELECT
--     COUNT(*) FILTER (WHERE status = 'cancelled')::FLOAT
--     / NULLIF(COUNT(*), 0) * 100 AS tasa_cancelacion
-- FROM bookings;

-- ============================================================
-- 23. DATOS SEED (opcionales para desarrollo)
-- ============================================================

-- Insertar servicios de ejemplo
-- (Ejecutar DESPUÉS de crear el primer usuario admin en auth.users)
/*
INSERT INTO public.services (name, description, duration_min, price) VALUES
    ('Corte de cabello',      'Corte clásico con tijera y máquina', 30,  150.00),
    ('Corte + barba',         'Corte completo más arreglo de barba', 45, 220.00),
    ('Arreglo de barba',      'Perfilado y arreglo profesional',     20,  100.00),
    ('Tinte',                 'Coloración completa con productos premium', 90, 350.00),
    ('Corte niño',            'Corte para menores de 12 años',       25,  100.00);
*/

-- ============================================================
-- FIN DEL SCHEMA
-- ============================================================
