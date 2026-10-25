# 📋 Especificación de Requisitos de Software (SRS) - SmartRoute

> **Plataforma Integral de Confianza, Logística y Biometría para Transporte Escolar Independiente**  
> *Versión del Documento:* 2.0 (Post-Pivote Arquitectónico)  
> *Fecha de emisión:* Octubre 2026  
> *Estado:* Aprobado para Implementación  

---

## 🎯 1. Introducción y Propósito del Software

**SmartRoute** es una solución tecnológica integral (SaaS y Marketplace) orientada a formalizar y optimizar el transporte escolar privado e independiente. 

Resuelve la falta de visibilidad y desconfianza de los **padres de familia** respecto a la seguridad de sus hijos, a la vez que dota a los **dueños de flotas** y **conductores** de herramientas para gestionar cupos de asientos, cobro de mensualidades, optimización de trayectos y verificación biométrica de abordaje con Inteligencia Artificial.

---

## 👥 2. Actores del Sistema

| Código | Actor | Rol y Responsabilidad |
| :--- | :--- | :--- |
| **ACT-01** | **Padre / Tutor Legal** | Usuario final que contrata el servicio, registra al estudiante, monitorea el trayecto en vivo, reporta inasistencias y supervisa los cobros. |
| **ACT-02** | **Conductor Escolar** | Operador detrás del volante. Valida la subida/bajada de estudiantes mediante reconocimiento facial o manual, recibe alertas de ausencias y transmite telemetría GPS. |
| **ACT-03** | **Transportista / Dueño de Flota** | Proveedor principal y cliente SaaS. Administra sus autobuses, cupos, cobra mensualidades, y **es el validador oficial del Sello de Confianza (Trust & Safety)** auditando la documentación legal, récord policivo y revisión técnica (RTM) de los choferes que contrata. |

---

## ⚙️ 3. Requisitos Funcionales (RF)

### 🔐 Módulo A: Identidad, Roles y Perfiles

* #### **RF-01: Autenticación Basada en Roles**
  * **Descripción:** El sistema debe permitir iniciar sesión y registrarse mediante correo/contraseña o token seguro, direccionando automáticamente al usuario a su interfaz correspondiente (`Padre`, `Conductor` o `Transportista`).
  * **Actores:** Todos.
  * **Prioridad:** Alta (Crítica).

* #### **RF-02: Gestión de Perfil de Padre y Estudiantes Asociados**
  * **Descripción:** El padre podrá registrar y editar la información de sus hijos (nombre, colegio de destino, dirección exacta de recogida/retorno, teléfono de emergencia y fotografía base para biometría).
  * **Actores:** ACT-01 (Padre).
  * **Prioridad:** Alta.

* #### **RF-03: Onboarding y Verificación Documental de Conductores por el Dueño**
  * **Descripción:** El Dueño de Flota podrá registrar o recibir las solicitudes de conductores contratados, auditando en su panel sus documentos obligatorios (licencia de conducir comercial, récord policivo / antecedentes penales, y revisión técnica vehicular) antes de asignarlos a una ruta y otorgarles el distintivo de conductor verificado.
  * **Actores:** ACT-02 (Conductor), ACT-03 (Dueño de Flota).
  * **Prioridad:** Alta.

---

### 🚌 Módulo B: Gestión de Flota, Cupos y Finanzas (Dueño / SaaS)

* #### **RF-04: Registro y Configuración de Unidades Escolares**
  * **Descripción:** El dueño de flota podrá dar de alta autobuses definiendo código de unidad, número de placa, modelo, colegio asociado y capacidad total de asientos (`max_capacity`).
  * **Actores:** ACT-03 (Dueño de Flota).
  * **Prioridad:** Alta.

* #### **RF-05: Gestión de Cupos y Asignación de Pasajeros**
  * **Descripción:** El sistema debe controlar el aforo por autobús, impidiendo sobrecupos y vinculando formalmente cada estudiante inscrito a un asiento físico dentro de una unidad determinada.
  * **Actores:** ACT-03 (Dueño de Flota).
  * **Prioridad:** Alta.

