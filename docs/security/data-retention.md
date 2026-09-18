# Data retention & demo-data policy

- Demo seed accounts/data are synthetic (Cairo names/phones clearly fake, e.g. 0100-000-xxxx) and Industrial-zone addresses; never mix with pilot data — separate DB / Supabase schema or `isDemo` flag + Admin wipe button.
- Pilot retention: requests + proof photos ≤24 months; audit events ≤36 months; expired sessions wiped on logout; deletion on customer request within 30 days (manual in MVP, logged).
- Backups: local demo has none (documented); Supabase path inherits project PITR limits — paste at Phase 5.
- Media: compress + cap; orphaned local photos GC'd after successful upload + 30d (or on logout for private devices shared-use warning).
