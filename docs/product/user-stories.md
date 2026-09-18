# User stories (MVP) + acceptance criteria (excerpt)

Format: As a <role> I want <goal> so that <value>. AC = Given/When/Then.

## Auth
- US-A1: As a user I want to sign in with email/password so that I see my role workspace.
  - AC: Given demo account `supervisor@demo.test` / When sign-in / Then queue screen shows within 3s; wrong password → Arabic error, no crash.
- US-A2: As an admin I want to list users by role so that I can disable leavers.
  - AC: Disabled user gets `unauthorized` state on next action.

## Requests
- US-R1: As a customer I want to create a request with photo + slot so that I don't need to call.
  - AC: Given valid form / When submit / Then request appears with status `new` + timeline entry; offline → `pending` badge, auto-retries.
- US-R2: As a customer I want to track status so that I stop calling the shop.
  - AC: Every status change appends timeline + notification entry.

## Dispatch
- US-D1: As a supervisor I want to assign a technician in ≤3 taps so that triage is fast.
  - AC: Assign writes JobAssignment + StatusHistory + AuditEvent atomically (logical); technician's list updates after sync.
- US-D2: As a supervisor I want overdue flags so that breaches are visible.
  - AC: Request past `slaDueAt` and not completed/cancelled appears in Overdue with red badge.

## Jobs
- US-J1: As a technician I want my jobs offline so that basements don't block me.
  - AC: Given synced jobs + airplane mode / When reopen app / Then job details open fully; status taps queue in outbox.
- US-J2: As a technician I want guarded statuses so that I can't skip illegally.
  - AC: `new→completed` rejected with typed error naming legal next states.
- US-J3: As a technician I want before/after photos + parts so that proof is complete.
  - AC: Complete requires ≥1 diagnosis note; photos optional but prompted; parts from catalog with qty ≥1.
- US-J4: As a customer I want to confirm + rate so that quality is recorded.
  - AC: Confirm enabled only when status `completed`; rating 1–5 required to close feedback.

## Sync / offline
- US-S1: As a technician I want pending/failed badges + retry so that I trust the app.
  - AC: Failed op shows reason + Retry button; retry uses same idempotency key (no duplicate on server fake).

Full matrix of status-transition tests lives in `docs/testing/test-strategy.md`.
