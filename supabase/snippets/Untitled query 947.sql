-- 1. Ver estudiantes, colegio y coordenadas de recogida actualizadas por el Padre
SELECT id, nombre, colegio, autobus_codigo, direccion_recogida, latitud_recogida, lo
-- 4. Ver autobuses, cupos ocupados, incidentes y notificaciones recientes
SELECT codigo, placa, modelo, capacidad, asientos_ocupados, colegio_asignado, estado
FROM public.autobuses
ORDER BY codigo;

SELECT id, autobus_codigo, tipo, titulo, created_at
FROM public.incidentes_ruta
ORDER BY created_at DESC
LIMIT 10;

SELECT id, autobus_codigo, titulo, mensaje, tipo, leida, created_at
FROM public.notificaciones
ORDER BY created_at DESC
LIMIT 10;ngitud_recogida
FROM public.estudiantes_pasajeros
ORDER BY id;

-- 2. Ver paradas sincronizadas en paradas_ruta
SELECT id, codigo, autobus_codigo, nombre, latitud, longitud
FROM public.paradas_ruta
ORDER BY id;

-- 3. Ver asistencia de hoy (ausencias, onboard, delivered)
SELECT a.id, e.nombre, a.fecha, a.estado, a.hora_abordaje, a.metodo_abordaje
FROM public.asistencia_diaria a
JOIN public.estudiantes_pasajeros e ON e.id = a.estudiante_id
ORDER BY a.id DESC;
