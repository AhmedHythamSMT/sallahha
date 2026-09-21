# Sallahha FieldOps — Demo Video Script (3–4 min)

**Audience:** hiring managers, senior engineers, portfolio reviewers.
**Format:** screen-recorded on Xiaomi (ADB `screenrecord` or handheld), Arabic UI with English captions.
**Length:** 3 min core + 1 min optional offline deep-dive.

---

## 0:00–0:15 — Hook (Arabic, then English)

> **AR:** "صلّحها — إدارة صيانة ميدانية عربية أولاً، تعمل أوفلين بالكامل."
> **EN:** "Sallahha FieldOps — Arabic-first, offline-first field service management for Egyptian AC shops."

**Visual:** app icon → launch → Arabic RTL home screen (4 role cards).

---

## 0:15–0:45 — Customer Flow (2 taps + form)

1. Sign in as **customer@demo.test** / `demo1234`.
2. **طلب صيانة جديد** → select *إصلاح تكييف* → type problem: *"التكييف ما بيبردش وطالع هواء دافئ"* (AR) → address *12 شارع مصدق، الدقي* → governorate *الجيزة* → phone *01000000001* → optional slot *بكرة بعد العصر* → **إرسال الطلب**.
3. Lands on **details**: header (description, address, SLA due), **جديد** badge, timeline with single entry.

**Narration:** "Three minutes from open to submitted. SLA clock starts now."

---

## 0:45–1:30 — Supervisor Dispatch (3 taps)

1. Sign out → **supervisor@demo.test** → **التوزيع** tab **جديدة**.
2. Request shows **اقتراح الفرز: cooling / high** with reasons (keyword highlights).
4. Tap 👤 → pick **Hassan Ali** (workload: 2 active) → **إسناد**.
5. Row moves to **نشطة**, workload updates, tech gets push → **تنبيهات** has entry.

**Narration:** "Triage is deterministic rules — no ML, human confirms. One tap assigns."

---

## 1:30–2:30 — Technician Execution (Offline Proof)

1. Sign out → **tech@demo.test** → **مهامي** → open assigned job.
2. **مقبول** → **في الطريق** → **وصل** → **قيد التنفيذ** (each with Synced badge).
3. **صورة قبل** → camera (permission) → snap → thumbnail appears **بانتظار المزامنة**.
4. Add diagnosis note: *"ضعف فريون + تنظيف فلاتر"*.
5. Add part: *فريون R410A ×1*.
6. Set estimate: *450 ج.م*.
7. **مكتمل** → **تأكيد استلام العمل** (customer) → **5★** rating.

**Narration:** "Every tap works in a basement. Status, photos, parts, estimate — all queue locally."

---

## 2:30–3:00 — Airplane Mode Deep-Dive (Optional Extended Cut)

1. **إعدادات → وضع الطائرة** ✈️ (ping 8.8.8.8 unreachable).
2. Open **مهامي** → list loads from SQLite (cached headers).
3. Open a job → advance statuses, add note, add part.
3. Banner shows **لا يوجد اتصال — التغييرات محفوظة وستُزامَن**.
4. Kill app → reopen → data intact.
5. **إعدادات → إيداع وضع الطائرة** → Wi-Fi back → **تمت المزامنة** badges flip, supervisor sees updates.

**Narration:** "Zero data loss. Idempotency keys prevent duplicates. Conflict policy is explicit, never silent."

---

## 3:00–3:30 — Security & Quality Gates

**Quick cuts:**
- `flutter analyze` → clean.
- `flutter test` → 61 passed (unit: rules, triage, sync; widget: AR/EN, guards, back; integration: journey, repo).
- GitHub Actions badge green.
- DB inspection: `sync_operations` all `acked`, zero `failed`.
- `flutter_secure_storage` session survives force-kill + relaunch.
- No secrets in git (`.env.example` only).

---

## 3:30–4:00 — Interview Angles (Closing)

> "Flutter: Riverpod + go_router + RTL + offline states.
> Backend: ERD, API contract, authz matrix, idempotency, pagination.
> DevOps: CI gates, `.env` hygiene, APK build.
> QA: unit (status machine), widget (AR/EN), integration (airplane E2E).
> Security: threat model, checklist, secure storage, upload validation.
> AI: rules-v1 model card, why ML deferred, promotion bar."

**End frame:** GitHub repo URL + QR code.

---

## Recording Checklist

- [ ] Xiaomi at 100% brightness, Do Not Disturb.
- [ ] `adb shell screenrecord /sdcard/demo.mp4 --time-limit 240 --bit-rate 8000000`.
- [ ] Arabic keyboard visible in form fills.
- [ ] Slow, deliberate taps (ADB taught me: aim low by ~120px on HyperOS).
- [ ] Captions: Arabic first, English below.
- [ ] Post-prod: trim dead air, zoom on badge transitions, blur any real names/phones.
- [ ] Upload to YouTube (unlisted) + embed in README.

---

## Interview Cheat Sheet (One-pager)

| Question | 60-second Answer |
|----------|------------------|
| "Why offline-first?" | Egyptian AC techs work in basements/rooftops with no signal. Status, photos, parts must queue and sync with idempotency keys — zero data loss, zero duplicates. |
| "Why Riverpod not Bloc?" | Solo 8-week MVP: one system for state + DI, less boilerplate, compile-safe providers, easier test mocks. Bloc is great for teams; Riverpod is faster alone. |
| "Why Drift not Hive/Isar?" | Relational data (assignments, history, parts joins). Drift = real SQL + migrations + reactive streams + testable DAOs. Hive is KV; Isar trajectory uncertain. |
| "Why no Firebase?" | Firestore fights our joins; its offline is cache-sync, not our explicit outbox; pricing anxiety for a pilot. Supabase = same SQL, RLS, free tier, keyless demo. |
| "How do conflicts resolve?" | Status → server wins (technician never overrides supervisor). Notes → last-write-wins + history. Assignment/estimate/parts → reject-and-flag. Never silent. |
| "What's the AI story?" | Rules-v1: keyword triage + priority + tech scoring. Deterministic, offline, audited, human-confirmed. ML waits for 500+ labeled tickets + published metrics — model card is honest. |
| "How do you test offline?" | `MemoryOpLog` + `SyncEngine` unit tests (FIFO, backoff, retry, conflict, restart). Integration: airplane-mode create → reconnect → `acked`, no duplicate. Widget: `pageBack` via `handlePopRoute`. |
| "What's the biggest risk?" | WhatsApp inertia. Mitigation: 3-tap Arabic flows, import-from-WhatsApp story, pilot with 1 friendly shop measuring missed-visit ↓. |
| "What would you build next?" | Web dispatcher console → real Paymob → FCM prod → second vertical (elevators). ML only with labeled data. |
| "Show me the code." | `lib/features/requests/data/request_repository_impl.dart` — enqueue-first, provisional local apply, durable outbox, replay with rebase. |

---

## Files to Hand Over

- `demo.mp4` (3:30, YouTube unlisted + embed)
- `README.md` (this repo)
- `docs/` (27 files: product, arch, backend, testing, security, UX, AI)
- `CHANGELOG.md` (0.1.0 → 0.6.0)
- `flutter build apk --release` (if keystore) or `--debug` APK