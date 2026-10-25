-- ==============================================================
-- SMARTRUTE - DATOS SEMILLA DETERMINÍSTICOS Y USUARIOS DE PRUEBA
-- ==============================================================
-- Este script crea usuarios de prueba fijos para los 3 roles del sistema
-- con contraseña estándar: Password123!
-- Contiene las identidades de autenticación de Supabase (auth.users y auth.identities)
-- y sincroniza sus perfiles en public.perfiles.

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
        '{"nombre": "Don Fernando Gómez (Transportista)", "rol": "owner", "telefono": "+57 300 111 2233"}'::jsonb,
        false,
        now(),
        now()
    ),
    -- B. CONDUCTOR ESCOLAR
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
        '{"nombre": "Carlos Andrés Gómez (Chofer)", "rol": "driver", "telefono": "+57 310 444 5566"}'::jsonb,
        false,
        now(),
        now()
    ),
    -- C. PADRE DE FAMILIA 1 (TUTOR DE MATEO GÓMEZ)
    (
        'c0000000-0000-0000-0000-000000000003',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'padre@smartroute.com',
        extensions.crypt('Password123!', extensions.gen_salt('bf', 8)),
        now(),
        '',
        '',
        '',
        '',
        '',
        '',
        '{"provider": "email", "providers": ["email"]}'::jsonb,
        '{"nombre": "Carlos Gómez (Tutor Mateo)", "rol": "student", "telefono": "+57 300 123 4567"}'::jsonb,
        false,
        now(),
        now()
    ),
    -- D. PADRE DE FAMILIA 2 (TUTORA DE SOFÍA RAMÍREZ)
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
        '{"nombre": "Elena Ramírez (Tutora Sofía)", "rol": "student", "telefono": "+57 310 987 6543"}'::jsonb,
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
        'c0000000-0000-0000-0000-000000000003',
        'c0000000-0000-0000-0000-000000000003',
        'c0000000-0000-0000-0000-000000000003',
        jsonb_build_object('sub', 'c0000000-0000-0000-0000-000000000003', 'email', 'padre@smartroute.com'),
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
    ('a0000000-0000-0000-0000-000000000001', 'Don Fernando Gómez', 'dueno@smartroute.com', 'owner', '+57 300 111 2233'),
    ('b0000000-0000-0000-0000-000000000002', 'Carlos Andrés Gómez', 'conductor@smartroute.com', 'driver', '+57 310 444 5566'),
    ('c0000000-0000-0000-0000-000000000003', 'Carlos Gómez (Padre)', 'padre@smartroute.com', 'student', '+57 300 123 4567'),
    ('c0000000-0000-0000-0000-000000000004', 'Elena Ramírez (Madre)', 'padre2@smartroute.com', 'student', '+57 310 987 6543')
on conflict (id) do update set
    nombre = excluded.nombre,
    email = excluded.email,
    rol = excluded.rol,
    telefono = excluded.telefono;

-- ==============================================================
-- 4. ASIGNACIÓN DETERMINÍSTICA DE FLOTA Y ESTUDIANTES
-- ==============================================================
update public.autobuses
set
    dueno_id = 'a0000000-0000-0000-0000-000000000001',
    conductor_id = 'b0000000-0000-0000-0000-000000000002',
    is_verified = true
where codigo = 'BUS-01';

update public.autobuses
set
    dueno_id = 'a0000000-0000-0000-0000-000000000001',
    is_verified = true
where codigo = 'BUS-02';

update public.estudiantes_pasajeros
set padre_id = 'c0000000-0000-0000-0000-000000000003'
where id = 1;

update public.estudiantes_pasajeros
set padre_id = 'c0000000-0000-0000-0000-000000000004'
where id = 2;
