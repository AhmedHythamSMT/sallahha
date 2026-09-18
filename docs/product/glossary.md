# Domain glossary — Sallahha FieldOps

| Term | AR | Definition |
|---|---|---|
| ServiceRequest (طلب صيانة) | طلب صيانة | Customer ask; has service type, description, address, slot, status, SLA due. |
| JobAssignment (إسناد) | إسناد | Link supervisor→technician; only one active per request. |
| Job (مهمة) | مهمة | Technician execution view of an assigned request. |
| StatusHistory | سجل الحالات | Append-only log of every status change (who/when/from/to). |
| JobNote | ملاحظة | Diagnosis or labor text, author-stamped. |
| JobPhoto | صورة | Before/after proof image, compressed, type-tagged. |
| Part / JobPartUsage | قطعة غيار / استخدام | Catalog part + qty consumed on a job. |
| Priority | أولوية | normal/high/urgent; suggested by triage, confirmed by human. |
| SLA / Overdue | اتفاق الخدمة / متأخر | `slaDueAt` promise; overdue = past due and not completed/cancelled. |
| Outbox / SyncOperation | صندوق الصادر | Durable queue of offline mutations with idempotency keys. |
| Idempotency key | مفتاح عدم التكرار | Client UUID per mutation; server dedupes retries. |
| Triage suggestion | اقتراح الفرز | Non-binding category/priority hint with reason + confidence. |
| Confirmation | تأكيد العميل | Customer explicit accept of completed work (button + PIN/signature). |
| Rating | تقييم | 1–5 + comment after confirmation. |
| AuditEvent | حدث تدقيق | Immutable admin-visible record of sensitive actions. |
| Workload | عبء الفني | Count of active (assigned→in_progress) jobs per technician. |
