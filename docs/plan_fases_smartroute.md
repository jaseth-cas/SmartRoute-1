# 🗺️ Plan Maestro de Fases de Implementación - SmartRoute

> **Estado del Proyecto:** Transición de Mock Frontend a Backend PostgreSQL / Supabase Realtime  
> **Fecha de Actualización:** Octubre 2026  
> **Entorno:** Local Docker Desktop + Supabase CLI + Flutter 3.x  

---

## 📊 1. Matriz General de Fases y Estado de Madurez

| Fase | Título y Alcance | Estado | Cobertura RF | Tecnologías / Componentes |
| :---: | :--- | :---: | :---: | :--- |
| **Fase 0** | **Arquitectura Frontend y Maquetación Modular** | <span style="color:green;font-weight:bold;">✅ Completada (100%)</span> | Todos (UI Mock) | Flutter 3.22+, GoRouter, Provider, OpenStreetMap (`flutter_map`) |
| **Fase 1** | **Infraestructura Docker, PostgreSQL y Migraciones** | <span style="color:green;font-weight:bold;">✅ Completada (100%)</span> | RF-01, RF-04, RF-05, RF-08, RF-13 | Docker Desktop, Supabase CLI, PostgreSQL 17, PostGIS, RLS |
| **Fase 2** | **Capa de Servicios y Repositorios Dart en Flutter** | <span style="color:green;font-weight:bold;">✅ Completada (100%)</span> | Transversal | `BusService`, `StudentService`, `AttendanceService`, `IncidentService` |
| **Fase 3** | **Conexión Módulo Transportista (Dueño de Flota / SaaS)** | <span style="color:green;font-weight:bold;">✅ Completada (100%)</span> | RF-04, RF-05, RF-06, RF-07 | Dashboard financiero en vivo, registro de buses, mapa multivehicular |
| **Fase 4** | **Conexión Módulo Conductor y Biometría Facial AI** | <span style="color:green;font-weight:bold;">✅ Completada (100%)</span> | RF-08, RF-09, RF-10, RF-11, RF-12 | Manifiesto dinámico, abordaje facial, omisión de paradas, telemetría GPS |
| **Fase 5** | **Conexión Módulo Padre de Familia y GPS Satelital** | <span style="color:orange;font-weight:bold;">⏳ Próxima a Iniciar</span> | RF-14, RF-15, RF-16, RF-17, RF-18 | Notificación push de abordaje, reporte de inasistencias, mapa en vivo |
| **Fase 6** | **Pruebas E2E, Sello Trust & Safety y Auditoría Final** | <span style="color:gray;font-weight:bold;">⏳ Pendiente</span> | RNF-01 a RNF-12 | RLS, Edge AI offline, validación documental y pruebas cruzadas |

---

## 🛠️ 2. Detalle Exhaustivo de Fases

### ✅ Fase 0: Arquitectura Frontend y Maquetación Modular (COMPLETADA)
* **Objetivo:** Construir una interfaz móvil y desktop rica, fluida y con 0 warnings que refleje fielmente el modelo de transporte escolar privado.
* **Componentes Implementados:**
  * **Sistema de Roles Dinámico:** Enrutamiento declarativo con `GoRouter` y guards de sesión según rol (`student`, `driver`, `owner`).
  * **Módulo Padre:** Pantalla principal con estatus del alumno, mapa interactivo OpenStreetMap, visualización de rutas, paradas y perfil.
  * **Módulo Conductor:** Pantalla de cabina, diálogo de reconocimiento facial biométrico con HUD animado (`FacialBoardingDialog`), manifiesto de estudiantes y reporte de incidentes.
  * **Módulo Transportista:** Panel de control de flota, KPIs de ocupación y recaudación de mensualidades, mapa multivehicular con seguimiento satelital y formulario de alta de autobuses.
  * **Calidad de Código:** Depuración completa de warnings de Flutter 3.22+ (`onPopInvokedWithResult`), colores institucionales en `SmartColors` y componentes atómicos reutilizables.

---

