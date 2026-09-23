# Sallahha FieldOps (صلّحها)

**Arabic-first, offline-first field-service management for small Egyptian AC-maintenance companies.**
Turn WhatsApp-based operations into a trackable workflow: fewer missed visits, no lost requests, always-known technician status.

> Portfolio project by a fresh graduate in Egypt — Flutter + Riverpod + Drift/SQLite, zero-cost demo, bilingual AR/EN.

## Executive summary (read first)
- **Strong:** narrow vertical (AC only), real pain (lost WhatsApp requests, unknown tech status), offline-first as differentiator, role-based workflow demoable in 10 minutes, SQL + sync + testing story that interviews love.
- **Risky assumptions:** shops will leave WhatsApp; technicians will tap statuses on low-end phones; owner pays attention to SLA dashboards. All must be validated with 5–8 interviews before building past MVP (questions in docs).
- **Smallest valuable workflow:** customer request → supervisor assign → technician offline job + proof → customer confirm + rate → supervisor SLA view. Everything else is optional/post-MVP/rejected (see `docs/product/mvp-scope.md`).
- **AI decision:** rules-based triage in MVP (`rules-v1` with reasons + human confirm + audit). No ML, no photo diagnosis — deterministic rules beat ML on cost/risk/data. Full analysis in `docs/ai/`.

## Architecture
```
UI (Riverpod + go_router) → domain (pure Dart: status machine, triage, SLA)
 → repositories (interfaces) → local (Drift/SQLite + outbox) / remote (Mock default, Supabase optional)
 ↳ services (map / notify / pay / analytics) all behind interfaces, mock-first
```
Feature-first layout under `lib/` (`app/ core/ features/ shared/`). Presentation never calls HTTP/SQLite directly. See `docs/architecture/technology-decisions.md`.

## Tech table (why)
| Tech | Why | Alternative rejected |
|---|---|---|
| Flutter/Dart | Single AR/EN Android-first codebase | Native ×2 work |
| Riverpod | One state+DI system, testable, less boilerplate than Bloc for solo MVP | Bloc (more files), GetX (test story) |
| go_router | Declarative + role redirects | Navigator 1.0 |
| Drift/SQLite | Real SQL, migrations, offline-first, interview-grade | Hive (KV), Isar (trajectory) |
| flutter_map/OSM + mock | Free, no key; mock for tests | Google Maps billing |
| Supabase-optional / mock-default | Open-source SQL, RLS; demo runs keyless | Firebase lock-in; FastAPI now = DevOps ×2 |
| Mock pay/notify/analytics | Zero-cost, privacy-safe | Real SDKs = scope + keys |

Free-cost strategy: mock-first, no keys required, tile-policy respected, limits re-verified at build time. Details: `docs/architecture/cost-audit.md`, `free-stack-decision.md`.

## Quickstart (mock mode, zero keys)
```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```
First launch shows the onboarding flow; "Get started" lands on sign-in. Demo accounts (seeded Phase 3): `customer@demo.test`, `tech@demo.test`, `supervisor@demo.test`, `admin@demo.test` (password: `demo1234`).

## Premium UI stack
Tajawal (Google Fonts) type + Material 3 design system, `flutter_screenutil` responsive sizing, `flutter_animate`/`rive`/`lottie`/`skeletonizer` animation+skeleton toolkit, `material_symbols_icons` glyphs, gradient hero/CTA styling inspired by the `mitesh77/Best-Flutter-UI-Templates` collection. Theme tokens live in `lib/core/theme/app_theme.dart`.

## Supabase (free hosted backend, optional)
Auth + Postgres + RLS + realtime behind your existing repository interfaces; the app still runs mock/keyless by default.

1. Create a project at [supabase.com](https://supabase.com) (free tier).
2. Open **SQL editor** → run `docs/backend/supabase.migration.sql` (profiles, requests, RLS, auth trigger).
3. Copy `.env.example` → `.env` and fill:
   ```dotenv
   DATA_SOURCE=mock   # leave mock, or flip to `supabase`
   SUPABASE_URL=https://<ref>.supabase.co
   SUPABASE_ANON_KEY=<anon key>
   ```
4. `flutter run` — sign-in now goes through Supabase Auth; the matching profile row (role, name, phone) is created on first sign-up and shown in-app. Inspect data from the **Table editor** in your project dashboard or the in-app **Debug DB Viewer**.

## Inspect the on-device database (debug builds)
```powershell
$ADB = "C:\Android-SDK\platform-tools\adb.exe"
cmd /c "$ADB -s <device-id> exec-out `"run-as com.example.sallahha cat app_flutter/sallahha.db`" > %TEMP%\sallahha_device.db"
C:\ADB\sqlite3.exe $env:TEMP\sallahha_device.db ".tables"
C:\ADB\sqlite3.exe $env:TEMP\sallahha_device.db "SELECT id, status FROM service_requests;"
```
(`run-as` works because debug builds are debuggable; `exec-out` via `cmd` keeps the binary intact — PowerShell `>` corrupts it.)

## Known limitations (honest)
- Remote/Supabase adapter is demo-scoped (auth + profiles wired; request sync lands post-MVP), FCM, real payments, OSM pin UI remain Phase 5.
- No realtime GPS, chat, accounting, marketplace, photo-AI — intentionally rejected (§ mvp-scope).
- No compliance claims (MASVS referenced, not certified); demo privacy policy only.
- SQLite integration tests skip on a Windows host without `sqlite3.dll`; they run on CI Linux.

## Docs map
- Product: `docs/product/` (PRD, personas, journeys, stories, glossary, scope, roadmap, risks)
- Architecture: `docs/architecture/` · Backend: `docs/backend/` (incl. `supabase.migration.sql`) · Testing: `docs/testing/` · Security: `docs/security/` · UX: `docs/ux/` · AI: `docs/ai/`

## Roadmap
Phases 0–7 in `docs/product/roadmap.md` (8–10 weeks). Post-MVP: web console → real Paymob/Fawry → FCM prod → second vertical → optional on-device ML only with labeled data.

## Portfolio script (60s)
"Small AC shops in Egypt run on WhatsApp — requests get lost and nobody knows where the technician is. Sallahha is an Arabic-first offline-first app: the customer books in 3 minutes, the supervisor assigns in 3 taps with SLA flags, and the technician works fully offline in basements — status, photos, parts all queue and sync with idempotency keys. I chose Riverpod + Drift/SQLite so the demo runs free with no backend, and triage is deterministic rules with human confirm — no fake AI. Here's the airplane-mode demo and the sync badges."

## Interview angles
- Flutter: Riverpod, go_router, RTL/AR-EN, offline UI states.
- Backend: ERD, API contract, authz matrix, idempotency, pagination.
- DevOps: GitHub Actions gates, `.env` hygiene, APK build.
- QA: unit (status machine), widget (AR/EN), integration (airplane-mode E2E), repo tests.
- Security: threat model, checklist, secure storage, upload validation.
- AI: rules-v1 model card, why ML deferred, promotion bar.
