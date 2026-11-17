-- ============================================================================
-- Migración Incremental: Sincronización de secuencias bigserial y RLS/Realtime
-- Evita errores 23505 (duplicate key) al insertar nuevos registros tras seeds
-- con ID explícitos, y garantiza replica identity para Realtime.
-- ============================================================================

-- 1. Resincronizar secuencias bigserial con el MAX(id) actual de cada tabla
SELECT setval(
    pg_get_serial_sequence('public.estudiantes_pasajeros', 'id'),
    COALESCE((SELECT MAX(id) FROM public.estudiantes_pasajeros), 1),
    true
);

SELECT setval(
    pg_get_serial_sequence('public.autobuses', 'id'),
    COALESCE((SELECT MAX(id) FROM public.autobuses), 1),
    true
);

SELECT setval(
    pg_get_serial_sequence('public.asistencia_diaria', 'id'),
    COALESCE((SELECT MAX(id) FROM public.asistencia_diaria), 1),
    true
);

SELECT setval(
    pg_get_serial_sequence('public.paradas_ruta', 'id'),
    COALESCE((SELECT MAX(id) FROM public.paradas_ruta), 1),
    true
);

SELECT setval(
    pg_get_serial_sequence('public.incidentes_ruta', 'id'),
    COALESCE((SELECT MAX(id) FROM public.incidentes_ruta), 1),
    true
);

SELECT setval(
    pg_get_serial_sequence('public.notificaciones', 'id'),
    COALESCE((SELECT MAX(id) FROM public.notificaciones), 1),
    true
);

-- 2. Asegurar REPLICA IDENTITY FULL para Realtime en todas las tablas operativas
ALTER TABLE public.autobuses REPLICA IDENTITY FULL;
ALTER TABLE public.asistencia_diaria REPLICA IDENTITY FULL;
ALTER TABLE public.notificaciones REPLICA IDENTITY FULL;
