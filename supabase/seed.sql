-- ==============================================================
-- SMARTROUTE - DATOS SEMILLA DETERMINÍSTICOS (PENONOMÉ, COCLÉ)
-- ==============================================================
-- Script idempotente (ON CONFLICT ... DO UPDATE) con la verdad única:
-- - 5 usuarios deterministas (contraseña estándar: Password123!)
-- - 2 autobuses reales en Penonomé (BUS-01 y BUS-02) con conductor asignado
-- - 8 estudiantes reales (4 asignados a BUS-01 y 4 a BUS-02)
-- - 8 paradas de ruta reales en Penonomé (4 por autobús)
-- ==============================================================

create extension if not exists pgcrypto with schema extensions;

-- ==============================================================
-- 1. USUARIOS EN AUTH.USERS (CONTRASEÑA: Password123!)
-- ==============================================================
insert into auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    email_change_token_current,
    reauthentication_token,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at
)
values
    -- A. DUEÑO DE FLOTA (TRANSPORTISTA)
    (
        'a0000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'dueno@smartroute.com',
        extensions.crypt('Password123!', extensions.gen_salt('bf', 8)),
        now(),
        '',
        '',
        '',
        '',
        '',
        '',
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{"nombre": "Don Fernando Gómez", "rol": "owner", "telefono": "+507 6201-1122"}'::jsonb,
        false,
        now(),
        now()
    ),
    -- B1. CONDUCTOR ESCOLAR 1 (BUS-01)
    (
        'b0000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'conductor@smartroute.com',
        extensions.crypt('Password123!', extensions.gen_salt('bf', 8)),
        now(),
        '',
        '',
        '',
        '',
        '',
        '',
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{"nombre": "Carlos Andrés Gómez", "rol": "driver", "telefono": "+507 6412-3344"}'::jsonb,
        false,
        now(),
        now()
    ),
    -- B2. CONDUCTOR ESCOLAR 2 (BUS-02)
    (
        'b0000000-0000-0000-0000-000000000005',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'conductor2@smartroute.com',
        extensions.crypt('Password123!', extensions.gen_salt('bf', 8)),
        now(),
        '',
        '',
        '',
        '',
        '',
        '',
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{"nombre": "Luis Alberto Mendoza", "rol": "driver", "telefono": "+507 6678-9012"}'::jsonb,
        false,
        now(),
        now()
    ),
    -- C1. PADRE DE FAMILIA 1 (TUTOR DE ESTUDIANTES EN BUS-01)
    (
        'c0000000-0000-0000-0000-000000000003',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'padre1@smartroute.com',
        extensions.crypt('Password123!', extensions.gen_salt('bf', 8)),
        now(),
        '',
        '',
        '',
        '',
        '',
        '',
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{"nombre": "Carlos Gómez (Tutor BUS-01)", "rol": "student", "telefono": "+507 6300-4567"}'::jsonb,
        false,
        now(),
        now()
    ),
    -- C2. PADRE DE FAMILIA 2 (TUTORA DE SOFÍA RAMÍREZ)
    (
        'c0000000-0000-0000-0000-000000000004',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'padre2@smartroute.com',
        extensions.crypt('Password123!', extensions.gen_salt('bf', 8)),
        now(),
        '',
        '',
        '',
        '',
        '',
        '',
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{"nombre": "Elena Ramírez (Tutora Sofía)", "rol": "student", "telefono": "+507 6510-6543"}'::jsonb,
        false,
        now(),
        now()
    )
on conflict (id) do update set
    email = excluded.email,
    encrypted_password = excluded.encrypted_password,
    raw_user_meta_data = excluded.raw_user_meta_data,
    email_confirmed_at = excluded.email_confirmed_at,
    confirmation_token = '',
    recovery_token = '',
    email_change_token_new = '',
    email_change = '',
    email_change_token_current = '',
    reauthentication_token = '',
    updated_at = now();

