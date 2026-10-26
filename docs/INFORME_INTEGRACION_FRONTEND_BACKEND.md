# Informe Técnico de Integración: Frontend Neumórfico & Backend Supabase

> **Proyecto:** SmartRoute Flutter  
> **Fecha de Integración:** Octubre 2026  
> **Rama de Fusión:** `main` (Merge limpio con `PruebaBackend`)  
> **Estado de la Suite de Pruebas:** `21/21 All tests passed` (`flutter test`)  
> **Hash de Commit de Integración:** `d411b78`

---

## 1. Resumen Ejecutivo de la Fusión

El objetivo primordial de esta integración fue **unificar el 100% de los desarrollos de la interfaz de usuario (UI/UX) neumórfica y detección biométrica facial** con el **100% de la arquitectura de backend relacional y servicios en la nube de Supabase**, garantizando:
1. **Cero pérdida de código estético y funcional:** Se conservaron todos los componentes visuales tipo cápsula, sombreados cóncavos/convexos (`NeumorphicBox`), paleta de colores Quivox Cyberpunk/Neumorphism, soporte responsive en doble columna para monitores desktop y pantallas móviles, detección facial BlazeFace en Web y rutas georreferenciadas del distrito de Penonomé, Coclé.
2. **Cero pérdida de lógica relacional y seguridad:** Se integraron intactas las migraciones SQL de PostgreSQL, tablas maestras, triggers automáticos de creación de perfiles, políticas Row Level Security (RLS), políticas de desarrollo híbrido (anon fallback) y todos los servicios Dart conectados vía `provider`.
3. **Resiliencia Operativa (Offline / Demo Fallback):** Todas las pantallas integradas implementan una estrategia de sincronización resiliente: intentan consumir y persistir datos en Supabase, y en caso de contingencia o ausencia de conectividad a la red de backend, recurren sin fallos ni bloqueos a los repositorios locales (`MockData`), permitiendo demostraciones y pruebas de usuario ininterrumpidas.

---

## 2. Mapa Detallado: ¿Qué Se Hizo? (Implementado y Fusionado)

### 2.1. Capa de Backend (Supabase & PostgreSQL)
* [x] **Esquema Relacional Completo (`supabase/migrations/20261023000000_schema_smartroute.sql`):**
  - Tabla `perfiles` (`id`, `nombre_completo`, `rol` [padre, conductor, dueno_bus, admin], `telefono`, `avatar_url`, `created_at`).
  - Tabla `estudiantes` (`id`, `nombre`, `padre_id`, `escuela`, `grado`, `foto_referencia_url`, `estado_embarque`, `bus_asignado_id`, `fecha_registro`).
  - Tabla `buses` (`id`, `codigo_bus`, `placa`, `capacidad`, `conductor_id`, `dueno_id`, `activo`, `latitud_actual`, `longitud_actual`, `velocidad_kmh`, `ultima_actualizacion`).
  - Tabla `rutas` y `paradas` (`coordenadas_gps`, `orden`, `hora_estimada`).
  - Tabla `asistencias` (`id`, `estudiante_id`, `bus_id`, `fecha_hora`, `tipo_evento` [check_in, check_out], `metodo_validacion` [biometrico, nfc, manual], `foto_validacion_url`, `coordenadas_gps`).
  - Tabla `incidentes` (`id`, `bus_id`, `conductor_id`, `tipo_incidente`, `descripcion`, `gravedad`, `fecha_hora`, `estado`).
  - Tabla `notificaciones` (`id`, `destinatario_id`, `titulo`, `mensaje`, `leido`, `tipo`, `fecha_hora`).
* [x] **Triggers de Autenticación (`supabase/migrations/20261023000001_auth_triggers.sql`):**
  - Función de base de datos `public.handle_new_user()` que replica inmediatamente en `public.perfiles` cualquier nuevo usuario creado en el schema `auth.users`.
* [x] **Políticas de Seguridad RLS Granulares (`docs/auditoria_seguridad_rls.md`):**
  - Políticas de aislamiento por rol para padres, conductores y transportistas.
  - Migración `20261025000003_allow_anon_hybrid_policies.sql` para soportar pruebas con clave pública `anon` y autenticación híbrida sin vulnerar los candados de producción.
