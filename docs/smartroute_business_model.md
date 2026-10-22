# 🚌 Proyecto SmartRoute: Plan de Negocio y Producto (Pivote)

Este documento sirve para madurar la visión de SmartRoute, pasando de ser un software tradicional para escuelas, a convertirse en una **Plataforma de Confianza (SaaS/Marketplace) para Transportistas Independientes**.

---

## 🎯 1. Visión General y Propuesta de Valor

**El Problema:** El transporte escolar privado (independiente) es altamente informal. Los padres sufren por la falta de transparencia y seguridad (no saben si el bus ya pasó o si el conductor es confiable). Los dueños de buses sufren para administrar los cobros, los cupos disponibles y a sus choferes contratados.

**La Solución (SmartRoute):** Una plataforma integral que conecta a padres con transportistas verificados, garantizando la seguridad del menor mediante tecnología de punta (biometría) y digitalizando toda la operación logística y financiera del transportista.

---

## 👥 2. Actores y Módulos del Sistema

Para que el modelo funcione, la arquitectura debe soportar 3 perfiles principales:

### A. El Dueño de Flota (Módulo Admin/Web)
Es el cliente principal o "proveedor". Puede tener desde 1 hasta 10 autobuses.
*   **Gestión de Flota:** Monitoreo en tiempo real (GPS) de todos sus vehículos y choferes en el mapa.
*   **Gestión de Cupos y Rutas:** Define cuántos asientos tiene cada bus. Asigna a los estudiantes a rutas específicas.
*   **Finanzas:** Panel de control para ver qué padres han pagado la mensualidad y quiénes están en mora.

### B. El Conductor (Módulo App Conductor)
Puede ser el mismo dueño o un empleado contratado por el dueño.
*   **Onboarding Estricto:** Subida de documentos (Licencia de conducir, antecedentes penales, revisión técnica del vehículo) para ser verificados por la plataforma.
*   **Modo Ruta:** Navegación GPS optimizada con las paradas del día.
*   **Terminal de Abordaje:** Su celular o tablet actúa como escáner de reconocimiento facial al subir/bajar estudiantes.

### C. El Padre de Familia / Estudiante (Módulo App Usuario)
Es el usuario final que exige seguridad y conveniencia.
*   **Rastreo y Alertas:** Ve el bus acercarse en tiempo real. Recibe notificaciones push.
*   **Prueba de Vida (Abordaje):** Recibe la confirmación biométrica de que el niño abordó el bus correcto.
*   **Pagos y Reserva:** Paga la suscripción mensual (el cupo) directamente desde la app con tarjeta o transferencia.

---

## ⭐ 3. Características Clave (Killer Features)

### 🛡️ Trust & Safety (Confianza y Seguridad)
SmartRoute no permite que cualquiera sea conductor. El proceso de registro requiere validación manual o automatizada de documentos. Esto convierte a la app en un sello de calidad que los padres buscarán activamente.

### 💺 Gestión de Cupos (Seat Management)
El modelo de negocio del transportista se basa en ocupar todos los asientos.
*   Los padres compran/reservan un "cupo" mensual.
*   Si un niño reporta "ausencia" (ej. está enfermo) a través de la app, el sistema recalcula la ruta del conductor para ahorrarle tiempo y combustible, ya que no tiene que pasar por esa casa.

### 👤 Biometría Facial Inteligente (AI Boarding)
Reemplaza los códigos QR o tarjetas RFID (que los niños pierden o rompen).
*   Se requiere que el padre suba una foto del niño al crear el perfil.
*   La app del conductor utiliza Machine Learning local (ej. Google ML Kit) en el dispositivo. Cuando el niño se acerca a la cámara del tablero, hace el "check-in" automáticamente en menos de un segundo.

---

## 💰 4. Modelo de Monetización (Cómo hace dinero SmartRoute)

Al ser una plataforma transaccional, tienes varias vías para generar ingresos:

1.  **SaaS (Suscripción al Transportista):** Cobrar una tarifa fija mensual al dueño por usar el software (ej. $20 - $30 USD al mes por cada autobús registrado en su flota).
2.  **Comisión Transaccional (Marketplace):** Si los padres pagan la mensualidad del transporte a través de tu app (pasarela de pagos), tú puedes cobrar un porcentaje (ej. 3% al 5%) por el procesamiento y conveniencia.
3.  **Verificación de Antecedentes (Fee de entrada):** Cobrar un monto único al transportista por realizarle el estudio de seguridad y verificación de documentos al registrarse.

---

## 🚧 5. Desafíos y Consideraciones Estratégicas

### ⚖️ Privacidad y Legalidad (Datos Biométricos)
*   **El Reto:** Vas a capturar y procesar rostros de menores de edad. Esto está altamente regulado.
*   **La Solución:** Las fotos deben procesarse de forma anónima (creando *embeddings* vectoriales) y no almacenar imágenes reales en bases de datos vulnerables. Se requiere un consentimiento (Términos y Condiciones) firmado digitalmente por los padres al crear la cuenta.

### 📱 Requisitos de Hardware
*   **El Reto:** El reconocimiento facial exige que el conductor tenga un celular o tablet montado en el tablero con buena cámara y luz.
*   **La Solución:** Optimizar el algoritmo para que corra en teléfonos de gama media sin depender de internet (Offline AI). Si se pierde la señal en una zona rural, el abordaje biométrico debe seguir funcionando.

### 🐔 El Huevo y la Gallina (Estrategia de Crecimiento)
*   **El Reto:** Los padres no bajarán la app si no hay buses. Los buses no pagarán por la app si no hay padres que la exijan.
*   **La Solución (Go-to-Market):** Estrategia B2B inicial. Véndele el software al transportista como una herramienta interna para que él gestione su negocio. Él mismo obligará a los padres de sus clientes actuales a descargar la app para recibir las notificaciones y pagar.

---

## 🛠️ 6. Siguientes Pasos Tecnológicos (Plan de Acción en Flutter)

1.  **Integrar ML Kit (Reconocimiento Facial):** Crear un prototipo rápido (PoC) usando `google_ml_kit` en Flutter para probar la velocidad de detección de rostros en la vista del conductor (`driver_home_screen.dart`).
2.  **Lógica de Cupos:** Modificar la base de datos (Firebase/Supabase) para que las Rutas y los Vehículos tengan un atributo `max_capacity` y un sub-cobro de `active_subscriptions`.
3.  **Roles Refinados:** Separar claramente la lógica de `admin` (dueño de flota en un escritorio) de la de `conductor` (operario detrás del volante).