-- ==============================================================
-- 2. IDENTIDADES DE AUTENTICACIÓN EN AUTH.IDENTITIES
-- ==============================================================
insert into auth.identities (
    id,
    provider_id,
    user_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
)
values
    (
        'a0000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000001',
        jsonb_build_object('sub', 'a0000000-0000-0000-0000-000000000001', 'email', 'dueno@smartroute.com'),
        'email',
        now(),
        now(),
        now()
    ),
    (
        'b0000000-0000-0000-0000-000000000002',
        'b0000000-0000-0000-0000-000000000002',
        'b0000000-0000-0000-0000-000000000002',
        jsonb_build_object('sub', 'b0000000-0000-0000-0000-000000000002', 'email', 'conductor@smartroute.com'),
        'email',
        now(),
        now(),
        now()
    ),
    (
        'b0000000-0000-0000-0000-000000000005',
        'b0000000-0000-0000-0000-000000000005',
        'b0000000-0000-0000-0000-000000000005',
        jsonb_build_object('sub', 'b0000000-0000-0000-0000-000000000005', 'email', 'conductor2@smartroute.com'),
        'email',
        now(),
        now(),
        now()
    ),
    (
        'c0000000-0000-0000-0000-000000000003',
        'c0000000-0000-0000-0000-000000000003',
        'c0000000-0000-0000-0000-000000000003',
        jsonb_build_object('sub', 'c0000000-0000-0000-0000-000000000003', 'email', 'padre1@smartroute.com'),
        'email',
        now(),
        now(),
        now()
    ),
    (
        'c0000000-0000-0000-0000-000000000004',
        'c0000000-0000-0000-0000-000000000004',
        'c0000000-0000-0000-0000-000000000004',
        jsonb_build_object('sub', 'c0000000-0000-0000-0000-000000000004', 'email', 'padre2@smartroute.com'),
        'email',
        now(),
        now(),
        now()
    )
on conflict (provider_id, provider) do update set
    identity_data = excluded.identity_data,
    updated_at = now();

-- ==============================================================
-- 3. PERFILES DE USUARIO EN PUBLIC.PERFILES
-- ==============================================================
insert into public.perfiles (id, nombre, email, rol, telefono)
values
    ('a0000000-0000-0000-0000-000000000001', 'Don Fernando Gómez', 'dueno@smartroute.com', 'owner', '+507 6201-1122'),
    ('b0000000-0000-0000-0000-000000000002', 'Carlos Andrés Gómez', 'conductor@smartroute.com', 'driver', '+507 6412-3344'),
    ('b0000000-0000-0000-0000-000000000005', 'Luis Alberto Mendoza', 'conductor2@smartroute.com', 'driver', '+507 6678-9012'),
    ('c0000000-0000-0000-0000-000000000003', 'Carlos Gómez', 'padre1@smartroute.com', 'student', '+507 6300-4567'),
    ('c0000000-0000-0000-0000-000000000004', 'Elena Ramírez', 'padre2@smartroute.com', 'student', '+507 6510-6543')
on conflict (id) do update set
    nombre = excluded.nombre,
    email = excluded.email,
    rol = excluded.rol,
    telefono = excluded.telefono;

-- ==============================================================
-- 4. FLOTA DE 2 AUTOBUSES EN PENONOMÉ, COCLÉ
-- ==============================================================
insert into public.autobuses (
    codigo,
    placa,
    modelo,
    capacidad,
    asientos_ocupados,
    estado,
    dueno_id,
    conductor_id,
    colegio_asignado,
    nombre_ruta,
    velocidad_kmh,
    latitud_actual,
    longitud_actual,
    is_verified
)
values
    (
        'BUS-01',
        'TBX-492',
        'Toyota Coaster Escolar',
        16,
        4,
        'En recorrido',
        'a0000000-0000-0000-0000-000000000001',
        'b0000000-0000-0000-0000-000000000002',
        'Colegio Ángel María Herrera',
        'Ruta Norte Penonomé - Ángel M. Herrera',
        38,
        8.5186,
        -80.3572,
        true
    ),
    (
        'BUS-02',
        'SKL-810',
        'Nissan Civilian',
        20,
        4,
        'Disponible',
        'a0000000-0000-0000-0000-000000000001',
        'b0000000-0000-0000-0000-000000000005',
        'Colegio San Agustín',
        'Ruta Sur Penonomé - San Agustín',
        28,
        8.5245,
        -80.3510,
        true
    )
on conflict (codigo) do update set
    placa = excluded.placa,
    modelo = excluded.modelo,
    capacidad = excluded.capacidad,
    asientos_ocupados = excluded.asientos_ocupados,
    estado = excluded.estado,
    dueno_id = excluded.dueno_id,
    conductor_id = excluded.conductor_id,
    colegio_asignado = excluded.colegio_asignado,
    nombre_ruta = excluded.nombre_ruta,
    velocidad_kmh = excluded.velocidad_kmh,
    latitud_actual = excluded.latitud_actual,
    longitud_actual = excluded.longitud_actual,
    is_verified = excluded.is_verified;