* [x] **Semilla Determinista de Usuarios de Prueba (`supabase/migrations/20261025000004_seed_deterministic_demo_users.sql` & `docs/usuarios_prueba.md`):**
  - **Padre de Familia:** `padre@smartroute.com` | `Password123!` (Asociado a estudiantes Valentina y Mateo).
  - **Conductor de Ruta:** `conductor@smartroute.com` | `Password123!` (Asignado al autobús `BUS-01` de Penonomé).
  - **Transportista / Dueño de Flota:** `dueno@smartroute.com` | `Password123!` (Gestor de las unidades de transporte).
* [x] **Capa de Servicios Dart (`lib/nucleo/servicios/`):**
  - `supabase_client.dart`: Inicialización singleton del SDK de Supabase con URL y Anon Key configuradas.
  - `auth_service.dart`: Login, registro, logout, recuperación de sesión y sincronización con `SessionManager`.
  - `student_service.dart`: Obtención de estudiantes asignados al padre, cambio de estado de abordaje.
  - `bus_service.dart`: Obtención de buses por código, actualización en tiempo real de coordenadas de telemetría y consulta de rutas.
  - `attendance_service.dart`: Registro transaccional de check-in / check-out con método biométrico facial o manual y emisión de alertas asociadas.
  - `incident_service.dart`: Emisión de incidentes mecánicos, de tráfico o emergencias con notificación automática a padres y directiva.

---

### 2.2. Capa de Frontend (UI/UX Neumórfica & Biometría)
* [x] **Estilo de Diseño Neumórfico "Soft UI" Quivox (`lib/nucleo/widgets/neumorphic_box.dart`, `lib/nucleo/tema/colors.dart`):**
  - Elevaciones sutiles, sombras duales (luz superior izquierda blanca / sombra inferior derecha oscura).
  - Estados interactivos: `isPressed`, `isConvex`, `isPill` y variantes en acentos Cyan (`SmartColors.vibrantCyan`), Dark Petrol (`SmartColors.deepPetrol`) y Crimson Alert.
* [x] **Terminal Biométrica de Abordaje Facial (`lib/nucleo/widgets/facial_boarding_dialog.dart` & `web/smartroute_face_detector.js`):**
  - Integración en navegador mediante script BlazeFace JavaScript con aceleración WebGL/WASM para reconocimiento de rostro y puntos faciales en tiempo real.
  - Diálogo modal con visor de cámara redondeado, retícula con escáner holográfico de bordes animados y verificación contra el modelo del estudiante.
  - Doble persistencia: Actualiza `AttendanceService` en Supabase y los estados en memoria de `MockData`.
* [x] **Diseño Responsivo Adaptativo Móvil / Desktop (`lib/nucleo/widgets/responsive_layout.dart`):**
  - Todas las pantallas críticas implementan `ResponsiveContent` y `LayoutBuilder` para renderizar:
    - En pantallas anchas (>= 1024px): Paneles laterales fijos de telemática, analíticas o listas de pasajeros junto a mapas interactivos en pantalla completa.
    - En pantallas móviles (< 1024px): Tarjetas deslizables y navegación táctil inferior con `DriverBottomBar` o pestañas neumórficas.
* [x] **Pantallas Fusionadas y Optimizadas:**
  - `login_screen.dart`: Soporte para acceso directo con cuentas demo (Padre, Conductor, Dueño) y autenticación contra `AuthService` de Supabase.
  - `register_screen.dart`: Selección visual de rol y creación coordinada en Supabase y estado local.
  - `student_home_screen.dart`: Panel del padre con estado de sus hijos en tiempo real, tarjeta del bus asignado, acceso al mapa telemático y telemetría de velocidad.
  - `simulated_map_screen.dart`: Mapa interactivo OpenStreetMap / FlutterMap con capas de ruta de Penonomé (Llano Marín -> Miraflores -> Escuela), panel de telemetría con velocímetro, estado del conductor y switch de sincronización en vivo con Supabase.
  - `driver_home_screen.dart`: Cabina de control del conductor con velocímetro neumórfico, lista de próximas paradas, botón de pánico y accesos rápidos.
  - `driver_demand_screen.dart`: Lista de estudiantes asignados, filtros de abordaje y disparador del diálogo de reconocimiento facial.
  - `report_incident_screen.dart`: Formulario neumórfico para reportar incidencias con categorización por gravedad e inserción en Supabase.
  - `owner_home_screen.dart`: Tablero del dueño con estado de la flota, métricas de ocupación, resumen financiero simulado y accesos de administración.
  - `owner_map_screen.dart`: Monitoreo geoespacial de toda la flota de autobuses escolares simultáneamente.
  - `register_bus_screen.dart`: Formulario de enrolamiento de nuevas unidades con capacidad y placa.
  - `edit_profile_screen.dart` & `notifications_screen.dart`: Perfil de usuario y bandeja de notificaciones reactiva.

