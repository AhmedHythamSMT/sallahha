# User journeys — MVP spine

## J1. Customer books AC repair (happy path)
1. Opens app (Arabic default) → taps "New request".
2. Picks service type (e.g. "Split AC — no cooling") → writes description (voice-typed ok) → optional photo → address + governorate + phone → preferred slot.
3. Submits → sees request card `New` with ID + timeline. Gets notification on assign / status change.
4. Technician arrives, fixes, shows before/after photos + parts + estimate.
5. Customer taps Confirm → rates 1–5 (+comment) → request closed.
- Failure branches: no internet at submit → queued as pending with retry; vague address → supervisor calls (phone shown); cancel before assign with reason.

## J2. Supervisor triages + assigns
1. Opens queue → `New (3)` badge. Opens request: triage suggestion ("likely cooling problem · priority HIGH — keyword: 'no cooling'") with reason shown.
2. Confirms/edits priority, sets due time (default 24h normal / 8h high / 4h urgent), picks technician (workload shown: "Hassan — 2 active").
3. Taps Assign → assignment + audit event; technician notified (mock push).
4. Monitors: overdue view flags breaches red; reassigns in 2 taps if technician sick.
- Failure branches: no free tech → stays `New` + overdue timer runs (visible); double-assign prevented (one active assignment).

## J3. Technician works a job offline
1. Morning: opens "My jobs" on Wi-Fi → jobs sync (details cached).
2. On site basement (no signal): opens job → taps Accepted → On the way → Arrived → In progress (each queued in outbox, badge `pending`).
3. Adds diagnosis note, before photo, parts used (2× capacitor), labor note, after photo, estimate 450 EGP.
4. Marks `Waiting for parts` (day 1) → back `In progress` (day 2) → Completed + customer signature/PIN.
5. Returns to signal: outbox flushes with backoff; conflicts resolved per policy (server-authoritative status); UI shows `synced`.
- Failure branches: sync fails → `failed` badge + manual retry, data never lost; app killed mid-queue → outbox persists, resumes on launch.

## J4. Supervisor closes the loop
1. Sees completed jobs, proof bundle (photos/parts/notes/signature), customer rating.
2. Weekly: opens basic report (completed, avg hours, avg rating, overdue count) → decides bonuses / callbacks.
