# Changelog

## [0.6.0] — 2026-09-18 — Phase 6 quality + security hardening
- Offline banner: explicit startup check + stream fallback (was stream-only, blind to pre-launch airplane mode). Verified on-device with real radio-off: banner shows; gone on reconnect.
- Workload line shows technician names (was raw truncated IDs).
- Accessibility: Semantics labels on nav cards + status buttons, FAB tooltips (uiautomator-visible, TalkBack-readable).
- Proof photos: camera capture (1024px/q80) with before/after buttons + thumbnails; repo validation (jpg/png ≤5MB, mirrored server-side later); Android CAMERA + READ_MEDIA_IMAGES declared.
- Secure session: flutter_secure_storage persistence + silent startup restore + clear on sign-out (all exception-safe).
- Gates: analyze clean, 61 green (+3 CI-Linux sqlite skips). Rebuilt + reinstalled; ADB-driven device pass: no crashes/exceptions, offline reads + outbox verified, one harness lesson (open notification shade steals input focus — check `dumpsys window`).
- Needs human fingers (ADB aim unreliable on HyperOS): session-survives-kill check, first real camera capture + permission dialog.

## [0.5.1] — 2026-09-18 — Physical device test (Xiaomi, ADB-driven)
- Drove the app on-device via ADB (24 screenshots): login EN/AR, role home, dispatch queue + triage hints, request details + Synced badge + timeline/assignment, notifications empty state, Arabic keyboard, airplane-mode cached list, reconnect with all ops acked. Zero crashes/exceptions, 0% idle CPU, no red screens, no overflows on tested screens.
- Findings queued for Phase 6: (1) offline banner ignores airplane toggle (connectivity stream needs explicit check); (2) workload line shows raw truncated tech IDs; (3) uiautomator sees nothing (add Semantics labels — also an a11y requirement); (4) locale persists across `-r` reinstalls (clear data for fresh AR demo).
- Harness note: `input tap` lands ~+120y off on HyperOS (status-bar inset) — spread taps; screencaps need `cmd` redirect (PowerShell corrupts binary).

## [0.5.0] — 2026-09-18 — Phase 5 integrations + backend verdict
- Backend decision (docs/architecture/backend-comparison.md): mock default, Supabase first real remote, PocketBase runner-up, Firebase rejected for this data model, FastAPI later. No new packages until credentials exist.
- Notifications: abstraction (memory + drift), inbox page (/notifications, unread bold, tap-to-read), repo hooks (assign→tech, status→customer, confirm→dispatcher, rating→tech).
- Payments: PaymentService + MockPaymentGateway (cash/test-card, full state machine, drift history), supervisor collect UI on completed+estimated requests.
- Analytics: non-PII event buffer wired into request lifecycle (created/assigned/status/confirmed/rated).
- AI seam: AIService interface (RuleBased + Fake adapters); dispatch consumes the provider, not the function.
- Gates: analyze clean, 56 green (+3 CI-Linux sqlite skips). Rebuilt + reinstalled on Xiaomi.

## [0.4.0] — 2026-09-18 — Phase 4 offline-first sync
- Durable outbox: `OpLog` abstraction (drift adapter = restart-safe, memory = tests), `SyncEngine` (per-entity FIFO, exponential backoff 1s→5min cap, 25-attempt exhaustion, single-flight), opId = idempotency key end-to-end.
- Enqueue-first repository: provisional local apply → durable op → flush when online. Reads render local bundles; remote refresh only when online with nothing pending. Client-generated request IDs (no remapping, no duplicates).
- Conflict policy live: version-conflict → one server-wins rebase when still legal, else `failed` with reason (never silent).
- UX: per-entity `SyncBadge` (synced/pending/failed+retry) in both detail AppBars, auto-flush on reconnect + startup, offline banner retained.
- Tests: backoff math, 7 engine cases (FIFO, offline noop, backoff delays, fail→retry, conflict paths, dedupe, restart), offline create→reconnect→no-duplicate (CI Linux), live badge widget test.
- Gates: `analyze` clean, 50 green (+3 sqlite host-skips for CI Linux). Rebuilt + reinstalled on Xiaomi.