-- ==============================================================
-- 5. ESTUDIANTES PASAJEROS (MÍNIMO 4 POR AUTOBÚS - 8 EN TOTAL)
-- ==============================================================
insert into public.estudiantes_pasajeros (
    id,
    nombre,
    padre_nombre,
    padre_telefono,
    padre_id,
    colegio,
    direccion_recogida,
    autobus_codigo,
    orden,
    cuota_mensual,
    estado_pago,
    latitud_recogida,
    longitud_recogida
)
values
    -- BUS-01 (4 estudiantes vinculados a padre1@smartroute.com)
    (
        1,
        'Mateo Gómez',
        'Carlos Gómez',
        '+507 6300-4567',
        'c0000000-0000-0000-0000-000000000003',
        'Colegio Ángel María Herrera',
        'Vía hacia Sonadora, Casa #14, Penonomé',
        'BUS-01',
        1,
        65.00,
        'Al día',
        8.5284,
        -80.3582
    ),
    (
        2,
        'Sofía Ramírez',
        'Carlos Gómez',
        '+507 6300-4567',
        'c0000000-0000-0000-0000-000000000003',
        'Colegio Ángel María Herrera',
        'Barriada Miraflores, Calle 4, Penonomé',
        'BUS-01',
        2,
        65.00,
        'Al día',
        8.5242,
        -80.3522
    ),
    (
        3,
        'Lucas Rodríguez',
        'Carlos Gómez',
        '+507 6300-4567',
        'c0000000-0000-0000-0000-000000000003',
        'Colegio Ángel María Herrera',
        'Av. Central, Sector El Chorro, Penonomé',
        'BUS-01',
        3,
        65.00,
        'Pendiente',
        8.5215,
        -80.3532
    ),
    (
        4,
        'Valentina Castro',
        'Carlos Gómez',
        '+507 6300-4567',
        'c0000000-0000-0000-0000-000000000003',
        'Colegio Ángel María Herrera',
        'Calle Damián Carles, San Antonio, Penonomé',
        'BUS-01',
        4,
        65.00,
        'Al día',
        8.5172,
        -80.3540
    ),
    -- BUS-02 (4 estudiantes vinculados a padre2@smartroute.com)
    (
        5,
        'Eliam Fernández',
        'Elena Ramírez',
        '+507 6510-6543',
        'c0000000-0000-0000-0000-000000000004',
        'Colegio San Agustín',
        'Vía Cristo Rey, Penonomé',
        'BUS-02',
        1,
        65.00,
        'Al día',
        8.5186,
        -80.3541
    ),
    (
        6,
        'Camila Vásquez',
        'Elena Ramírez',
        '+507 6510-6543',
        'c0000000-0000-0000-0000-000000000004',
        'Colegio San Agustín',
        'Villa Karola, Calle Principal, Penonomé',
        'BUS-02',
        2,
        65.00,
        'Al día',
        8.5256,
        -80.3498
    ),
    (
        7,
        'Gabriel Aguilar',
        'Elena Ramírez',
        '+507 6510-6543',
        'c0000000-0000-0000-0000-000000000004',
        'Colegio San Agustín',
        'Barriada Las Lomas, Penonomé',
        'BUS-02',
        3,
        65.00,
        'Pendiente',
        8.5138,
        -80.3492
    ),
    (
        8,
        'Isabella Ortega',
        'Elena Ramírez',
        '+507 6510-6543',
        'c0000000-0000-0000-0000-000000000004',
        'Colegio San Agustín',
        'Av. Juan Demóstenes Arosemena, Penonomé',
        'BUS-02',
        4,
        65.00,
        'Al día',
        8.5085,
        -80.3545
    )
on conflict (id) do update set
    nombre = excluded.nombre,
    padre_nombre = excluded.padre_nombre,
    padre_telefono = excluded.padre_telefono,
    padre_id = excluded.padre_id,
    colegio = excluded.colegio,
    direccion_recogida = excluded.direccion_recogida,
    autobus_codigo = excluded.autobus_codigo,
    orden = excluded.orden,
    cuota_mensual = excluded.cuota_mensual,
    estado_pago = excluded.estado_pago,
    latitud_recogida = excluded.latitud_recogida,
    longitud_recogida = excluded.longitud_recogida;

