# 🚌 SmartRoute Flutter

SmartRoute es una plataforma integral de confianza (SaaS y Marketplace) diseñada para digitalizar, transparentar y optimizar el **transporte escolar privado e independiente** en Penonomé, Coclé.

Permite a los padres de familia monitorear el trayecto en tiempo real con confirmación biométrica facial de abordaje y selector GPS/OSRM de domicilio, a la vez que dota a los conductores y dueños de flota de herramientas para gestionar cupos, rutas óptimas multi-colegio con Dijkstra + OSRM y telemetría reactiva en vivo.

---

## 📚 Documentación del Proyecto

* 📋 **[Especificación de Requisitos de Software (RF y RNF)](docs/requisitos_smartroute.md)**: Requisitos funcionales, no funcionales (hardware en cabina, privacidad biométrica de menores, tolerancia offline) y matriz de cobertura.
* 🎯 **[Modelo de Negocio y Producto (Pivote)](docs/smartroute_business_model.md)**: Propuesta de valor, monetización SaaS/Marketplace y estrategia de Trust & Safety.
* 🔑 **[Usuarios de Prueba (Seed SQL)](docs/usuarios_prueba.md)**: Cuentas determinísticas activas en `supabase/seed.sql`.
* 🛡️ **[Auditoría de Seguridad y RLS](docs/auditoria_seguridad_rls.md)**: Políticas de acceso y seguridad en Supabase.

---

## 🚀 Arquitectura y Tecnologías

### Frontend (App Móvil y Web)
* **Framework:** Flutter 3.x (Dart 3.x).
* **Arquitectura:** Modular / Feature-First (`lib/nucleo/` y `lib/modulos/`).
* **Navegación:** `go_router` (Soporte declarativo, deep linking y protección de rutas).
* **Gestor de Estado:** `provider` (`SessionManager`, `ChangeNotifier` y servicios inyectados).
* **Mapas y Enrutamiento:** `flutter_map` (OpenStreetMap) + `OsrmRoutingService` (`/route/v1/driving/` y `/nearest/v1/driving/` con fallback offline) + `RouteOptimizerService` (Dijkstra multi-colegio).
* **Permisos GPS:** `GpsPermissionHelper` centralizado sobre `geolocator` para los 3 roles (`student`, `driver`, `owner`).

### Backend y Base de Datos (Supabase + Docker)
* **Base de Datos:** PostgreSQL 17 con Supabase local (`http://127.0.0.1:54321`, compatible con móvil USB vía `adb reverse tcp:54321 tcp:54321`).
* **Extensiones Geoespaciales:** PostGIS (`public.autobuses`, `public.estudiantes_pasajeros`, `public.paradas_ruta`).
* **Tiempo Real (Realtime WebSockets):** `REPLICA IDENTITY FULL` y publicación activa para `autobuses`, `estudiantes_pasajeros`, `paradas_ruta`, `asistencia_diaria`, `incidentes_ruta` y `notificaciones`.
* **Migraciones SQL (`supabase/migrations/` — 9 archivos):**
  1. `20261023000000_schema_smartroute.sql` (esquema inicial y PostGIS)
  2. `20261023000001_auth_triggers.sql` (`handle_new_user()` en `auth.users`)
  3. `20261023000002_incidentes_notificaciones.sql` (`incidentes_ruta` y `notificaciones`)
  4. `20261025000003_allow_anon_hybrid_policies.sql` (políticas RLS híbridas)
  5. `20261025000004_seed_deterministic_demo_users.sql` (usuarios semilla iniciales)
  6. `20261114000005_add_pickup_coordinates_estudiantes.sql` (`latitud_recogida` y `longitud_recogida`)
  7. `20261114000006_enable_realtime_estudiantes_paradas.sql` (Realtime en estudiantes y paradas)
  8. `20261116000007_fix_sequences_and_rls_checks.sql` (resincronización de secuencias `bigserial` y `REPLICA IDENTITY FULL`)
  9. `20261116000008_bus_multi_school_support.sql` (soporte multi-colegio por autobús e índice `(autobus_codigo, colegio)`)

---

## 👥 Estructura de Módulos (Roles) y Capacidades Actuales

1. **👨‍👩‍👧 Padre / Familia (`modulos/padre`):**
   * Rastreo satelital del autobús escolar en vivo con ETA.
   * Selector interactivo de domicilio (`StudentLocationPickerScreen`) con GPS, toque en mapa, formatos DD/DMM/DMS y *snap* a calle vía OSRM.
   * Selector buscable de colegio (`SchoolSelectorField`) adaptativo al teclado virtual con opción comodín **"Otro (especificar colegio)"**.
   * Reporte inmediato de inasistencias (`asistencia_diaria`) con recálculo automático en Conductor y Transportista.
   * Bandeja de alertas en tiempo real (`NotificationsScreen`).