* #### **RF-06: Panel Financiero y Control de Mensualidades**
  * **Descripción:** Dashboard consolidado para el transportista que calcula:
    * Total de ingresos recaudados vs. ingresos pendientes del mes.
    * Tasa porcentual de ocupación de la flota.
    * Listado de tutores con cuotas "Al día" o "En mora".
  * **Actores:** ACT-03 (Dueño de Flota).
  * **Prioridad:** Media / Alta.

* #### **RF-07: Monitoreo Multivehicular de Flota en Vivo**
  * **Descripción:** Mapa interactivo con soporte geoespacial que proyecta la ubicación de todos los autobuses de la flota en tiempo real, identificando chofer asignado, velocidad y estado de servicio.
  * **Actores:** ACT-03 (Dueño de Flota).
  * **Prioridad:** Alta.

---

### 👨‍✈️ Módulo C: Operativa del Conductor y Abordaje Inteligente

* #### **RF-08: Manifiesto Dinámico de Pasajeros del Día**
  * **Descripción:** El conductor dispondrá de una lista ordenada cronológicamente con las paradas de recogida y entrega, visualizando datos del estudiante, tutor y teléfono de contacto directo.
  * **Actores:** ACT-02 (Conductor).
  * **Prioridad:** Alta.

* #### **RF-09: Terminal de Abordaje Biométrico con IA (AI Facial Boarding)**
  * **Descripción:** La cámara del dispositivo en cabina detectará el rostro del estudiante al subir y, tras verificar coincidencia con el perfil, marcará automáticamente su estado como *"A bordo del bus"* registrando fecha y hora exacta.
  * **Actores:** ACT-02 (Conductor).
  * **Prioridad:** Alta (Killer Feature).

* #### **RF-10: Check-in Manual de Contingencia**
  * **Descripción:** En caso de que la iluminación, mascarilla o ángulo impidan el reconocimiento facial, el conductor podrá confirmar el abordaje de forma manual con un toque en el manifiesto.
  * **Actores:** ACT-02 (Conductor).
  * **Prioridad:** Alta.

* #### **RF-11: Recálculo Inteligente de Ruta por Inasistencias**
  * **Descripción:** Si un tutor reporta que su hijo no asiste, el sistema debe alertar al conductor y omitir automáticamente la parada de ese alumno del itinerario GPS, reduciendo tiempos de trayecto y gasto de gasolina.
  * **Actores:** ACT-02, ACT-01.
  * **Prioridad:** Alta.

* #### **RF-12: Transmisión Telemática de Ubicación GPS**
  * **Descripción:** El dispositivo del conductor emitirá periódicamente coordenadas geoespaciales precisas al servidor durante la ejecución de la ruta activa.
  * **Actores:** ACT-02 (Conductor).
  * **Prioridad:** Alta.

* #### **RF-13: Reporte de Incidentes en Ruta**
  * **Descripción:** El conductor podrá emitir alertas rápidas (avería mecánica, tráfico severo, desvío de emergencia) que notifiquen de forma masiva e instantánea a todos los padres de la ruta.
  * **Actores:** ACT-02 (Conductor).
  * **Prioridad:** Media.

---

### 👨‍👩‍👧 Módulo D: Experiencia del Padre de Familia

* #### **RF-14: Rastreo Satelital del Autobús en Vivo**
  * **Descripción:** El padre podrá abrir el mapa satelital interactivo y visualizar la ubicación exacta del autobús escolar aproximándose a su domicilio o en dirección al colegio.
  * **Actores:** ACT-01 (Padre).
  * **Prioridad:** Alta.

* #### **RF-15: Notificación Push de Confirmación de Abordaje (Prueba de Vida)**
  * **Descripción:** Al momento exacto en que el menor es reconocido facialmente al subir o bajar, el padre recibirá una notificación push inmediata indicando hora, ubicación y confirmación de seguridad.
  * **Actores:** ACT-01 (Padre).
  * **Prioridad:** Alta (Killer Feature).

* #### **RF-16: Reporte de Inasistencias con un Solo Toque**
  * **Descripción:** Botón directo en la pantalla de inicio del padre que permite declarar la ausencia del estudiante para el recorrido de la mañana o de la tarde antes de que el bus inicie el tramo.
  * **Actores:** ACT-01 (Padre).
  * **Prioridad:** Alta.

