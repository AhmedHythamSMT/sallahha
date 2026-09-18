# Conflict resolution

## Policy (explicit, no silent loss)
1. **Status transitions: server-authoritative.** If local `in_progress→completed` races a supervisor `→cancelled`, server wins; technician sees "Server set Cancelled by Supervisor — your change kept in history, tap to re-apply". Both transitions stay in StatusHistory.
2. **Non-critical text (diagnosis/labor notes): last-write-wins at field level** with `updatedAt` + author stamp; loser version retained in note history / audit.
3. **Sensitive data (assignment, priority, SLA, estimate, parts qty): reject-and-flag.** Loser goes `failed(conflict)` with both values shown; human re-applies.
4. **Photos/ratings:** additive-only; never overwrite. Duplicate opIds deduped.

## Implementation notes
- Each entity carries `version` (server rev) + `updatedAt`. Sync sends `baseVersion`; mismatch → conflict path above.
- Idempotency: retries reuse `opId`; server/mock keeps applied-`opId` set; duplicates return prior ack without re-applying.
- Tests required: offline update → reconnect; duplicate op; failed sync; conflict each category; restart with pending ops (see `docs/testing/test-strategy.md`).
