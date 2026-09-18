# Technology decisions (ADR summary)

One state manager, one DI, one DB — no duplication. Every package must earn its place.

## Chosen stack (MVP)
| Area | Choice | Why | Rejected alternative / why | Cost | Fallback |
|---|---|---|---|---|---|
| App | Flutter + Dart (stable 3.47 / 3.13) | Single codebase AR/EN, Android-first Egypt, hiring signal | Native Kotlin — doubles work for solo | Free/OSS | — |
| State + DI | **Riverpod 2.x** | Compile-safe providers, testable, doubles as DI (no get_it), less boilerplate than Bloc for solo 8-wk MVP | Bloc — excellent but more files/events; GetX — anti-patterns, poor test story | Free | Provider-only subset |
| Navigation | go_router | Declarative, deep-link ready, role redirects, standard in jobs | AutoRoute (codegen weight), Navigator 1.0 (imperative) | Free | Navigator 2.0 manual |
| Models | freezed + json_serializable | Immutable entities, union error types, portfolio-expected | Manual — error-prone; built_value — heavier | Free (build_runner) | Manual immutable classes |
| Local DB | **Drift (SQLite)** | Real SQL, migrations, streams, testable, offline-first fit, SQL portfolio value | Hive (KV, weak queries, uncertain future) / Isar (discontinued trajectory) | Free/OSS | sqlite3 raw + DAO |
| Connectivity | connectivity_plus | Offline banner + sync trigger | Manual ping — flaky | Free | Manual retry button only |
| Secure storage | flutter_secure_storage | Tokens, not SharedPreferences | shared_prefs for tokens — insecure | Free | In-memory (demo) + warning |
| Images | image_picker + flutter_image_compress | Capture + <1MB compress before queue | No compress — storage blowup | Free | Pick only + server reject >5MB |
| Maps | flutter_map (OSM) + mock mode | Free, no key; mock map for tests/offline | google_maps_flutter — billing risk | Free* | Mock static map (*respect OSM tile policy; cache; never hammer public tiles) |
| Backend (optional) | Supabase (Postgres) behind repository interface; **mock/local default** | Open-source, SQL, RLS, generous free tier, matches Drift/SQL story | Firebase — NoSQL + lock-in; self-host FastAPI — more DevOps for solo (kept as documented alternative) | Free tier* | MockRemoteDataSource (zero keys) |
| Push/analytics/crash | Interfaces + local/mock; Firebase adapters optional & flagged off | App must boot with zero keys; privacy-safe | Hard Firebase dep — breaks zero-cost + offline story | Free | Local log |
| Payments | PaymentGateway interface + Mock only | No real money in MVP; Paymob/Fawry adapter stub post-MVP | Real SDK now — compliance + keys + scope | Free | Estimate field only |

*Verify current free-tier limits at build time; documented in `cost-audit.md`.
