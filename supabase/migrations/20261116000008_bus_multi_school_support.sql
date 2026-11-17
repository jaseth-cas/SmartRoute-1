-- ============================================================================
-- Migración Incremental: Soporte Multi-Colegio por Autobús Escolar
-- Un autobús particular puede transportar estudiantes de distintos colegios;
-- la columna `estudiantes_pasajeros.colegio` es la fuente de verdad por alumno.
-- ============================================================================

ALTER TABLE public.autobuses
    ALTER COLUMN colegio_asignado SET DEFAULT 'Múltiples colegios';

CREATE INDEX IF NOT EXISTS idx_estudiantes_bus_colegio
    ON public.estudiantes_pasajeros (autobus_codigo, colegio);