* #### **RF-17: Cálculo de ETA y Alerta de Proximidad**
  * **Descripción:** El sistema calculará el tiempo estimado de llegada a la parada y alertará al padre cuando el vehículo se encuentre a menos de 5 o 10 minutos de distancia.
  * **Actores:** ACT-01 (Padre).
  * **Prioridad:** Media.

* #### **RF-18: Consulta de Suscripción y Estado de Cuenta**
  * **Descripción:** El tutor podrá consultar el monto de la mensualidad escolar, fecha límite de pago y el estado de vigencia del cupo de su representado.
  * **Actores:** ACT-01 (Padre).
  * **Prioridad:** Media.

---

## 🛡️ 4. Requisitos No Funcionales (RNF)

> **Nota Crítica:** Los RNF abarcan todas las condiciones técnicas, legales, físicas, de hardware y operativas indispensables para que la solución funcione en el mundo real, más allá de la pantalla del software.

### ⚖️ 4.1. Legalidad, Privacidad y Tratamiento de Datos de Menores

* #### **RNF-01: Protección Criptográfica de Biometría Facial (No almacenar fotos en crudo)**
  * **Requisito:** El sistema **no debe** almacenar archivos de imágenes fotográficas reales de menores en bases de datos vulnerables o accesibles por internet.
  * **Implementación:** La foto original se procesará localmente o mediante microservicio aislado para extraer un vector numérico unidireccional (*face embedding* de 128 o 512 dimensiones). Solo los vectores matemáticos cifrados (AES-256) serán persistidos en la base de datos relacional.

* #### **RNF-02: Consentimiento Parental Digital Expreso**
  * **Requisito:** Cumplimiento con legislaciones de protección de datos personales de menores. Ningún registro de menor podrá completarse sin la aceptación expresa y trazable (con timestamp e IP) de los Términos de Servicio y Autorización de Tratamiento Biométrico por parte del tutor legal.

---

### 📶 4.2. Tolerancia a Fallos, Edge AI y Modo Offline

* #### **RNF-03: Reconocimiento Facial en el Borde (Offline Edge Computing)**
  * **Requisito:** El escaneo facial en la terminal del conductor debe funcionar de manera 100% autónoma en el dispositivo móvil/tablet sin requerir conexión a internet activa en ese instante (útil en zonas rurales o puntos ciegos de cobertura celular).
  * **Implementación:** Los *embeddings* de los estudiantes asignados a la ruta se sincronizan localmente en la memoria SQLite/Hive del dispositivo al inicio del día. El modelo de inferencia local (ej. Google ML Kit / TFLite) ejecuta la comparación *on-device*.

* #### **RNF-04: Sincronización en Cola Asíncrona (Queue & Retry)**
  * **Requisito:** Los eventos de abordaje capturados sin red se almacenarán en una cola de persistencia local y se sincronizarán automáticamente con Supabase en cuanto el dispositivo recupere señal 4G/LTE.

---

### 🏎️ 4.3. Rendimiento, Concurrencia y Latencia

* #### **RNF-05: Latencia de Inferencia Biométrica (< 1.2 segundos)**
  * **Requisito:** El tiempo total desde que la cámara enfoca el rostro del menor hasta que emite el sonido de confirmación visual/auditivo no debe superar 1.2 segundos, previniendo congestiones o filas al abordar el vehículo escolar.

* #### **RNF-06: Latencia de Telemetría GPS (< 4 segundos)**
  * **Requisito:** La posición del vehículo en los mapas de padres y dueños debe actualizarse con un retraso máximo de 3 a 5 segundos bajo condiciones estándar de red móvil.

* #### **RNF-07: Resiliencia ante Picos de Tráfico Escolar**
  * **Requisito:** La infraestructura backend (Supabase / PostgreSQL) debe soportar concurrencia masiva concentrada en dos ventanas horarias pico diarias (6:00 AM - 8:30 AM y 1:30 PM - 4:30 PM), manteniendo tiempos de respuesta de API por debajo de 300 ms.

---

### 📱 4.4. Hardware Vehicular y Condiciones de Instalación (Entorno Físico)

* #### **RNF-08: Especificaciones de Dispositivo en Cabina (Terminal del Conductor)**
  * **Requisito:**
    * Dispositivo Android (versión 10+) o iOS (15+) con procesador Octa-Core y mínimo 3 GB de memoria RAM.
    * Cámara frontal de al menos 8 MP con autoenfoque y buen comportamiento en condiciones de baja/alta luminosidad matutina.
    * Módulo satelital GNSS compatible con GPS y GLONASS con precisión menor a 5 metros.

