# Backend comparison — Supabase vs Firebase vs the rest (for Sallahha FieldOps)

Date: 2026-09-18. Context: offline-first Flutter MVP, 16-table relational model,
Egyptian SME pilot, zero-cost demo, solo fresh graduate.

## Verdict up front
1. **Demo/default: the built-in mock** (zero accounts, zero keys, works on the Xiaomi today).
2. **First real remote: Supabase.** Postgres matches our Drift schema 1:1, Row Level Security mirrors the authorization matrix, Auth + Storage cover login/photos, free tier fits a pilot, and SQL is the stronger portfolio signal for backend/mobile roles.
3. **Runner-up: PocketBase** — single Go binary, SQLite, self-hosts on a €4 VPS or a shop PC; great Egypt story (data stays local, works over LAN). Costs control, not zero-effort: YOU own backups/uptime.
4. **Rejected for this project: Firebase.** Firestore's document model fights our relational data (assignments, history, parts joins); offline is cache-based, not the explicit outbox that is this project's differentiator; pricing is usage-metered anxiety for a pilot; vendor lock-in teaches less SQL.
5. **Later, not now: self-hosted FastAPI + Postgres.** Maximum control and the best "I built the backend" story — but auth/storage/realtime/backup all become your second job. Correct post-traction move, wrong 8-week-MVP move.

## Comparison
| Need | Supabase | Firebase | PocketBase | FastAPI self-host |
|---|---|---|---|---|
| Data model fit | ✅ Postgres = our ERD as-is | ❌ NoSQL, denormalize everything | ✅ SQLite, relational | ✅ whatever you build |
| Auth + roles | ✅ Auth + RLS policies | ✅ Auth + rules (separate language) | ✅ built-in auth | 🛠️ you build (JWT, hashing) |
| File/photo storage | ✅ Storage buckets | ✅ Storage | ✅ built-in | 🛠️ S3/MinIO wiring |
| Offline-first fit | ✅ dumb-sync friendly: opId unique constraint dedupes, `version` column for conflicts | ⚠️ cache sync fights explicit outbox | ✅ same as Supabase | ✅ same, you write it |
| Realtime dispatch board | ✅ Realtime (Postgres changes) | ✅ best-in-class | ⚠️ SSE realtime | 🛠️ websockets |
| Free-tier pilot risk | ⚠️ pausing/limits change — verify live | ⚠️ metered billing surprises | ✅ free if you host | ⚠️ VPS €4+/mo, not free |
| Egypt reality (cards, forex) | ✅ card-free start | ⚠️ card often required | ✅ no account needed | ⚠️ VPS needs payment |
| Portfolio signal | ✅ SQL + RLS + Postgres | ➖ config-console skills | ✅ self-host/ops story | ✅✅ full backend ownership |
| Effort for solo MVP | low | medium (remodel) | low-medium (ops you) | high |

## Supabase integration plan (when keys exist, Phase 5+)
- Tables mirror `docs/backend/erd.md` 1:1 (names identical, `op_id UNIQUE` on mutations table, `version INT` on service_requests).
- RLS mirrors `docs/backend/authorization-matrix.md`: customers `customer_id = auth.uid()`, technicians via active assignment join, supervisors full-shop scope.
- Auth: email/password (demo accounts become real users with the same addresses).
- Storage bucket `job-photos` (5MB limit, jpg/png) — outbox uploads on flush.
- Idempotency: `INSERT ... ON CONFLICT (op_id) DO NOTHING` then return existing row — same semantics as MockBackend.
- Realtime: subscribe dispatch queue to `service_requests` changes (supervisor board updates live).
- Env: `SUPABASE_URL` / `SUPABASE_ANON_KEY` in `.env` (never git); `DATA_SOURCE=mock` stays default so the demo never breaks.
- No supabase_flutter dependency is added until credentials exist (rule: no package without a live use).

## What Firebase would be better at (honesty)
Pure-realtime consumer apps, crashlytics/remote-config maturity, and teams already on GCP. None of those is this project's bottleneck — our bottleneck is a trustworthy offline queue over relational data.
