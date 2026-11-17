---
name: quality-gate-testing-guard
description: Enforce SonarQube Quality Gate standards (0 open issues, A rating in Security, Reliability, and Maintainability), clean `flutter analyze` checks, and modular test coverage in `test/modulos/` for SmartRoute Flutter. Use after writing or refactoring Dart code, adding features, or updating test suites.
---

# Quality Gate & Modular Testing Guard

Ensure every code change in SmartRoute Flutter preserves the SonarQube Quality Gate ("Passed" with 0 open issues) and passes all modular tests without regressions.

## When to Use

- Creating or modifying Dart screens, services, providers, or models in `lib/`.
- Adding or updating unit and widget tests inside `test/modulos/`.
- Refactoring code to fix warnings, code smells, or cognitive complexity.

## Quality Gate & Code Standards

1. **Zero-Warning Analysis (`flutter analyze`):**
   - Never leave unused imports, dead code, unused local variables, or missing `const` constructors where applicable.
   - Always check `mounted` (`if (!context.mounted) return;`) before using `BuildContext` across `async` gaps.
   - Properly dispose all `TextEditingController`, `StreamSubscription`, and `AnimationController` instances in `dispose()`.

2. **SonarQube Maintainability & Reliability (A Rating):**
   - Keep widget `build()` methods modular and focused; extract sub-widgets or helper methods when nesting or cognitive complexity grows.
   - Avoid duplicated logic across `padre/`, `conductor/`, and `transportista/` modules by reusing shared helpers in `lib/nucleo/`.
   - Never swallow exceptions with empty `catch (_) {}` blocks; handle or log errors meaningfully.

3. **Modular Test Suite Alignment (`test/modulos/`):**
   - Match new features or bug fixes with tests in the corresponding module folder (`autenticacion`, `conductor`, `padre`, `transportista`, or `nucleo`).
   - Mock external dependencies (Supabase client, Geolocator, OSRM HTTP calls, Camera) so tests run deterministically offline without requiring `127.0.0.1:54321` to be active.

## Verification Workflow

Before finishing any coding task, verify or provide the exact commands to confirm quality:
1. `flutter analyze` -> Must report `No issues found!`.
2. `flutter test` -> All modular suites in `test/modulos/` must pass (maintaining or increasing the 30.9%+ baseline coverage).