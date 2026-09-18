# Sallahha FieldOps (صلّحها) — Product Requirements Document

**Version:** 0.1 (MVP planning) · **Date:** 2026-09-17 · **Owner:** fresh-graduate builder
**Vertical for MVP:** air-conditioning maintenance only. **Default language:** Arabic, fully bilingual AR/EN.

## 1. Problem
Small Egyptian AC maintenance companies run operations on WhatsApp, phone calls, paper, and Excel. Consequences observed/assumed (to validate in interviews):
- Requests get lost in chat threads; no single queue.
- No clear job status ("where is the technician?").
- Missed / duplicated visits; no SLA tracking.
- No job history per customer/device → repeat diagnosis.
- No proof of work (photos, parts, signature) → payment disputes.
- Owner cannot see workload, overdue jobs, or ratings.

## 2. Users & roles
| Role | Uses | Core need |
|---|---|---|
| Customer | mobile app | request easily, track, confirm, rate |
| Technician | mobile app (offline-first) | see today's jobs, update status offline, capture proof |
| Supervisor/Dispatcher | mobile app (MVP; web post-MVP) | triage queue, assign, monitor SLA |
| Admin | mobile app settings (MVP) | users, services, pricing rules, demo data, audit view |

## 3. Positioning (chosen)
> **"Turn WhatsApp-based maintenance operations into a trackable Arabic-first workflow — fewer missed visits, no lost requests, always-known technician status."**

Why this one: it names the current alternative (WhatsApp), the mechanism (trackable workflow), the differentiator (Arabic-first), and the measurable outcome (missed visits / lost requests / status clarity). The other two candidates ("field-service OS" — too grandiose for MVP; "reduce missed visits…" alone — outcome without mechanism) are kept as taglines. See `mvp-scope.md` § positioning.

## 4. Smallest valuable workflow (MVP spine)
Customer creates request → supervisor assigns technician → technician works offline-capable job → customer confirms + rates → supervisor sees SLA/workload. Anything not on this spine is optional or post-MVP.

## 5. Functional requirements (MVP)
### 5.1 Auth & roles
- FR-A1: Email+password sign-in (mock + Supabase-ready interface). Demo accounts per role.
- FR-A2: Role claim (customer/technician/supervisor/admin); server-side enforcement (RLS/policy table, § authorization-matrix).
- FR-A3: Sign-out; session expiry message. No social login in MVP.

### 5.2 Service requests (customer)
- FR-R1: Create request: service type (AC install/cleaning/repair/gas refill — seeded list), description (AR/EN free text), optional photo (≤5MB, jpg/png), address text + governorate + phone, optional map pin (mock/OSM), preferred time slot.
- FR-R2: Request gets ID, status `new`, timestamps, idempotency key (client UUID).
- FR-R3: Customer sees own requests with status timeline; receives status-change notification (local/mock in MVP).
- FR-R4: Customer confirms completion (explicit button) and rates 1–5 + optional comment. Rating required before request counts as "closed with feedback".

### 5.3 Dispatch (supervisor)
- FR-D1: Queue views: New / Assigned+active / Overdue (SLA breach) / Completed / Cancelled; search by ID/phone; filter by service type.
- FR-D2: Assign / reassign technician; change priority (normal/high/urgent); set SLA due time (default per service type, editable).
- FR-D3: Workload view: per-technician active job count.
- FR-D4: Basic reports: completed/week, avg completion time, avg rating, overdue count. No custom report builder.
- FR-D5: Priority *suggestion* from rule-based triage (keywords); supervisor must confirm; suggestion logged with reason.

### 5.4 Jobs (technician)
- FR-J1: "My jobs" list (synced for offline); job details readable offline.
- FR-J2: Status transitions (guarded state machine): new→assigned→accepted→on_the_way→arrived→in_progress→{waiting_for_parts→in_progress}→completed; cancelled from assigned/accepted only with reason. Illegal transitions rejected with typed error.
- FR-J3: Add diagnosis notes, labor notes, before/after photos (offline-stored, queued), used parts (from seeded catalog + qty), optional estimated cost (EGP).
- FR-J4: Collect customer confirmation (PIN or signature capture — signature as image in MVP; no legal-certification claim).
- FR-J5: Sync badges: pending/synced/failed per job and per change; manual retry button; offline banner.

### 5.5 Cross-cutting
- FR-X1: Arabic default, EN toggle, RTL/LTR, EGP formatting, AR dates.
- FR-X2: Every mutation carries idempotency key; outbox queue persists across restarts.
- FR-X3: Audit events for: create, assign, status change, confirm, rate, priority change.
- FR-X4: Mock PaymentGateway present but NOT on MVP spine (estimate only; no charge). States: pending/succeeded/failed/cancelled/timed_out.

## 6. Non-functional requirements
- NFR-1 Offline-first: full technician read + status/note/photo mutations offline; sync with backoff; never silently drop data.
- NFR-2 Low-end Android: cold start < 3s on 2GB RAM device; images compressed < 1MB before upload; list pagination (20/page).
- NFR-3 Zero-cost demo: works with no accounts/keys (mock mode); no paid tiles/APIs by default.
- NFR-4 Security baseline: no secrets in git, secure token storage, server authz, upload validation, no PII in logs/notifications previews.
- NFR-5 Testability: business rules pure-Dart, covered by unit tests; one E2E journey.

## 7. Acceptance criteria (MVP exit)
- AC-1: Demo script runs end-to-end on a fresh emulator with mock mode, airplane-mode segment included, in < 10 min.
- AC-2: `flutter analyze` clean, `flutter test` green, debug APK builds.
- AC-3: All required states visible: loading/empty/error/offline/pending-sync/failed-sync/unauthorized.
- AC-4: Arabic default verified on RTL checklist; EN toggle works without restart.
- AC-5: Docs listed in README "Required deliverables" all exist.

## 8. Domain glossary (short)
- **ServiceRequest**: customer ask. **JobAssignment**: supervisor→technician link (one active at a time). **Job**: technician execution view of an assigned request. **StatusHistory**: append-only transitions. **Outbox/SyncOperation**: queued offline mutation with idempotency key. **SLA**: due-time promise per request; breach = overdue. **Triage suggestion**: non-binding priority/category hint. Full glossary: `glossary.md`.

## 9. Success metrics (MVP pilot)
- Activation: ≥1 company, ≥3 technicians, ≥20 real requests in 4 weeks.
- Reliability: 0 lost requests (every WhatsApp-equivalent captured), sync success ≥99% after retry.
- Operations: missed-visit rate ↓ vs baseline; median assign latency < 30 min working hours; overdue share visible weekly.
- Quality: ≥40% rating response; avg rating tracked; 0 silent data-loss incidents.
- Portfolio: README demo + APK + green CI + interview script rehearsed.

## 10. Out of scope (explicit)
Realtime GPS tracking, in-app chat, accounting/invoicing, marketplace, photo-AI diagnosis, iOS release, web dispatcher console, real payments. See `mvp-scope.md` and `roadmap.md`.

## 11. Risks (pointer)
Full register: `risk-register.md`. Top: WhatsApp inertia; technician low-connectivity; scope creep; Supabase limits; photo storage growth.
