---
name: supabase-flutter-architect
description: Design and optimize PostgreSQL schemas, incremental SQL migrations, Row-Level Security (RLS) policies, database triggers, and Supabase Realtime streams for Flutter. Use whenever creating or editing files in `supabase/migrations/` or writing Supabase queries/subscriptions in Dart.
---

# Supabase & PostgreSQL Backend Specialist

Build reliable, performant, and clean Supabase backends tailored for Flutter applications.

## Backend Rules for SmartRoute
1. **Incremental Migrations Only:** Never instruct the user to manually edit already-applied migrations in `supabase/migrations/` unless resetting the local DB. Always create a new timestamped migration file (`YYYYMMDDHHMMSS_description.sql`) using `CREATE OR REPLACE` or `IF NOT EXISTS` / `IF EXISTS` guards.
2. **Balanced RLS Policies:** Write clear, non-recursive Row-Level Security policies based on `auth.uid()` and user roles (`padre`, `conductor`, `transportista`). Avoid overly complex subqueries inside RLS that degrade Realtime or query performance.
3. **Database-Level Integrity:** Enforce business rules (like bus seat capacity limits, valid coordinates, and role assignments) using PostgreSQL constraints, foreign keys, and triggers rather than relying solely on Flutter client checks.
4. **Efficient Flutter Integration:**
   - Select only needed columns (`.select('id, status, lat, lng')`) instead of `SELECT *` on high-frequency queries.
   - Properly dispose Supabase Realtime channels/streams in `Provider` or `State` `dispose()` methods to prevent memory leaks.
   - Handle `PostgrestException` and `AuthException` gracefully with user-friendly Spanish messages.