-- ==============================================================
-- 6. ASISTENCIA DIARIA INICIAL (PARA LOS 8 ESTUDIANTES)
-- ==============================================================
insert into public.asistencia_diaria (estudiante_id, fecha, jornada, estado, hora_abordaje, metodo_abordaje)
values
    (1, current_date, 'manana', 'onboard', '06:52 AM', 'Biometría Facial AI'),
    (2, current_date, 'manana', 'onboard', '07:01 AM', 'Biometría Facial AI'),
    (3, current_date, 'manana', 'waiting', null, null),
    (4, current_date, 'manana', 'absent', null, null),
    (5, current_date, 'manana', 'onboard', '06:58 AM', 'Biometría Facial AI'),
    (6, current_date, 'manana', 'waiting', null, null),
    (7, current_date, 'manana', 'waiting', null, null),
    (8, current_date, 'manana', 'waiting', null, null)
on conflict (estudiante_id, fecha, jornada) do update set
    estado = excluded.estado,
    hora_abordaje = excluded.hora_abordaje,
    metodo_abordaje = excluded.metodo_abordaje;

-- ==============================================================
-- 7. PARADAS DE RUTA REALES EN PENONOMÉ (4 POR BUS)
-- ==============================================================
insert into public.paradas_ruta (
    id,
    autobus_codigo,
    codigo,
    nombre,
    referencia,
    orden,
    distancia_km,
    latitud,
    longitud,
    is_favorite
)
values
    -- Paradas BUS-01 (Ruta Norte Penonomé -> Colegio Ángel María Herrera)
    (1, 'BUS-01', 'P-B01-01', 'Vía Sonadora Norte', 'Entrada Residencial Sonadora', 1, 0.0, 8.5284, -80.3582, true),
    (2, 'BUS-01', 'P-B01-02', 'Barriada Miraflores', 'Frente a Minisúper Miraflores', 2, 1.1, 8.5242, -80.3522, false),
    (3, 'BUS-01', 'P-B01-03', 'Sector El Chorro', 'Avenida Central Penonomé', 3, 2.0, 8.5215, -80.3532, false),
    (4, 'BUS-01', 'P-B01-04', 'Colegio Ángel María Herrera', 'Portón Principal Av. Héctor Conte', 4, 3.4, 8.5112, -80.3551, true),

    -- Paradas BUS-02 (Ruta Sur Penonomé -> Colegio San Agustín)
    (5, 'BUS-02', 'P-B02-01', 'Villa Karola', 'Entrada Principal Villa Karola', 1, 0.0, 8.5256, -80.3498, true),
    (6, 'BUS-02', 'P-B02-02', 'Vía Cristo Rey', 'Frente a Parque Cristo Rey', 2, 1.2, 8.5186, -80.3541, false),
    (7, 'BUS-02', 'P-B02-03', 'Barriada Las Lomas', 'Esquina Comercial Las Lomas', 3, 2.3, 8.5138, -80.3492, false),
    (8, 'BUS-02', 'P-B02-04', 'Colegio San Agustín', 'Portón de Acceso Escolar', 4, 4.1, 8.4952, -80.3539, true)
on conflict (id) do update set
    autobus_codigo = excluded.autobus_codigo,
    codigo = excluded.codigo,
    nombre = excluded.nombre,
    referencia = excluded.referencia,
    orden = excluded.orden,
    distancia_km = excluded.distancia_km,
    latitud = excluded.latitud,
    longitud = excluded.longitud,
    is_favorite = excluded.is_favorite;

-- ==============================================================
-- 8. SINCRONIZACIÓN DE SECUENCIAS SERIALES
-- ==============================================================
select setval(pg_get_serial_sequence('public.autobuses', 'id'), (select coalesce(max(id), 1) from public.autobuses));
select setval(pg_get_serial_sequence('public.estudiantes_pasajeros', 'id'), (select coalesce(max(id), 1) from public.estudiantes_pasajeros));
select setval(pg_get_serial_sequence('public.asistencia_diaria', 'id'), (select coalesce(max(id), 1) from public.asistencia_diaria));
select setval(pg_get_serial_sequence('public.paradas_ruta', 'id'), (select coalesce(max(id), 1) from public.paradas_ruta));
select setval(pg_get_serial_sequence('public.notificaciones', 'id'), (select coalesce(max(id), 1) from public.notificaciones));