### 🚀 Fase 1: Infraestructura Docker, PostgreSQL y Migraciones (EN EJECUCIÓN / COMPLETADA)
* **Objetivo:** Desplegar localmente el stack completo de Supabase mediante Docker Desktop y configurar el esquema relacional con seguridad RLS y capacidades Realtime.
* **Entregables de Base de Datos:**
  * **Configuración del CLI:** Archivo `supabase/config.toml` con puertos asignados (`54321` API, `54322` DB, `54323` Studio).
  * **Migración Base (`20261023000000_schema_smartroute.sql`):**
    * Extensión geoespacial `postgis`.
    * Tabla `public.perfiles`: Identidad de usuarios con roles y números de contacto.
    * Tabla `public.autobuses`: Unidades de transporte escolar con coordenadas GPS, placa, capacidad y conductor asignado.
    * Tabla `public.estudiantes_pasajeros`: Menores matriculados, colegios, direcciones de recogida y cuotas de pago.
    * Tabla `public.asistencia_diaria`: Estado diario (`waiting`, `onboard`, `delivered`, `absent`), hora y método de abordaje.
    * Tabla `public.paradas_ruta`: Puntos de detención secuenciales.
    * Publicación `supabase_realtime` para streaming en vivo de `autobuses` y `asistencia_diaria`.
  * **Triggers de Autenticación (`20261023000001_auth_triggers.sql`):**
    * Sincronización automática entre `auth.users` y `public.perfiles` extrayendo el rol y nombre desde metadata.
  * **Migración de Notificaciones e Incidentes (`20261023000002_incidentes_notificaciones.sql`):**
    * Tabla `public.incidentes_ruta`: Alertas viales y mecánicas reportadas por conductores.
    * Tabla `public.notificaciones`: Alertas push de abordaje y avisos escolares para padres y dueños con soporte WebSocket Realtime.
  * **Datos Semilla (`seed.sql`):** Inserción de autobuses de prueba, estudiantes reales con direcciones y estados matutinos de asistencia.

---

### ✅ Fase 2: Capa de Servicios y Repositorios Dart en Flutter (COMPLETADA)
* **Objetivo:** Eliminar el acoplamiento a `MockData` y construir repositorios desacoplados que consuman Supabase REST y Realtime WebSockets.
* **Módulos y Clases Implementados (`lib/nucleo/servicios/`):**
  1. `BusService`:
     * `Future<void> registerBus(BusModel bus)` -> `INSERT` en `public.autobuses`.
     * `Future<List<BusModel>> getOwnerBuses(String ownerId)` -> Consulta con RLS.
     * `Future<BusModel?> getDriverBus(String driverId)` -> Busca unidad asignada al chofer.
     * `Stream<BusLocationUpdate> streamBusLocation(String busCode)` -> Escucha en tiempo real cambios de latitud/longitud.
  2. `AttendanceService`:
     * `Future<void> recordBoarding(int studentId, String method)` -> Actualiza a `onboard` con hora actual.
     * `Future<void> reportAbsence(int studentId, bool isAbsent)` -> Alterna entre `absent` y `waiting`.
     * `Stream<List<AttendanceRecord>> streamDailyAttendance(String busCode)` -> Notifica al chofer y padre al instante.
  3. `StudentService`:
     * `Future<List<StudentPassengerMock>> getStudentsByBus(String busCode)` -> Carga el manifiesto escolar.
     * `Future<StudentPassengerMock?> getStudentByParent(String parentId)` -> Carga el alumno vinculado al padre.
  4. `NotificationService`:
     * `Future<void> reportIncident({busCode, tipo, titulo, descripcion})` -> Inserta en `incidentes_ruta`.
     * `Stream<List<NotificationMock>> streamNotifications(String? userId)` -> Notificaciones push en tiempo real.

---

### ✅ Fase 3: Conexión Módulo Transportista / Dueño de Flota (COMPLETADA)
* **Objetivo:** Conectar las interfaces SaaS del transportista con los datos reales en PostgreSQL.
* **Componentes y Conexiones Implementados:**
  * **`RegisterBusScreen`:**
    * Conectado a `BusService.registerBus()` persistiendo en `public.autobuses`.
    * Validación en vivo de obligatoriedad, capacidad positiva y unicidad de placa/código.
    * Feedback visual con indicadores de carga y SnackBars de éxito/error.
  * **`OwnerHomeScreen`:**
    * Migrado a componente con estado reactivo (`StatefulWidget`).
    * Métricas financieras reales integradas con `StudentService.getFleetFinancialSummary()`.
    * Listado dinámico de unidades escolares desde PostgreSQL con fallback resiliente.
    * Control de cobro de mensualidades escolares enlazado a `StudentService.getAllStudents()`.
    * Mecanismo de recarga suave "Pull-to-refresh" (`RefreshIndicator`) y botón en AppBar.
  * **`OwnerMapScreen`:**
    * Suscrito al stream WebSocket en tiempo real de `BusService.streamAllBuses()`.
    * Proyección de marcadores interactivos para toda la flota en OpenStreetMap.
    * Selector horizontal deslizable de unidades con centrado automático de cámara.
    * Indicador dinámico de estado telemático ("Realtime Conectado / GPS Satelital").

