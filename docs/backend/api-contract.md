# API contract (repository interface; mock default, Supabase/FastAPI later)

Base: `https://api.local` (mock) · Auth: Bearer JWT · Errors: `{ code, messageAr, messageEn, details? }` · Pagination: `?page&limit(≤50)` → `{ data, page, total }`.

## Endpoints (MVP)
| Method | Path | Role | Notes |
|---|---|---|---|
| POST | /auth/login | public | → `{ token, user }`; 401 invalid |
| POST | /requests | customer | idempotency-Key header required |
| GET | /requests?mine=&status=&q= | customer/supervisor | supervisor sees all; customer own |
| GET | /requests/{id} | scoped | includes timeline, notes, photos, parts |
| PATCH | /requests/{id}/priority | supervisor | body `{ priority, reason }` |
| POST | /requests/{id}/assign | supervisor | `{ technicianId }`; deactivates prior active |
| PATCH | /requests/{id}/status | technician/supervisor | guarded transitions; 422 + legal-next on violation |
| POST | /requests/{id}/notes | technician | `{ kind, body }` |
| POST | /requests/{id}/photos | technician | multipart ≤5MB jpg/png; response compresses |
| POST | /requests/{id}/parts | technician | `{ partId, qty }` |
| POST | /requests/{id}/confirm | customer | only when completed |
| POST | /requests/{id}/ratings | customer | `{ stars 1..5, comment? }` once |
| GET | /dispatch/queue?view=new\|active\|overdue\|done | supervisor | overdue computed server-side |
| GET | /dispatch/workload | supervisor | per-tech active counts |
| GET | /reports/summary?week= | supervisor/admin | completed, avgHours, avgRating, overdue |

## Examples
`POST /requests` → 201 `{ id, status:"new", slaDueAt, timeline:[…] }`.
`PATCH /status` illegal → 422 `{ code:"ILLEGAL_TRANSITION", messageEn:"Cannot go new→completed. Legal: assigned.", … }`.
`POST /requests` retry same Idempotency-Key → 200 original (no duplicate).

Auth flow: login → secure-store token → attach header → 401 → logout + re-login prompt. FastAPI-local swap keeps same paths (documented alternative to Supabase).
