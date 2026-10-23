-- ==============================================================
-- MIGRACIÓN INICIAL: PLATAFORMA DE TRANSPORTE ESCOLAR SMARTRUTE
-- ==============================================================

-- 1. Habilitar extensión espacial para geolocalización avanzada
create extension if not exists postgis;

-- 2. Tabla de Perfiles de Usuario (Padre, Conductor, Dueño de Flota)
create table if not exists public.perfiles (
    id uuid primary key,
    nombre text not null,
    email text not null,
    rol text not null check (rol in ('student', 'driver', 'owner')),
    telefono text,
    created_at timestamptz default now()
);

-- Habilitar RLS en perfiles
alter table public.perfiles enable row level security;

create policy "Permitir lectura de perfiles autenticados"
    on public.perfiles for select
    to authenticated
    using (true);

create policy "Usuarios pueden actualizar su propio perfil"
    on public.perfiles for update
    to authenticated
    using (id = auth.uid());

-- 3. Tabla de Autobuses Escolares
create table if not exists public.autobuses (
    id bigserial primary key,
    codigo text unique not null,
    placa text unique not null,
    modelo text not null,
    capacidad int not null default 16,
    asientos_ocupados int not null default 0,
    estado text not null default 'Disponible', -- 'En recorrido', 'Disponible', 'Detenido'
    dueno_id uuid references public.perfiles(id),
    conductor_id uuid references public.perfiles(id),
    colegio_asignado text default 'Colegio San José',
    nombre_ruta text default 'Ruta Escolar Norte',
    velocidad_kmh int default 0,
    latitud_actual double precision default 9.9340,
    longitud_actual double precision default -84.0780,
    is_verified boolean default true,
    created_at timestamptz default now()
);

alter table public.autobuses enable row level security;

create policy "Permitir lectura de autobuses a todos los autenticados"
    on public.autobuses for select
    to authenticated
    using (true);

create policy "Transportistas pueden crear y actualizar sus propios autobuses"
    on public.autobuses for all
    to authenticated
    using (dueno_id = auth.uid());

-- 4. Tabla de Estudiantes Pasajeros
create table if not exists public.estudiantes_pasajeros (
    id bigserial primary key,
    nombre text not null,
    padre_nombre text not null,
    padre_telefono text,
    padre_id uuid references public.perfiles(id),
    colegio text not null default 'Colegio San José',
    direccion_recogida text not null,
    autobus_codigo text references public.autobuses(codigo) on delete set null,
    orden int not null default 1,
    cuota_mensual numeric(10,2) default 65.00,
    estado_pago text not null default 'Al día', -- 'Al día', 'Pendiente', 'En mora'
    vector_biometrico text, -- Representación vectorial cifrada para IA Facial
    created_at timestamptz default now()
);

alter table public.estudiantes_pasajeros enable row level security;

create policy "Lectura de estudiantes para usuarios autorizados"
    on public.estudiantes_pasajeros for select
    to authenticated
    using (true);

-- 5. Tabla de Asistencia y Abordaje Diario (Sincronización en vivo)
create table if not exists public.asistencia_diaria (
    id bigserial primary key,
    estudiante_id bigint references public.estudiantes_pasajeros(id) on delete cascade,
    fecha date not null default current_date,
    jornada text not null default 'manana' check (jornada in ('manana', 'tarde')),
    estado text not null default 'waiting' check (estado in ('waiting', 'onboard', 'delivered', 'absent')),
    hora_abordaje text,
    metodo_abordaje text, -- 'Biometría Facial AI', 'Manual'
    created_at timestamptz default now(),
    unique (estudiante_id, fecha, jornada)
);

alter table public.asistencia_diaria enable row level security;

create policy "Permitir lectura y modificación de asistencia a autenticados"
    on public.asistencia_diaria for all
    to authenticated
    using (true);

-- 6. Tabla de Paradas de Ruta
create table if not exists public.paradas_ruta (
    id bigserial primary key,
    autobus_codigo text references public.autobuses(codigo) on delete cascade,
    codigo text not null,
    nombre text not null,
    referencia text,
    orden int not null,
    distancia_km double precision default 0.0,
    latitud double precision,
    longitud double precision,
    is_favorite boolean default false,
    created_at timestamptz default now()
);

alter table public.paradas_ruta enable row level security;

create policy "Lectura de paradas a autenticados"
    on public.paradas_ruta for select
    to authenticated
    using (true);

-- 7. Activar Streaming en Tiempo Real (Realtime WebSockets)
alter publication supabase_realtime add table public.autobuses;
alter publication supabase_realtime add table public.asistencia_diaria;

-- ==============================================================
-- DATOS SEMILLA (SEED DATA DE TRANSPORTE ESCOLAR)
-- ==============================================================

-- Inserción de Autobuses Escolares
insert into public.autobuses (codigo, placa, modelo, capacidad, asientos_ocupados, estado, colegio_asignado, nombre_ruta, velocidad_kmh, latitud_actual, longitud_actual)
values 
    ('BUS-01', 'TBX-492', 'Toyota Coaster Escolar', 16, 14, 'En recorrido', 'Colegio San José', 'Ruta Escolar Norte - Col. San José', 38, 9.9340, -84.0780),
    ('BUS-02', 'SKL-810', 'Nissan Civilian', 20, 18, 'Disponible', 'Colegio Santa María', 'Ruta Escolar Sur - Col. Santa María', 0, 9.9318, -84.0778)
on conflict (codigo) do nothing;

-- Inserción de Estudiantes Pasajeros
insert into public.estudiantes_pasajeros (id, nombre, padre_nombre, padre_telefono, colegio, direccion_recogida, autobus_codigo, orden, cuota_mensual, estado_pago)
values 
    (1, 'Mateo Gómez', 'Carlos Gómez', '+57 300 123 4567', 'Colegio San José', 'Calle 45 # 12-30 (Casa)', 'BUS-01', 1, 65.00, 'Al día'),
    (2, 'Sofía Ramírez', 'Elena Ramírez', '+57 310 987 6543', 'Colegio San José', 'Cra. 15 # 88-21 (Res. Primavera)', 'BUS-01', 2, 65.00, 'Al día'),
    (3, 'Lucas Rodríguez', 'Andrés Rodríguez', '+57 315 444 3322', 'Colegio San José', 'Av. 19 # 104-50 (Edif. Almirante)', 'BUS-01', 3, 65.00, 'Pendiente'),
    (4, 'Valentina Castro', 'Patricia Castro', '+57 320 555 8899', 'Colegio San José', 'Calle 72 # 9-15 (Torres del Parque)', 'BUS-01', 4, 65.00, 'Al día'),
    (5, 'Santiago Morales', 'Felipe Morales', '+57 301 777 9900', 'Colegio San José', 'Transversal 23 # 45-10', 'BUS-01', 5, 65.00, 'Al día')
on conflict (id) do nothing;

-- Inserción de Estados de Asistencia del Día
insert into public.asistencia_diaria (estudiante_id, fecha, jornada, estado, hora_abordaje, metodo_abordaje)
values 
    (1, current_date, 'manana', 'onboard', '07:14 AM', 'Biometría Facial AI'),
    (2, current_date, 'manana', 'onboard', '07:22 AM', 'Biometría Facial AI'),
    (3, current_date, 'manana', 'waiting', null, null),
    (4, current_date, 'manana', 'absent', null, null),
    (5, current_date, 'manana', 'waiting', null, null)
on conflict (estudiante_id, fecha, jornada) do nothing;
