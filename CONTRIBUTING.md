# Contributing

- Language: Arabic default in UI; code + comments in English.
- No hardcoded strings — add to `lib/core/localization/strings.dart` (ARB migration in Phase 2).
- No business logic in widgets; domain code pure Dart + unit-tested.
- Presentation never touches HTTP/SQLite directly — via repositories.
- Every new package needs a row in `docs/architecture/technology-decisions.md`.
- Run before push: `dart format .`, `flutter analyze`, `flutter test`.
- No secrets in git; mock mode must keep working with empty `.env`.
- Sync failures are surfaced, never swallowed; idempotency keys on mutations.
