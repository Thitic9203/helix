# TC API prep — Phase D

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase D as its WORKFLOW.md section names. Every rule here is a full gate of the workflow.

## Phase D — Scope and design [medium freedom]

From API spec + Swagger:

1. Group endpoints by **module/feature** (tags or path prefix).
2. Per endpoint (or logical group), design cases:
   - Happy path (2xx, contract matches schema)
   - Auth (401) when the operation (or the global spec) has a `security` requirement
   - Permission (403) when the spec or Swagger names roles/scopes for the operation
   - Validation (400, or 422 when Swagger lists it) — required fields, types, bounds
   - Not found (404) when the path has an id parameter; conflict (409) when Swagger lists 409 for the operation
   - Idempotency / side effects when the spec or Swagger documents them (row shape: [api-tc-guidelines.md](references/api-tc-guidelines.md) § Coverage per endpoint)
   - **Swagger leaves an operation's statuses or auth undocumented** (no `responses`, or only `default`; or no `security` on the operation or globally while the spec says auth is required):
     - the API spec states no status for that case either → do not invent one for those error rows: list the operation under **Spec/Swagger gaps flagged** in the Phase E review block, ask the user for the expected status, and 🔴 **STOP** before writing those rows;
     - the spec states one → use it, flagged as a gap;
     - no `security` and the spec is silent on auth → treat the operation as public: no 401 row, listed under out of scope.
3. Map each row to **Services Impacted** from spec or user naming.
4. **Test Case ID** pattern: `TC_API_{Module}_{nn}` — unique; `nn` follows the row order below (every 2xx row of a module has a lower `nn` than any 4xx row), so renumber whenever Phase D/E adds or moves a row; ids are stable only after the user approves the Phase F draft.

Writing rules: [references/api-tc-guidelines.md](references/api-tc-guidelines.md).

Story AC mapping: only when the user gave a Jira story key in the same session and asked for it, map cases to AC — default is **API coverage from spec**, not story AC.

### Row ordering within each module

Within each module/feature group, order rows as follows:

1. **Happy path / success cases** (2xx) — listed first
2. Auth / permission failures (401, 403)
3. Validation / bad request (400)
4. Not found / conflict (404, 409)
5. Other error scenarios
