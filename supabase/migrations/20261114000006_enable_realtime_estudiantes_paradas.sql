-- ============================================================================
-- Migración: Habilitar Supabase Realtime para estudiantes_pasajeros y paradas_ruta
-- Garantiza sincronización en vivo de domicilios y paradas entre Padre, Conductor y Dueño
-- ============================================================================

alter table public.estudiantes_pasajeros replica identity full;

do $$
begin
    alter publication supabase_realtime add table public.estudiantes_pasajeros;
exception
    when duplicate_object then null;
end $$;

do $$
begin
    alter publication supabase_realtime add table public.paradas_ruta;
exception
    when duplicate_object then null;
end $$;