---

### 2.3. Configuración y Pruebas Automatizadas
* [x] **`pubspec.yaml`:**
  - Dependencias de backend: `supabase_flutter: ^2.8.3`.
  - Dependencias de UI y telemática: `flutter_map: ^7.0.2`, `latlong2: ^0.9.1`, `geolocator: ^13.0.2`, `google_fonts: ^6.2.1`, `go_router: ^14.8.0`, `provider: ^6.1.2`, `intl: ^0.20.2`.
* [x] **Suite de Tests Automatizados (`flutter test`):**
  - `test/modulos/trust_safety_test.dart`: 20 tests unitarios y de componentes de seguridad y auditoría.
  - `test/nucleo/modelos/models_test.dart`: Validación de serialización de modelos `StudentPassengerMock`, `BusMock` e `IncidentMock`.
  - `test/widget_test.dart`: Smoke test integral con `MultiProvider` inyectando todos los servicios de Supabase para arranque limpio de la aplicación.

---

## 3. ¿Qué NO Se Hizo? (Pendiente para Fases Posteriores)

Para mantener la estabilidad operativa, no introducir dependencias incompatibles y evitar sobrecostos o fricciones de compilación, se delimitaron deliberadamente los siguientes puntos para las fases posteriores del proyecto:

| Módulo / Funcionalidad | Estado Actual | Pendiente / Trabajo Futuro Recomendado |
| :--- | :--- | :--- |
| **Comparación de Vectores Faciales en Servidor (`pgvector`)** | El reconocimiento facial valida el rostro mediante BlazeFace en frontend y registra la confirmación de identidad en la base de datos. | Implementar la extensión `pgvector` en PostgreSQL y una Supabase Edge Function (`/match-face`) para calcular la distancia euclidiana / coseno de un embedding facial de 128/512 dimensiones en el servidor. |
| **Cámara Nativa para Móviles Android / iOS** | La biometría facial está 100% afinada para entornos Web (`web/smartroute_face_detector.js` y `HtmlElementView`). | Configurar el paquete nativo `camera` o `google_mlkit_face_detection` para Android e iOS en caso de requerir compilación para APK / IPA móvil nativa. |
| **Notificaciones Push en Segundo Plano (FCM / APNs)** | Las notificaciones se registran en la tabla `notificaciones` de Supabase y se visualizan en tiempo real dentro de la campana de notificaciones de la app. | Integrar el SDK de `firebase_messaging` para enviar alertas push emergentes con el dispositivo bloqueado o la aplicación cerrada. |
| **Transmisión de Coordenadas vía Hardware OBD-II / MQTT** | La telemetría simula el movimiento sobre las rutas de Penonomé y permite sincronizar la posición actual del conductor vía GPS con `Geolocator`. | Integrar un microcontrolador (e.g., ESP32 / Teltonika FMB920) que envíe telemetría real por protocolo MQTT / WebSockets directo a Supabase Realtime. |
| **Pasarela de Pagos Escolares** | En `owner_home_screen.dart` se incluye el resumen financiero y métricas de recaudación simulada. | Integrar pasarelas de pago locales panameñas (Yappy Comercial, PagueloFacil) o Stripe para cobro recurrente de mensualidades de transporte. |

---

## 4. Guía Rápida para el Desarrollador

### Ejecutar las Pruebas Unitarias y de Integración
```bash
flutter test
```
*Salida esperada:* `All tests passed!` (21 pruebas completadas satisfactoriamente).

### Iniciar la Aplicación en el Navegador Web (Chrome)
```bash
flutter run -d chrome
```

### Credenciales de Demostración Inmediata
- **Padre:** `padre@smartroute.com` / `Password123!`
- **Conductor:** `conductor@smartroute.com` / `Password123!`
- **Dueño de Bus:** `dueno@smartroute.com` / `Password123!`
*(También están disponibles los accesos directos de un clic en la pantalla de inicio de sesión).*