## [0.3.2] — 2026-09-18 — Device feedback round
- Back navigation everywhere: section cards and FAB now `push` (were `go`, which replaced the stack and made system-back exit the app); new-request submit uses `pushReplacement` so back skips the stale form. AppBar back + Android gesture traverse Home → section → details.
- Assign now mirrors its timeline event to the local cache (status_history was empty for assigns).
- Verified: 41 tests green (incl. full tap-through chain test with system-back pops), analyze clean, rebuilt + reinstalled on Xiaomi.

## [0.3.1] — 2026-09-17 — On-device run (Xiaomi 25080RABDG, Android 16)
- First `flutter build apk --debug` + install + launch on physical device: healthy start (Impeller/Vulkan, no Dart exceptions), Arabic RTL login verified via screenshot.
- Toolchain fixes: `flutter config --android-sdk C:\Android-SDK`, JDK 17 (`Microsoft\jdk-17.0.12.7-hotspot`, persisted via JAVA_HOME), `kotlin.incremental=false` in `android/gradle.properties` (Kotlin cache cannot close under paths with spaces on Windows).
- Note: `monkey` launch injected a stray tap (landed on /login) — expected harness behavior, not an app bug.

## [0.3.0] — 2026-09-17 — Phase 3 core workflow
- Repository layer: `RequestRepository` interface + write-through impl (mock remote → drift cache + SyncOperation rows); op-key dedupe; server-side guards + version-conflict errors.
- Mock backend: seeded, 120ms latency, idempotent creates, full status machine, confirm/rate gating.
- UI: email+password login (4 demo accounts), customer request form (domain-validated) + list + details (timeline/confirm/rate), supervisor dispatch (4 queue tabs, search, workload, assign sheet, triage hints), technician jobs + job execution (status buttons, cancel reason, notes, parts, estimate), basic reports, profile identity.
- Rules: SLA/overdue, Egyptian phone + draft validation, transition guard.
- Deferred honestly: camera capture UI (`image_picker` in Phase 6 hardening; path plumbing done end-to-end), full details offline cache + sync engine (Phase 4).
- Gates: `analyze` clean, 40 tests green (+2 sqlite roundtrips skipped on Windows host, run on CI Linux).

## [0.2.0] — 2026-09-17 — Phase 2 foundation complete
- ARB localization (ar default, en) via gen-l10n: 60 keys, locale toggle persisted with SharedPreferences.
- Full MVP route map with role guards + unauthorized page; thin placeholder pages per feature.
- Design tokens (teal/amber) + shared UI states (loading/empty/error/offline banner/sync badges) + typed-error → localized-message mapping.
- Riverpod DI: persisted locale, mock session role, connectivity/offline provider.
- Drift schema v1 (16 tables mirroring ERD) + codegen + synthetic seed (5 users, 4 services, 6 parts, 8 requests).
- Deterministic triage rules-v1 (6 categories, safety path, tech scoring) with 17 unit tests.
- Gates: `analyze` clean, 27 tests green (+1 sqlite roundtrip skipped on Windows host, runs on CI Linux).
- Note: no Android SDK on this Windows host — debug APK builds in CI (`.github/workflows/flutter-ci.yml`), not locally.

## [0.1.0] — 2026-09-17 — Foundation + product/architecture docs
- Added full Phase-1 docs: product (PRD, personas, journeys, stories, glossary, scope, roadmap, risks), architecture (tech decisions, cost audit, free-stack, offline-first, sync machine, conflicts), backend (ERD, API contract, authz matrix), testing, security, UX/RTL, AI (evaluation, architecture, model-card rules-v1, data policy).
- Set up feature-first skeleton, Riverpod + GoRouter + theme + AR/EN strings, Result/error types, job-status state machine with unit tests, CI workflow, `.env.example`.
- Decision: Riverpod over Bloc; Drift/SQLite over Hive/Isar; Supabase-optional with mock default; rules-based triage (no ML in MVP).
