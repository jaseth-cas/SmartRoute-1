# SmartRoute Flutter - Guardarraíles Permanentes del Proyecto

Estas reglas son obligatorias en TODAS las sesiones de trabajo dentro de `smartroute_flutter`:

## 1. Enrutamiento Obligatorio de Skills (Cuándo activar cada una)
Antes de responder o modificar código, evalúa la tarea y aplica activamente las instrucciones de las skills correspondientes en `.agent/skills/`:
- **SIEMPRE (En toda tarea de código o arquitectura):** Aplica `smartroute-product-focus` (mantener el foco en la plataforma escolar de Penonomé, roles Padre/Conductor/Transportista, sin desviarse a ataques teóricos ni romper decisiones MVP) y la parte **Anti-Alucinaciones** de `owasp-security-anti-hallucination` (verificar archivos reales en `lib/`, `supabase/migrations/` y `test/` antes de afirmar nada).
- **Cuando haya código nuevo o refactorización:** Aplica silenciosamente la higiene básica de `owasp-security-anti-hallucination` (consultas parametrizadas, sin secretos hardcodeados, validar ownership) y ejecuta los criterios de `quality-gate-testing-guard` (`flutter analyze` con 0 incidencias y pruebas modulares en `test/modulos/`).
- **Cuando toques `supabase/` o consultas Dart a Supabase:** Activa `supabase-flutter-architect` (solo migraciones incrementales nuevas, políticas RLS limpias y cierre de streams Realtime).
- **Cuando toques mapas, GPS, OSRM o Dijkstra:** Activa `geospatial-routing-specialist` (precisión en coordenadas DD/DMM/DMS, exclusión de ausentes antes de Dijkstra y fallback offline intacto).

## 2. Reglas Inquebrantables de Ejecución
1. **Cero Alucinaciones:** Nunca inventes nombres de tablas, columnas, rutas de archivos ni métodos de paquetes. Si no has leído el archivo en el workspace, léelo primero con tus herramientas.
2. **Cero Paranoia Innecesaria:** Si el usuario pide construir o arreglar una pantalla/función, entrega el código funcional directamente. Solo haz auditorías extensas de vulnerabilidades OWASP si el usuario pide explícitamente revisar o auditar seguridad.
3. **Protección del Quality Gate:** Ningún cambio debe dejar warnings en `flutter analyze` ni romper las 19 pruebas existentes en `test/modulos/`.
4. **Respeto a la Arquitectura:** Mantén la estructura Feature-First (`lib/modulos/{autenticacion,conductor,padre,transportista}` y `lib/nucleo/`), `provider` para estado y `go_router` para navegación.