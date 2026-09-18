# Offline-first design

## Principle
Local SQLite (Drift) is the source of truth for reads; the outbox is the source of truth for writes. Network is an optimization, never a requirement for technician work.

## Components
- **Drift tables:** requests, assignments, status_history, notes, photos (local path + remote URL nullable), parts_usage, sync_operations, audit_events.
- **SyncOperation fields:** `opId (client UUID = idempotency key)`, entityType, entityId, opType (create/update/status/photo/note/parts), payload JSON, createdAt, retryCount, lastAttemptAt, status (pending/sending/acked/failed), lastError.
- **SyncEngine:** connectivity listener + app-resume + manual retry trigger; processes FIFO per entity, exponential backoff (1s→2→4→…→5min cap, jitter); marks acked only on server-ack (or mock-ack); persists across restarts (outbox table, not memory).
- **Photos offline:** captured to app dir, compressed <1MB, queued as `photo` ops with local path; upload on reconnect; UI shows local thumbnail + `pending` badge.

## UI contract
- Global offline banner; per-job sync badge (pending/synced/failed); failed shows reason + Retry; never block reading cached jobs.
- Optimistic UI with rollback flag: show local value + `pending`; on conflict, show server value + conflict notice (never silent overwrite of sensitive data).

## Failure scenarios
| Scenario | Behavior |
|---|---|
| Airplane-mode status tap | Queued; badge pending; works fully |
| Reconnect | Auto-flush FIFO; backoff on 5xx; stop on 401 → re-auth prompt |
| Duplicate retry | Same opId → server dedupes; no double parts/status |
| App killed mid-queue | Outbox table survives; resume on launch |
| Photo too large | Rejected pre-queue with typed error; compress hint |
| Server rejects (validation/authz) | Op → failed with message; manual fix + retry; audit logged |
