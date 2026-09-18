# AI data policy

- MVP uses **zero real training data**: rules hand-written; demo predictions run on synthetic seed tickets clearly labeled `demo`.
- If/when ML is considered: explicit shop consent, PII scrub (phones/addresses/pins stripped before labeling), on-device storage, no third-party LLM calls with customer data, annotator agreement (Arabic-dialect speakers), per-governorate sampling to avoid Cairo bias, right-to-delete honored (purge + retrain note).
- Synthetic data must never be presented as model accuracy evidence in portfolio or interviews.
