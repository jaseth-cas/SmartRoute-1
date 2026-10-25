-- ==============================================================
-- MIGRACIÓN: POLÍTICAS RLS HÍBRIDAS (AUTENTICADOS + ANON / DEMO)
-- Permite que las operaciones de cabina, abordaje y reporte de incidentes
-- funcionen de forma consistente en entorno local, demos y producción.
-- ==============================================================

-- 1. Incidentes de Ruta
DROP POLICY IF EXISTS "Conductores pueden registrar incidentes" ON public.incidentes_ruta;
DROP POLICY IF EXISTS "Permitir lectura de incidentes a usuarios autenticados" ON public.incidentes_ruta;
DROP POLICY IF EXISTS "incidentes_select_policy" ON public.incidentes_ruta;
DROP POLICY IF EXISTS "incidentes_insert_policy" ON public.incidentes_ruta;

CREATE POLICY "incidentes_select_policy"
    ON public.incidentes_ruta FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "incidentes_insert_policy"
    ON public.incidentes_ruta FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

-- 2. Notificaciones Escolares
DROP POLICY IF EXISTS "Usuarios pueden ver sus propias notificaciones o alertas generales" ON public.notificaciones;
DROP POLICY IF EXISTS "Usuarios autenticados pueden crear notificaciones" ON public.notificaciones;
DROP POLICY IF EXISTS "Usuarios pueden marcar sus notificaciones como leídas" ON public.notificaciones;
DROP POLICY IF EXISTS "notificaciones_select_policy" ON public.notificaciones;
DROP POLICY IF EXISTS "notificaciones_insert_policy" ON public.notificaciones;
DROP POLICY IF EXISTS "notificaciones_update_policy" ON public.notificaciones;

CREATE POLICY "notificaciones_select_policy"
    ON public.notificaciones FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "notificaciones_insert_policy"
    ON public.notificaciones FOR INSERT
    TO anon, authenticated
    WITH CHECK (true);

CREATE POLICY "notificaciones_update_policy"
    ON public.notificaciones FOR UPDATE
    TO anon, authenticated
    USING (true);

-- 3. Asistencia Diaria
DROP POLICY IF EXISTS "Permitir lectura y modificación de asistencia a autenticados" ON public.asistencia_diaria;
DROP POLICY IF EXISTS "asistencia_all_policy" ON public.asistencia_diaria;

CREATE POLICY "asistencia_all_policy"
    ON public.asistencia_diaria FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- 4. Autobuses Escolares
DROP POLICY IF EXISTS "Permitir lectura de autobuses a todos los autenticados" ON public.autobuses;
DROP POLICY IF EXISTS "Transportistas pueden crear y actualizar sus propios autobuses" ON public.autobuses;
DROP POLICY IF EXISTS "autobuses_select_policy" ON public.autobuses;
DROP POLICY IF EXISTS "autobuses_all_policy" ON public.autobuses;

CREATE POLICY "autobuses_select_policy"
    ON public.autobuses FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY "autobuses_all_policy"
    ON public.autobuses FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- 5. Estudiantes Pasajeros
DROP POLICY IF EXISTS "Lectura de estudiantes para usuarios autorizados" ON public.estudiantes_pasajeros;
DROP POLICY IF EXISTS "estudiantes_all_policy" ON public.estudiantes_pasajeros;

CREATE POLICY "estudiantes_all_policy"
    ON public.estudiantes_pasajeros FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- 6. Paradas de Ruta
DROP POLICY IF EXISTS "Lectura de paradas a autenticados" ON public.paradas_ruta;
DROP POLICY IF EXISTS "paradas_select_policy" ON public.paradas_ruta;

CREATE POLICY "paradas_select_policy"
    ON public.paradas_ruta FOR SELECT
    TO anon, authenticated
    USING (true);
