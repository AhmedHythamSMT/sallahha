# Free-stack decision

**Decision:** Flutter + Riverpod + go_router + Drift/SQLite local-first; repository interfaces with `MockRemoteDataSource` default; Supabase as the *documented optional* remote; Firebase adapters optional and off; OSM/flutter_map with mock fallback; Mock payments/notifications/analytics.

## Why not Firebase-first?
Firestore is NoSQL + vendor-shaped; offline story is cache-based, not an explicit outbox you can show in interviews; SQL (Drift + Postgres) demonstrates stronger backend fundamentals for a fresh graduate targeting backend/mobile roles.

## Why not self-hosted FastAPI now?
Good portfolio signal but doubles DevOps (hosting, TLS, auth, uptime) in an 8–10 week solo MVP. Kept as documented Phase-3-swap: repository interface means FastAPI can replace Supabase without touching UI/domain. Local FastAPI note stays in `docs/backend/api-contract.md`.

## Why Drift over Hive/Isar?
- Hive: KV box, no real queries/migrations story, weaker sync narrative.
- Isar: maintenance trajectory uncertain; query power unused at this scale is still less standard than SQL.
- Drift: SQL + migrations + reactive streams + pure-Dart testable DAOs → best offline-first + interview story ("I can reason about SQL, migrations, and sync").

## What could change this decision?
If Supabase free tier adds card requirement → stay mock-only, note FastAPI-local path. If APK size becomes an issue on 2GB devices → drop sqlite3 bundled lib for system sqlite where possible, measure first.
