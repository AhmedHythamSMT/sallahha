# Risk register

| # | Risk | Likelihood / Impact | Mitigation | Contingency |
|---|---|---|---|---|
| R1 | Shops prefer WhatsApp; no adoption | H / H | Arabic-first 3-tap flows; import-from-WhatsApp story (forward → create); pilot with 1 friendly shop | Concierge onboarding; measure missed-visit ↓ as proof |
| R2 | Technicians offline in basements/roofs | H / H | Offline-first as architecture (not feature); big buttons; compressed photos | Outbox + retry + supervisor "stale" indicator |
| R3 | Scope creep (chat/tracking/accounting) | H / M | Rejected-list in mvp-scope; every new ask → post-MVP log | Weekly scope review vs MVP spine |
| R4 | Supabase/Firebase free-tier limits or card wall | M / M | Mock-first; remote behind interface; local demo always works | Stay on mock + local FastAPI note; document limits in cost-audit |
| R5 | Photo storage + data costs | M / M | Compress <1MB, cap counts, local-first, remote optional | Quota banner; cleanup policy |
| R6 | Arabic UX bugs (RTL, long strings, digits) | M / M | Localization strategy + RTL checklist; widget tests AR+EN | Freeze strings; golden-path screenshots |
| R7 | Time overrun (solo, 8–10 wks) | M / H | Vertical slice order; optional items clearly marked | Cut optionals (map pad, FCM adapter) first |
| R8 | Fake AI claims embarrass in interviews | M / H | Rule-based triage with reasons + audit; model-card honesty | "AI intentionally out of MVP" narrative ready |
| R9 | Authz bypass / data leak between shops | M / H | Server-side checks + authz matrix tests; single-tenant demo seed | Row-level scoping; audit events |
| R10 | Low-end device jank | M / M | Pagination, image downsizing, no heavy anims; test on 2GB device/emulator | Perf pass in Phase 6 |

Review cadence: end of each phase; owner updates status column (Open/Mitigating/Closed).
