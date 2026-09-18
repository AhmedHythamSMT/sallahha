# Authorization matrix (must be enforced server-side, not just UI)

| Action | Customer | Technician | Supervisor | Admin |
|---|---|---|---|---|
| Create request | own only | — | — | — |
| View requests | own only | assigned only | all | all |
| Assign / reassign | — | — | ✅ | ✅ |
| Set priority / SLA | — | — | ✅ | ✅ |
| Update status (job) | — | assigned jobs, legal transitions | ✅ (incl. cancel w/ reason) | ✅ |
| Add notes/photos/parts | — | assigned jobs | — (view) | — (view) |
| Confirm completion | own completed | — | — | — |
| Rate | own confirmed once | — | — (view) | — (view) |
| Manage users/services/parts | — | — | tech+services (no roles) | ✅ full |
| View audit | — | — | scoped (dispatch) | ✅ full |
| View reports | — | — | ✅ | ✅ |

Tests: permission-rejection flow per role (integration); RLS/policies mirror this table when Supabase adapter lands. Disabled users → 401 on next call.
