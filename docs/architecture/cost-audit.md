# Cost audit — zero-cost proof (verify limits at build time, 2026)

Rule: the demo must run with **no account, no card, no key**. Anything paid is behind an interface and OFF by default.

| Dependency | Purpose | Cost | Limit / risk (check live) | Fallback in repo |
|---|---|---|---|---|
| Flutter/Dart/Android Studio/VS Code/emulator | Build | Free OSS | Disk/RAM only | — |
| Drift + sqlite3_flutter_libs | Offline DB | Free OSS | App size +~5MB | Mock in-memory DAO for tests |
| Riverpod / go_router / freezed / json_serializable | App framework | Free OSS | build_runner time | Manual models |
| OSM tiles via flutter_map | Map pin | Free w/ policy | Tile-abuse ban if hammered; needs connectivity | MockMap (default in tests/offline demo) |
| Supabase free tier | Optional remote | Free tier* | Project pausing, row/storage caps change | MockRemoteDataSource (default) |
| Firebase (FCM/analytics/crash) | Optional adapters | Free tier* | Requires account; analytics privacy review | Local/mock (default) |
| GitHub Actions | CI (analyze/test) | Free public repo | Minutes caps private | Local scripts |
| Paymob/Fawry | Post-MVP adapter stub | Real fees | PCI scope — NOT in MVP | MockPaymentGateway |

*Do not assume — open pricing page during Phase 5 and paste numbers here.
**Secrets:** `.env.example` only; real `.env` gitignored; CI uses placeholders; mock mode when keys absent.
