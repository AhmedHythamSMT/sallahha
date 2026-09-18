# Model card — rules-v1 (deterministic triage; NOT an ML model)

- **Purpose:** assist supervisor triage; never a definitive diagnosis.
- **Logic:** AR/EN keyword sets per category (e.g. تبريد/cooling: "ما بيبردش|no cooling|warm air"), urgent triggers ("شرر|spark|ريحة حرق|burning smell" → safety-call-now banner, still human-confirmed), priority weights; full list in code + tests.
- **Inputs:** description + service type (+ optional slot). **Outputs:** category + priority + confidence (keyword-count heuristic) + reasons.
- **Limitations:** dialect gaps, sarcasm/typos, no image understanding, confidence is heuristic not calibrated probability.
- **Evaluation:** unit suite of 40+ AR/EN phrases (Egyptian dialect incl.) asserting expected label or "uncertain→normal+ask"; published pass table in repo tests. No accuracy claim beyond that suite.
- **Ethics/safety:** human must confirm; urgent-safety keywords show "call supervisor now" guidance, never auto-dispatch; no biometric/medical use.
- **Versioning:** `rules-v1`; changes logged in CHANGELOG with before/after test deltas.
