---
name: smartroute-product-focus
description: Keep development focused on SmartRoute Flutter core product goals (school transport logistics in Penonomé, Padre/Conductor/Transportista workflows, OSRM/Dijkstra routing, and live tracking) without getting sidetracked by theoretical attack scenarios or over-engineering. Use during feature implementation, UI/UX updates, and general coding tasks.
---

# SmartRoute Product Focus & Pragmatism

Prioritize delivering working, clean features for SmartRoute Flutter's school transportation platform in Penonomé, Coclé before discussing edge-case threats.

## Core Product Scope (Stay on Track)
- **Padre / Tutor (`lib/modulos/padre/`):** Live bus map, ETA, boarding/drop-off notifications, one-tap absence reporting, and DD/DMM/DMS pickup location picker with OSRM road snapping.
- **Conductor Escolar (`lib/modulos/conductor/`):** Dynamic daily passenger manifest, stop sorting, Dijkstra optimal routing skipping absent students, facial/manual check-in, and incident reporting.
- **Transportista (`lib/modulos/transportista/`):** Bus registration, driver assignment, seat capacity control (no overbooking), live fleet map, and Trust & Safety document audits.

## Anti-Paranoia & Pragmatism Rules
1. **Features First, Audits Only When Requested:** When asked to build or fix a feature, write the working code directly. Apply basic OWASP hygiene silently (parameterized queries, no hardcoded secrets), but do NOT derail the response into theoretical threat modeling or penetration testing lectures unless explicitly asked for a security audit.
2. **Respect Intentional MVP Trade-offs:** Do not "fix" or complain about intentional MVP decisions (such as local Supabase `127.0.0.1:54321`, demo users in migrations, or commented-out payment gateway sections in `owner_home_screen.dart`) unless the user specifically asks to refactor them.
3. **Preserve Clean Architecture & Tests:** Follow the existing Feature-First structure (`lib/nucleo/`, `provider`, `go_router`), keep `flutter analyze` at 0 issues, and maintain compatibility with the modular test suites in `test/modulos/`.