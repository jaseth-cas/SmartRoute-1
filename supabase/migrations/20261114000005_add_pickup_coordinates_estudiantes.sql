-- ==============================================================
-- MIGRACIÓN: COORDENADAS EXACTAS DE RECOGIDA EN ESTUDIANTES
-- ==============================================================

alter table public.estudiantes_pasajeros
    add column if not exists latitud_recogida double precision,
    add column if not exists longitud_recogida double precision;

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
