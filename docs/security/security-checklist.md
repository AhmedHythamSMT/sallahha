# Security checklist (MVP gate)

- [ ] No secrets/tokens/keys in git (`git grep -i -E "sk-|bearer|password"` clean); `.env` ignored.
- [ ] Tokens in flutter_secure_storage; logout clears; 401 → re-login.
- [ ] Server-side authz per `authorization-matrix.md` (UI hiding is not enforcement).
- [ ] Input validation client + server; phone/address length caps; rating 1–5.
- [ ] Uploads: jpg/png only, ≤5MB, count cap, compress <1MB, error on violation.
- [ ] No PII/tokens in logs, crash reports, notification previews, analytics events.
- [ ] Idempotency keys on all mutations; payment double-submit safe.
- [ ] Minimal permissions (camera/gallery/location-when-needed with rationale AR/EN).
- [ ] Deps audited (`dart pub audit`); no unneeded packages.
- [ ] Demo data clearly seeded + deletable; prod/demo separation documented.
- [ ] Map keys (if any) restricted; OSM tile policy respected.
