# 🚌 SmartRoute Flutter

SmartRoute es una plataforma integral de confianza (SaaS y Marketplace) diseñada para digitalizar, transparentar y optimizar el **transporte escolar privado e independiente**. 

Permite a los padres de familia monitorear el trayecto en tiempo real con confirmación biométrica facial de abordaje, a la vez que dota a los conductores y dueños de flota de herramientas para gestionar cupos, cobro de mensualidades y ahorro de recorrido por inasistencias.

---

## 📚 Documentación del Proyecto

* 📋 **[Especificación de Requisitos de Software (RF y RNF)](docs/requisitos_smartroute.md)**: Requisitos funcionales, no funcionales (hardware en cabina, privacidad biométrica de menores, tolerancia offline) y matriz de cobertura.
* 🎯 **[Modelo de Negocio y Producto (Pivote)](docs/smartroute_business_model.md)**: Propuesta de valor, monetización SaaS/Marketplace y estrategia de Trust & Safety.

---

## 🚀 Arquitectura y Tecnologías

### Frontend (App Móvil y Web)
* **Framework:** Flutter 3.x (Dart 3.x).
* **Arquitectura:** Modular / Feature-First (Separación clara por módulos y dominios).
* **Navegación:** `go_router` (Soporte declarativo, deep linking y protección de rutas).
* **Gestor de Estado:** `provider` (Gestión global de sesión y autenticación).
* **Mapas Geoespaciales:** `flutter_map` (OpenStreetMap) con soporte telemático satelital.

### Backend y Base de Datos (Proyectado)
* **Base de Datos:** PostgreSQL con Supabase.
* **Extensiones Geoespaciales:** PostGIS para procesamiento y consulta de coordenadas GPS en tiempo real.
* **Seguridad:** Row-Level Security (RLS) para aislamiento estricto de información de menores entre padres y unidades escolares.

---

## 👥 Estructura de Módulos (Roles)

La aplicación implementa flujos especializados según el rol autenticado:

1. **👨‍👩‍👧 Padre / Familia (`modulos/padre`):**
   * Rastreo satelital del autobús escolar en vivo hacia el domicilio o colegio.
   * Tarjeta de estado de abordaje del estudiante en tiempo real (prueba facial AI).
   * Reporte inmediato de inasistencias con recálculo automático de ruta para el chofer.
   * Estado de suscripción, cuotas mensuales y alertas de proximidad.

2. **👨‍✈️ Conductor Escolar (`modulos/conductor`):**
   * Manifiesto dinámico de estudiantes a recoger y entregar.
   * Terminal interactiva de abordaje biométrico facial (AI Boarding).
   * Notificaciones de ausencias reportadas por padres para omitir paradas (-10 a -15 min de trayecto).
   * Transmisión continua de telemetría y ubicación GPS.

3. **🏢 Transportista / Dueño de Flota (`modulos/transportista`):**
   * Panel de control SaaS con métricas de ocupación de cupos y recaudación del mes.
   * Monitoreo GPS interactivo de toda la flota en OpenStreetMap con telemetría en vivo.
   * Control de cobro de mensualidades escolares (estudiantes al día vs. en mora).
   * Registro y configuración de unidades escolares y conductores.

---

## 🛠️ Organización del Código Fuente

```text
lib/
 ├── main.dart
 ├── nucleo/                 # Core transversal
 │    ├── datos/             # MockData y sincronización local
 │    ├── modelos/           # Entidades de negocio (Bus, Route, StudentPassenger)
 │    ├── navegacion/        # AppRouter (GoRouter con guards de sesión)
 │    ├── tema/              # Paleta SmartColors y SmartTheme
 │    ├── utilidades/        # Validadores de formularios
 │    └── widgets/           # Componentes UI reutilizables
 │
 └── modulos/                # Módulos por Dominio de Negocio
      ├── autenticacion/     # Login, registro y SessionManager
      ├── conductor/         # Manifiesto, terminal facial y modo ruta
      ├── padre/             # Seguimiento escolar, ETA, perfil y ausencias
      ├── transportista/     # Dashboard financiero y mapa de flota
      └── splash/            # Pantalla de bienvenida y verificación
```

---

## 🧪 Pruebas y Calidad de Código

Para verificar la integridad del código y ejecutar el análisis estático de Flutter:

```bash
flutter analyze
flutter test
```
