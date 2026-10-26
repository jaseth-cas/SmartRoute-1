-- ==============================================================
-- MIGRACIÓN: MÓDULO DE INCIDENTES EN RUTA Y NOTIFICACIONES PUSH
-- ==============================================================

-- 1. Tabla de Incidentes en Ruta (Reportados por conductores)
create table if not exists public.incidentes_ruta (
    id bigserial primary key,
    autobus_codigo text references public.autobuses(codigo) on delete set null,
    conductor_id uuid references public.perfiles(id),
    tipo text not null check (tipo in ('Mecánico', 'Tráfico', 'Accidente', 'Pasajero', 'Otro')),
    titulo text not null,
    descripcion text not null,
    created_at timestamptz default now()
);

alter table public.incidentes_ruta enable row level security;

create policy "Permitir lectura de incidentes a usuarios autenticados"
    on public.incidentes_ruta for select
    to authenticated
    using (true);

create policy "Conductores pueden registrar incidentes"
    on public.incidentes_ruta for insert
    to authenticated
    with check (true);

-- 2. Tabla de Notificaciones Escolares (Alertas para padres y transportistas)
create table if not exists public.notificaciones (
    id bigserial primary key,
    usuario_id uuid references public.perfiles(id) on delete cascade,
    autobus_codigo text references public.autobuses(codigo) on delete set null,
    titulo text not null,
    mensaje text not null,
    tipo text not null default 'info' check (tipo in ('alert', 'info', 'system')),
    leida boolean default false,
    created_at timestamptz default now()
);

alter table public.notificaciones enable row level security;

create policy "Usuarios pueden ver sus propias notificaciones o alertas generales"
    on public.notificaciones for select
    to authenticated
    using (usuario_id = auth.uid() or usuario_id is null);

create policy "Usuarios autenticados pueden crear notificaciones"
    on public.notificaciones for insert
    to authenticated
    with check (true);

create policy "Usuarios pueden marcar sus notificaciones como leídas"
    on public.notificaciones for update
    to authenticated
    using (usuario_id = auth.uid() or usuario_id is null);

-- 3. Habilitar Streaming en Tiempo Real (Realtime WebSockets)
alter publication supabase_realtime add table public.incidentes_ruta;
alter publication supabase_realtime add table public.notificaciones;

-- 4. Datos Semilla para Notificaciones Iniciales
insert into public.notificaciones (autobus_codigo, titulo, mensaje, tipo, leida)
values
    ('BUS-01', 'Ruta Iniciada', 'El autobús BUS-01 ha iniciado el recorrido matutino hacia el Colegio San José.', 'info', true),
    ('BUS-01', 'Retraso Moderado por Tráfico', '[Tráfico] Congestión vehicular sobre la Av. 19. Retraso estimado de 8 minutos.', 'alert', false),
    ('BUS-01', 'Abordaje Confirmado', 'Mateo Gómez ha abordado el autobús de forma segura.', 'system', false)
on conflict do nothing;
