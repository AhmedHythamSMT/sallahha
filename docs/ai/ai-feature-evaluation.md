# AI feature evaluation — verdict: rules in MVP, ML post-MVP (if ever)

| Feature | User value | Data/model needs | Risks | Rules-better? | Verdict |
|---|---|---|---|---|---|
| A. Issue classification (cooling/electrical/leak/noise/no-power/cleaning) | Medium: faster triage | Needs 500+ labeled AR/EN tickets; dialect variance | Wrong category → wrong tech; trust erosion | **Yes** — keyword + service-type rules with confidence | MVP: RuleBasedTriageService w/ reason + human confirm |
| B. Priority suggestion (normal/high/urgent) | Medium: SLA protection | Same labels + SLA outcomes | Over-escalation fatigue; safety overclaim | **Yes** — urgent-keyword list (no-cooling+infant/elderly, spark, burning smell→call-now warning, not auto-dispatch) | MVP: rules + confirm + audit |
| C. Technician matching | High: first-time-fix | Skills/availability/distance/history | Stale skills; distance without tracking | **Yes** — deterministic score (skill×3 + availability×2 + active-load penalty + same-governorate) | MVP: scoring function, no ML |
| D. Note summarization | Low-Med: customer SMS | Seq2seq/LLM; AR dialect | Hallucinated promises/costs | **Yes** — template from fields (status+parts+estimate) | Post-MVP at most; template now |
| E. Photo diagnosis | Claimed high, actual negative | 10k+ labeled fault photos; expert review | Unsafe, liability, unvalidatable | N/A — don't build | **Rejected** for MVP and roadmap-early |

Honest line for interviews: **"AI is intentionally rules-based in the MVP because deterministic triage gives more value with less cost, less risk, and no data — ML waits for real labeled data."** No medical/safety/guaranteed-diagnosis claims ever.
