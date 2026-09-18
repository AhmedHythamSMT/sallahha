# Threat model (demo-grade; references OWASP MASVS, no compliance claim)

## Assets → threats → controls
- **Accounts/sessions:** credential stuffing, role escalation → strong demo passwords + secure token storage + server-side authz matrix + session expiry + audit.
- **Customer PII (phone/address/location):** leak via logs/notifications/backups → minimal collection, no PII in logs or push previews, location optional + coarse, demo data flagged.
- **Job photos:** privacy + malicious uploads → type/size validation (jpg/png ≤5MB), compress, strip EXIF location where possible, per-request scoping.
- **API abuse:** replay/duplicates, enumeration → idempotency keys, auth on all routes, pagination caps, rate-limit note for real backend.
- **Payments:** double-charge → state machine + idempotency; MVP = mock only, no card data anywhere.
- **Local storage:** rooted-device read → tokens in secure storage, DB minimale, logout wipes session.
- **Supply chain:** vulnerable deps → `flutter pub audit` / `dart pub audit` in CI, minimal packages.
- **Secrets:** `.env` gitignored, `.env.example` only, CI placeholders, mock mode without keys.

## Out of scope honesty
No formal MASVS audit, no pen-test, no cert claims. This doc + checklist + demo privacy policy are engineering hygiene for a portfolio MVP, not legal compliance.
