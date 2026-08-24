# 🚌 SmartRoute

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**SmartRoute** es un prototipo interactivo de sistema de gestión de transporte universitario desarrollado en Flutter. Su objetivo principal es simular el seguimiento, administración y uso de rutas de autobuses desde la perspectiva de diferentes actores clave del sistema (Estudiantes, Conductores, Transportistas y Administradores).

## ✨ Características Principales

El proyecto cuenta con un sistema robusto de navegación y manejo de roles, ofreciendo una experiencia distinta dependiendo del tipo de usuario que inicie sesión:

*   🎓 **Módulo de Estudiantes:** 
    *   Visualización de rutas disponibles.
    *   Mapa interactivo con seguimiento GPS simulado de autobuses en tiempo real.
    *   Cálculo del Tiempo Estimado de Llegada (ETA).
    *   Notificaciones de proximidad.
*   👨‍💼 **Módulo de Administrador:** 
    *   Gestión (CRUD simulado) de Rutas, Paradas y Autobuses.
    *   Asignación de rutas y paradas.
*   🚌 **Módulo de Transportista (Dueño):** 
    *   Monitoreo global de la flota en un mapa en tiempo real.
    *   Registro de nuevas unidades (buses) al sistema.
*   🧑‍✈️ **Módulo de Conductor:** 
    *   Activación/Desactivación del GPS.
    *   Mapa de calor de demanda (paradas con más estudiantes esperando).

## 🛠️ Tecnologías y Arquitectura

*   **Framework:** Flutter
*   **Lenguaje:** Dart
*   **Gestión de Estado:** `provider` (Manejo de sesión y cambios de interfaz reactivos).
*   **Enrutamiento:** `go_router` (Navegación declarativa y profunda).
*   **Base de Datos (Prototipo):** Datos en memoria (`MockData`) diseñados para ser fácilmente reemplazados por una API REST o Firebase en el futuro.

## 🚀 Instalación y Ejecución

Sigue estos pasos para correr el prototipo localmente en tu computadora:

1.  Clona este repositorio:
    ```bash
    git clone https://github.com/jaseth-cas/SmartRoute-1.git
    ```
2.  Entra a la carpeta del proyecto:
    ```bash
    cd SmartRoute-1
    ```
3.  Instala las dependencias necesarias:
    ```bash
    flutter pub get
    ```
4.  Ejecuta la aplicación en tu emulador o dispositivo físico:
    ```bash
    flutter run
    ```

## 🔐 Cuentas de Prueba (Simuladas)

Al iniciar la aplicación, selecciona cualquier rol en el menú principal. El sistema utilizará un manejador de sesión falso (`FakeJwtProvider`) para asignarte una identidad según tu elección:
- **Estudiante:** Ana Martínez
- **Administrador:** Admin SmartRoute
- **Transportista:** Transporte Universitario Penonomé
- **Conductor:** Carlos Pérez

---
*Desarrollado con ❤️ para mejorar la movilidad estudiantil.*
