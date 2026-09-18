# SmartRoute Flutter

SmartRoute es una aplicación móvil diseñada para el rastreo en tiempo real y la gestión de rutas de autobuses (como transporte universitario o rutas privadas). Permite a los usuarios visualizar la ubicación exacta de los autobuses, estimar tiempos de llegada (ETA) y gestionar operaciones desde diferentes perfiles.

## 🚀 Arquitectura y Tecnologías

### Frontend (App Móvil)
- **Framework:** Flutter (Dart).
- **Arquitectura:** Modular / Feature-First (Separación por módulos funcionales).
- **Enrutamiento:** GoRouter (Deep linking y navegación declarativa).
- **Estado:** Provider (Gestión de estado de sesiones).

### Backend y Base de Datos (Proyectado)
- **Base de Datos:** PostgreSQL.
- **Sistema Geoespacial:** PostGIS (Extensión de PostgreSQL utilizada específicamente para procesar, guardar y consultar las coordenadas GPS de los autobuses en tiempo real con alta eficiencia).

---

## 🧩 Estructura de Módulos (Roles)

La aplicación cuenta con diferentes vistas y capacidades dependiendo del rol con el que se inicie sesión:

1. **🧑‍🎓 Estudiante (Usuario Normal):**
   - Rastreo de autobuses en el mapa en tiempo real.
   - Cálculo de Tiempos Estimados de Llegada (ETA) a las paradas.
   - Notificaciones de cercanía de la ruta.
   - Edición de perfil de usuario.

2. **👨‍✈️ Conductor (Driver):**
   - Transmisión de coordenadas GPS (PostGIS).
   - Visualización de la demanda actual de pasajeros en las paradas.
   - Reporte rápido de incidentes.

3. **🏢 Administrador (Admin):**
   - Gestión y creación de **Rutas**.
   - Asignación de **Paradas** a rutas específicas.
   - Gestión de conductores y vinculación con la flota.

4. **🚌 Propietario (Owner):**
   - Registro y gestión técnica de sus **Autobuses** (Capacidad, modelo, placas).
   - Mapa de monitoreo general de su flota exclusiva.

---

## 🛠️ Organización del Proyecto

El código fuente está estructurado de la siguiente manera para escalar fácilmente:

```text
lib/
 ├── main.dart
 ├── nucleo/                 # Core (Compartido por toda la app)
 │    ├── modelos/           # Modelos de datos de negocio
 │    ├── navegacion/        # AppRouter (GoRouter)
 │    ├── tema/              # Colores y tipografías globales
 │    ├── utilidades/        # Validadores, Helpers
 │    └── widgets/           # Componentes UI reutilizables (CustomTextField, Buttons)
 │
 └── modulos/                # Funcionalidades por Dominio (Features)
      ├── admin/
      ├── autenticacion/
      ├── conductor/
      ├── estudiante/
      ├── propietario/
      └── splash/
```

## 🧪 Pruebas (Testing)

El proyecto incluye pruebas de caja blanca para garantizar la estabilidad de las reglas de negocio, como la validación de correos electrónicos y contraseñas.
Para ejecutar las pruebas:
```bash
flutter test
```
