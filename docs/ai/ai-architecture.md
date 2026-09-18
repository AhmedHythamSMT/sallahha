# AI architecture (MVP: deterministic; ML-ready seams)

```
UI (triage hint card w/ reason + [Confirm][Edit])
 └▶ TriageProvider (Riverpod)
     └▶ AIService (interface: suggestCategory(), suggestPriority(), matchTechnician(), explain())
         ├▶ RuleBasedTriageService  ← MVP default, pure Dart, fully offline, tested
         ├▶ FakeAIService          ← tests / demo determinism
         └▶ (post-MVP) MlClassifierAdapter: TF-Lite/ONNX small model, optional, flagged off
```

- Every suggestion returns `{ label, confidence 0..1, reasonsAr/En[], modelId:'rules-v1', humanConfirmed:bool }`; confirmations/edits appended to AuditEvent.
- No network, no PII leaves device; offline fallback = rules (always available).
- ML promotion bar (all required): ≥500 real labeled tickets, measured precision/recall per class published in model-card, bias check (governorate/dialect), license+size documented, on-device only, human-confirm retained.
