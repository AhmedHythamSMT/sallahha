# Sync state machine

```
        ┌─────────┐  queue   ┌─────────┐  attempt  ┌─────────┐  ack   ┌────────┐
        │  local  │ ───────▶ │ pending │ ────────▶ │ sending │ ─────▶ │ acked  │
        │  edit   │          └────┬────┘           └────┬────┘        └────────┘
        └─────────┘               │  app restart        │ fail (retryable)
                                  │  (stays pending)    ▼
                                  │              ┌─────────┐  attempts exhausted / non-retryable
                                  │              │ backing │ ───────────────────▶ ┌────────┐
                                  └─────────────▶│  off    │   manual retry resets │ failed │
                                                 └─────────┘ ◀─────────────────── └────────┘
```

- `pending`: durable, counted in badges. `sending`: in-flight (single flight per opId). `backing off`: scheduled with `nextAttemptAt`. `acked`: applied + removable (keep 7d for audit). `failed`: needs human (validation/authz/conflict) + Retry button (same opId).
- Per-entity ordering: status ops for one job flush in `createdAt` order; a newer status never overtakes an older one (prevents `completed` acked before `arrived`).
- Global triggers: connectivity regain, app resume, manual retry, post-mutation flush attempt.
