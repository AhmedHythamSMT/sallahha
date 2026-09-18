# Roadmap — 8–10 weeks (solo fresh graduate, ~12–15 h/week)

## Phase 0 — Repo inspection (0.5 wk) ✅
Fresh counter template; Flutter 3.47 / Dart 3.13. No legacy to preserve.

## Phase 1 — Product + architecture docs (wk 1–2) ← YOU ARE HERE
Exit: all docs in `/docs` exist; tech decisions frozen; risk register open.

## Phase 2 — Foundation (wk 2–3)
Riverpod + GoRouter + theme + AR/EN scaffolding + Drift schema v1 + error/result types + CI + `.env.example`. Exit: `analyze` clean, sample tests green.

## Phase 3 — Core workflow (wk 3–5)
Auth/roles → requests → assign → job status machine → notes/photos/parts → confirm/rate → supervisor reports. Mock remote first. Exit: happy-path E2E on emulator.

## Phase 4 — Offline-first (wk 5–6)
Outbox, sync engine + backoff, badges/retry, conflict policy, restart-safety. Exit: airplane-mode test matrix green.

## Phase 5 — Integrations (wk 6–7)
Map/notification/payment/analytics/AI-triage interfaces + mocks (+ optional Supabase/FCM adapters behind flags). Exit: app runs with zero keys.

## Phase 6 — Quality + security (wk 7–8)
Coverage of business rules, RTL/a11y pass, image compression, secure storage, threat-model fixes, low-end device test.

## Phase 7 — Demo + docs (wk 8–10)
Seed data, demo accounts, README, APK, demo-video script, portfolio + interview scripts. Exit: MVP acceptance criteria (§PRD-7) met.

## Post-MVP (after hiring signal)
Web console → real payments → FCM prod → Supabase prod → second vertical → optional on-device ML (see `docs/ai/`).