* #### **RNF-09: Soporte Físico y Alimentación Continua en el Autobús**
  * **Requisito:** El autobús debe contar con un soporte rígido vehicular industrial anti-vibración instalado en el tablero o mampara de acceso a la altura promedio de los alumnos (1.10 m - 1.40 m), con toma de carga de 12V a 5V/3A continuo para evitar que el dispositivo se descargue por el uso intensivo de GPS y pantalla encendida.

---

### 🛡️ 4.5. Seguridad de Software y Control de Accesos

* #### **RNF-10: Cifrado Extremo a Extremo en Tránsito**
  * **Requisito:** Todas las peticiones HTTP y canales de WebSocket para streaming GPS deben transmitirse bajo protocolos TLS 1.3 con certificados SSL válidos.

* #### **RNF-11: Seguridad a Nivel de Filas (Row-Level Security - RLS)**
  * **Requisito:** En la base de datos PostgreSQL/Supabase, las políticas de RLS deben garantizar estrictamente que:
    * Un padre **únicamente** pueda consultar la ubicación del autobús y los datos del estudiante del cual es tutor legal.
    * Un conductor **únicamente** acceda a los estudiantes asignados a su unidad de transporte activa.
    * Un transportista **únicamente** visualice las unidades y cobros que pertenezcan a su propia empresa o flota.

---

### 📋 4.6. Verificación Operativa y "Sello de Confianza" (Proceso Humano / Trust & Safety)

* #### **RNF-12: Proceso de Certificación y Sello de Confianza (Responsabilidad del Transportista)**
  * **Requisito:** El Dueño de Flota, como operador comercial y legal responsable ante los padres de familia, debe validar obligatoriamente antes de asignar un chofer a un autobús escolar:
    1. Antecedentes judiciales y récord policivo limpio del conductor.
    2. Licencia de conducir comercial vigente y apta para transporte de menores.
    3. Póliza de seguro con cobertura de accidentes a pasajeros / escolares.
    4. Certificado de Revisión Técnica y Mecánica (RTM) con vigencia no mayor a 6 meses.

---

## 📊 5. Matriz de Cobertura: Estado Actual vs. Backend Implementado

| Módulo / Requisito | Estado en Frontend | Conexión Backend (Supabase / PostgreSQL) | Estado Final |
| :--- | :---: | :---: | :---: |
| **RF-01: Auth & Roles** | ✅ Conectado (`login_screen.dart`) | Conectado a Supabase Auth + tabla `perfiles` | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **RF-04: Registro Autobuses** | ✅ Conectado (`register_bus_screen.dart`) | `INSERT` en tabla `autobuses` con validaciones | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **RF-06: Métricas y Cobros** | ✅ Conectado (`owner_home_screen.dart`) | `StudentService.getFleetFinancialSummary()` en vivo | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **RF-07: Mapa de Flota Dueño** | ✅ Conectado (`owner_map_screen.dart`) | Suscripción WebSocket Realtime a `autobuses` | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **RF-09: Abordaje Facial AI** | ✅ Conectado (`facial_boarding_dialog.dart`) | Persistencia y broadcast en `asistencia_diaria` | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **RF-11: Inasistencias Alumno** | ✅ Conectado (`student_home_screen.dart`) | `AttendanceService.reportAbsence()` en tiempo real | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **RF-14: Mapa GPS Padre** | ✅ Conectado (`simulated_map_screen.dart`) | Stream satelital reactivo desde `BusService` | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **RF-03/RNF-12: Trust & Safety** | ✅ Conectado (`trust_safety_dialog.dart`) | Certificación documental de chofer y RTM | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |
| **Warnings Flutter 3.22+** | ✅ **Completado:** 0 advertencias, 0 errores | `flutter analyze` y `flutter test` con 100% éxito | <span style="color:green;font-weight:bold;">✅ 100% Completado</span> |

---

## 📌 6. Conclusión del Proyecto

Todas las fases de desarrollo (Fase 0 a Fase 6) han sido completadas con éxito, verificadas mediante pruebas automáticas y validadas de extremo a extremo en navegador.
