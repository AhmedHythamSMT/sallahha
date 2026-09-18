# MVP scope — must / optional / post-MVP / rejected

## 1. Must-have (MVP exit gate)
- Auth + 4 roles + demo accounts; server-side authz matrix enforced.
- Request CRUD (customer) with photo/slot/governorate; status timeline.
- Supervisor queue (new/active/overdue/done), assign/reassign, priority + SLA due, workload, basic reports.
- Technician my-jobs offline, guarded 9-state machine, notes, before/after photos, parts usage, estimate EGP, signature/PIN confirm.
- Customer confirm + 1–5 rating.
- Offline-first outbox with idempotency, backoff, badges, retry, restart-safe.
- AR default + EN, RTL/LTR, EGP + AR dates, all required UI states.
- Rule-based triage suggestion (category + priority) with reason + human confirm + audit.
- Mock payment/notification/analytics behind interfaces (no real charge, no Firebase required).
- Seed demo data; `.env.example`; green CI; debug APK.

## 2. Useful but optional (include only if ahead of schedule)
- OSM map pin (`flutter_map`) with mock fallback; static mock map in tests.
- Signature pad package (else photo-of-signature fallback).
- Push via FCM adapter (local/mock is the MVP bar).
- Supabase remote adapter wired to real project (mock remains default).

## 3. Post-MVP (roadmap, not now)
- Web dispatcher console; iOS release; real Paymob/Fawry adapter; FCM production; advanced reports/export; multi-branch; inventory; elevator/plumbing verticals; small on-device ML classifier (only with labeled data); summarization.

## 4. Rejected (do NOT build — complexity without MVP value)
- Realtime GPS tracking → battery/privacy/cost; contradicts offline-first story.
- In-app chat → WhatsApp/phone already wins; status timeline + notifications suffice.
- Accounting/ledger → regulated, scope explosion; estimate field only.
- Marketplace/bidding → two-sided cold start; this is B2B ops tool.
- Photo-AI diagnosis → unsafe, data-hungry, unvalidatable; documented in `docs/ai/`.
- Social login, SSO, custom report builder, multi-language beyond AR/EN.

## Positioning (3 candidates → choice)
1. "A simple Arabic-first field-service operating system for small Egyptian maintenance teams." — clear but "OS" overclaims for MVP.
2. "Reduce missed visits, lost requests, and unclear technician status." — strong outcome, no mechanism.
3. **Chosen:** "Turn WhatsApp-based maintenance operations into a trackable Arabic-first workflow." — names alternative + mechanism + differentiator. Pair with #2 as supporting metric line.
