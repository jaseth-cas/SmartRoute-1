-- ==============================================================
-- MIGRACIÓN: COORDENADAS EXACTAS DE RECOGIDA EN ESTUDIANTES Y RLS PARADAS
-- ==============================================================

alter table public.estudiantes_pasajeros
    add column if not exists latitud_recogida double precision,
    add column if not exists longitud_recogida double precision;

-- Permitir INSERT y UPDATE en paradas_ruta y estudiantes_pasajeros para sincronizar ubicaciones GPS
DROP POLICY IF EXISTS "paradas_select_policy" ON public.paradas_ruta;
DROP POLICY IF EXISTS "paradas_all_policy" ON public.paradas_ruta;

CREATE POLICY "paradas_all_policy"
    ON public.paradas_ruta FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "estudiantes_all_policy" ON public.estudiantes_pasajeros;
CREATE POLICY "estudiantes_all_policy"
    ON public.estudiantes_pasajeros FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

DROP POLICY IF EXISTS "Permitir lectura de perfiles autenticados" ON public.perfiles;
DROP POLICY IF EXISTS "Usuarios pueden actualizar su propio perfil" ON public.perfiles;
DROP POLICY IF EXISTS "perfiles_all_policy" ON public.perfiles;
CREATE POLICY "perfiles_all_policy"
    ON public.perfiles FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);

-- Actualizar coordenadas de recogida para los estudiantes semilla (Penonomé)
update public.estudiantes_pasajeros
set latitud_recogida = 8.5284, longitud_recogida = -80.3582
where id = 1 and latitud_recogida is null;

update public.estudiantes_pasajeros
set latitud_recogida = 8.5242, longitud_recogida = -80.3522
where id = 2 and latitud_recogida is null;

update public.estudiantes_pasajeros
set latitud_recogida = 8.5215, longitud_recogida = -80.3532
where id = 3 and latitud_recogida is null;

update public.estudiantes_pasajeros
set latitud_recogida = 8.5186, longitud_recogida = -80.3541
where id = 4 and latitud_recogida is null;

update public.estudiantes_pasajeros
set latitud_recogida = 8.5172, longitud_recogida = -80.3540
where id = 5 and latitud_recogida is null;
