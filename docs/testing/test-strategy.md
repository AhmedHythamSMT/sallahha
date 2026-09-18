# Test strategy

## Pyramid
- **Unit (pure Dart, no widgets):** status machine (all 9 states incl. illegal), SLA/overdue calc, priority/triage rules, pricing totals, sync backoff + dedupe, conflict policy, payment state machine, triage explanations. Target: ~100% of `domain/` business rules.
- **Widget:** login, request-create, job-details, offline banner, sync badges, loading/empty/error states, AR-RTL + EN-LTR, a11y labels. Use fakes (FakeAIService, MockRemote).
- **Repository:** local-first fallback, cache-then-remote, retry, idempotent re-apply.
- **Integration (1+ E2E):** customer→supervisor→technician-offline→reconnect→confirm→rate on emulator, incl. airplane-mode segment; payment-mock flow; permission-rejection flow.

## Offline matrix (must all pass)
offline-create · offline-status-update · reconnect-flush · retry-backoff · duplicate-op dedupe · failed-sync + manual retry · status conflict (server wins) · text conflict (LWW+history) · restart-with-pending.

## Quality gates (CI + local)
`dart format --set-exit-if-changed .` · `flutter analyze` · `flutter test` · build_runner check (if codegen dirty) · `flutter build apk --debug` (release-like when keystore exists). No artificial global % chase; report per-area coverage and uncovered list in PRs.
