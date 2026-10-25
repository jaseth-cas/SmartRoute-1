# 🔑 Credenciales y Cuentas de Prueba - SmartRoute

Este documento contiene las cuentas fijas y determinísticas del entorno de desarrollo y pruebas de **SmartRoute**, sincronizadas tanto en `auth.users` como en `public.perfiles` de PostgreSQL / Supabase.

---

## 📋 1. Tabla Resumen de Credenciales

> **Contraseña Maestra para TODOS los usuarios de prueba:**  
> `Password123!`

| Rol en el Sistema | Nombre del Usuario | Correo Electrónico | Contraseña | Pantalla Inicial | UUID Fijo |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **🏢 Dueño de Flota (Transportista)** | Don Fernando Gómez | `dueno@smartroute.com` | `Password123!` | `/owner_home` | `a0000000-0000-0000-0000-000000000001` |
| **👨‍✈️ Conductor Escolar** | Carlos Andrés Gómez | `conductor@smartroute.com` | `Password123!` | `/driver_home` | `b0000000-0000-0000-0000-000000000002` |
| **👨‍👩‍👦 Padre / Tutor (Mateo)** | Carlos Gómez | `padre@smartroute.com` | `Password123!` | `/student_home` | `c0000000-0000-0000-0000-000000000003` |
| **👩‍👧 Madre / Tutora (Sofía)** | Elena Ramírez | `padre2@smartroute.com` | `Password123!` | `/student_home` | `c0000000-0000-0000-0000-000000000004` |

---

## 🚌 2. Asociación de Flota y Estudiantes en Base de Datos

### A. Unidades Escolares (`public.autobuses`)
* **`BUS-01` (Toyota Coaster Escolar - Placa TBX-492):**
  * **Dueño:** Don Fernando Gómez (`a0000000-0000-0000-0000-000000000001`)
  * **Conductor Asignado:** Carlos Andrés Gómez (`b0000000-0000-0000-0000-000000000002`)
  * **Capacidad:** 16 asientos (14 ocupados)
  * **Sello de Confianza (Trust & Safety):** `is_verified: true`
* **`BUS-02` (Nissan Civilian - Placa SKL-810):**
  * **Dueño:** Don Fernando Gómez (`a0000000-0000-0000-0000-000000000001`)
  * **Conductor Asignado:** Disponible
  * **Capacidad:** 20 asientos (18 ocupados)
  * **Sello de Confianza (Trust & Safety):** `is_verified: true`

### B. Pasajeros Asignados (`public.estudiantes_pasajeros`)
* **Mateo Gómez (ID: 1):**
  * **Tutor Legal:** Carlos Gómez (`c0000000-0000-0000-0000-000000000003` / `padre@smartroute.com`)
  * **Autobús:** `BUS-01` (Parada #1)
  * **Colegio:** Colegio San José
* **Sofía Ramírez (ID: 2):**
  * **Tutora Legal:** Elena Ramírez (`c0000000-0000-0000-0000-000000000004` / `padre2@smartroute.com`)
  * **Autobús:** `BUS-01` (Parada #2)
  * **Colegio:** Colegio San José

---

## ⚡ 3. Cómo Re-aplicar o Resetear las Semillas

Si en algún momento reseteas la base de datos local con `npx supabase db reset`, el archivo `supabase/seed.sql` re-insertará de forma automática e inmediata todos estos usuarios con sus identidades y contraseñas.

Para re-aplicar manualmente la semilla sin resetear toda la base de datos:
```powershell
# En Windows PowerShell
Get-Content supabase\seed.sql | docker exec -i supabase_db_smartroute_flutter psql -U postgres -d postgres
```

Para verificar que un usuario puede autenticarse contra el endpoint GoTrue:
```powershell
# Probar inicio de sesión de Dueño de Flota
Invoke-RestMethod -Uri "http://127.0.0.1:54321/auth/v1/token?grant_type=password" `
  -Method Post `
  -Headers @{ "apikey" = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODMxOTM2MDB9.smD6-kGtxxcoDEc_mCHp_TeL_pAUnhk7V3PrGfsq_bE" } `
  -ContentType "application/json" `
  -Body '{"email":"dueno@smartroute.com","password":"Password123!"}'
```