---

### ✅ Fase 4: Conexión Módulo Conductor y Biometría Facial AI (COMPLETADA)
* **Objetivo:** Habilitar la operativa en cabina, el manifiesto dinámico, el abordaje biométrico facial en tiempo real y la telemetría GPS continua hacia Supabase PostgreSQL.
* **Componentes y Conexiones Implementados:**
  * **`DriverHomeScreen`:**
    * Carga de unidad escolar asignada (`BUS-01`) y ruta desde `BusService.getBusByCode()`.
    * Monitorización reactiva de asistencia diaria mediante `AttendanceService.streamTodayAttendance()`.
    * Indicadores en vivo de capacidad, alumnos a bordo y alumnos en espera.
    * Transmisor de telemetría GPS en tiempo real emitiendo cambios periódicos a `public.autobuses.latitud_actual / longitud_actual`.
    * Banner inteligente de advertencia por inasistencias reportadas (RF-11) detallando paradas omitidas para ahorro de combustible.
  * **`DriverDemandScreen` (Manifiesto de Pasajeros):**
    * Secuenciación de alumnos ordenada por parada (`#1`, `#2`, `#3`, etc.) vía `StudentService.getStudentsByBus()`.
    * Soporte dual de abordaje: Terminal Facial AI y Check-in Manual de Contingencia (RF-10).
    * Acción de confirmación de entrega segura en colegio (`checkOutPassenger`).
    * Filtros rápidos por estado (`Todos`, `En espera`, `A bordo`, `Ausentes`) y pull-to-refresh.
  * **`FacialBoardingDialog` (Killer Feature Edge ML):**
    * Integración de coincidencia biométrica simulada (99.4% confianza) con `AttendanceService.checkInPassenger()`.
    * Persistencia instantánea en `public.asistencia_diaria` con método `"Biometría Facial AI"` y broadcast WebSocket Realtime.
  * **`ReportIncidentScreen`:**
    * Formulario de contingencias en ruta enlazado con `IncidentService.reportIncident()`.
    * Registro en `public.incidentes_ruta` con tipo de evento (`Mecánico`, `Tráfico`, `Accidente`, `Otro`) y notificación push broadcast.

---

### ⏳ Fase 5: Conexión Módulo Padre de Familia y GPS Satelital (PENDIENTE)
* **Objetivo:** Brindar a los tutores la máxima transparencia y tranquilidad en el trayecto de sus hijos.
* **Tareas Específicas:**
  * **`StudentHomeScreen`:**
    * Vincular dinámicamente la tarjeta del estudiante al hijo asociado al `padre_id` del usuario autenticado.
    * Suscribirse en tiempo real a la columna `estado` de `asistencia_diaria`: cuando el chofer escanea al alumno, el padre ve cambiar su pantalla a *"A bordo del bus"* instantáneamente.
  * **Botón de Inasistencia:**
    * Conectar `_toggleAbsence` a `AttendanceService.reportAbsence()` para que el cambio impacte de inmediato en la base de datos y al chofer.
  * **`SimulatedMapScreen` (Rastreo Satelital en Vivo):**
    * Sustituir el temporizador en bucle por el stream de coordenadas del autobús escolar en `public.autobuses`.
  * **`EditProfileScreen`:**
    * Conectar la edición de nombre y teléfono con la tabla `public.perfiles`.

---

### ⏳ Fase 6: Aseguramiento de Calidad, Sello Trust & Safety y Auditoría Final (PENDIENTE)
* **Objetivo:** Validación integral de seguridad, aislamiento de datos y resiliencia offline.
* **Tareas Específicas:**
  * **Auditoría de Políticas RLS:** Comprobar que un padre no pueda leer la ubicación de autobuses donde no tiene hijos matriculados.
  * **Pruebas de Concurrencia y ADB Reverse:** Validar el túnel `adb reverse tcp:54321 tcp:54321` para pruebas en teléfonos físicos conectados por USB.
  * **Sello de Confianza:** Flujo de validación documental del transportista para certificar antecedentes penales y RTM de conductores.
  * **Análisis estático:** `flutter analyze` y `flutter test` con 100% de éxito.

---

## 💻 3. Guía Rápida de Comandos para el Desarrollador

```bash
# Iniciar stack local de Supabase (Docker)
npx supabase start

# Ver estado de los contenedores y URLs de servicios
npx supabase status

# Reiniciar y aplicar todas las migraciones con datos semilla
npx supabase db reset

# Habilitar conexión con teléfono Android físico conectado por USB
adb reverse tcp:54321 tcp:54321

# Ejecutar la aplicación en Flutter
flutter run
```