2. **👨‍✈️ Conductor Escolar (`modulos/conductor`):**
   * Flujo de inicio: Bienvenida → `DriverCardSortingScreen` (excluye ausentes y muestra los distintos colegios destino) → `DriverDijkstraRoutingScreen` → `DriverHomeScreen` (cabina con mapa en vivo y monitor CCTV).
   * Motor compartido `RouteOptimizerService` (Dijkstra + OSRM multi-colegio) con recálculo reactivo vía Supabase Realtime al asignarse o modificarse estudiantes/asistencia.
   * Controlador de telemetría `BusTelemetryController` (`TelemetryMode.simulated` con avance real sobre polilínea OSRM a 30–44 km/h, pausa/reanudación, `1x`/`2x` y contrato `TelemetryMode.realGps` listo para GPS físico del chofer), publicando posición y velocidad en `public.autobuses`.
   * Cabecera responsive sin desbordamientos en 360px, manifiesto dinámico (`DriverDemandScreen`), check-in facial/manual, reporte de incidentes y alertas adaptadas al rol Conductor.

3. **🏢 Transportista / Dueño de Flota (`modulos/transportista`):**
   * Panel de flota reactivo (`OwnerHomeScreen`) para registrar autobuses, asignar choferes, auditar Sello de Confianza y matricular/asignar cupos respetando el colegio propio de cada estudiante (`BusService.extractCoveredSchools(...)`).
   * Mapa de flota multi-bus (`OwnerMapScreen`) con paleta determinística de colores por unidad (polilínea, marcador de bus y pines de casas), filtro **multi-selección** (`Todos` + selección de 1, 2 o $N$ buses), marcadores de todos los colegios cubiertos y controles de simulación en vivo sincronizados con `RouteOptimizerService` y `BusTelemetryController`.

---

## 🛠️ Organización del Código Fuente

```text
lib/
 ├── main.dart
 ├── nucleo/                 # Core transversal
 │    ├── constantes/        # AppConstants (centro Penonomé y catálogo penonomeSchools)
 │    ├── modelos/           # BusMock, RouteMock, StopMock, StudentPassengerMock, SchoolLocation
 │    ├── navegacion/        # AppRouter (GoRouter)
 │    ├── servicios/         # Servicios Supabase, OSRM, Dijkstra, Telemetría y GPS:
 │    │    ├── attendance_service.dart
 │    │    ├── auth_service.dart
 │    │    ├── bus_service.dart
 │    │    ├── camera_web_service.dart (+ stub/web)
 │    │    ├── gps_permission_helper.dart
 │    │    ├── incident_service.dart
 │    │    ├── osrm_routing_service.dart
 │    │    ├── route_optimizer_service.dart
 │    │    ├── student_service.dart
 │    │    ├── supabase_client.dart
 │    │    └── telemetry_simulation_service.dart
 │    ├── tema/              # Paleta SmartColors y SmartTheme
 │    ├── utilidades/        # Validadores y CoordinateParser (DD/DMM/DMS)
 │    └── widgets/           # Componentes UI reutilizables (incl. SchoolSelectorField)
 │
 └── modulos/                # Módulos por Dominio de Negocio
      ├── autenticacion/     # Login, registro, PermissionGate y SessionManager
      ├── conductor/         # Card Sorting, Dijkstra, Cabina, Manifiesto, Facial e Incidentes
      ├── padre/             # Seguimiento, ETA, Location Picker, Perfil y Alertas
      ├── transportista/     # Panel de flota, registro de buses y mapa multi-bus
      └── splash/            # Pantalla de bienvenida y arranque
```

---

## 🧪 Pruebas Modulares (`test/modulos/` — 23 pruebas)

* `autenticacion_module_test.dart`: **3** pruebas (sesión, login y registro).
* `conductor_module_test.dart`: **5** pruebas (Card Sorting, Manifiesto, Dijkstra excluyendo ausentes, Check-in facial e Incidentes).
* `nucleo_module_test.dart`: **6** pruebas (arranque, validadores, modelos, OSRM online/offline, `BusService.extractCoveredSchools`, `RouteOptimizerService` y `BusTelemetryController`).
* `padre_module_test.dart`: **5** pruebas (perfil, errores de red, `StudentLocationPickerScreen`, stream `StudentService` y `SchoolSelectorField` con teclado virtual).
* `transportista_module_test.dart`: **4** pruebas (`RegisterBusScreen`, `OwnerHomeScreen`, `TrustSafetyDialog` y `OwnerMapScreen` con colores por bus y filtro multi-selección).

Comandos de verificación:

```bash
flutter analyze --no-pub
flutter test
```
