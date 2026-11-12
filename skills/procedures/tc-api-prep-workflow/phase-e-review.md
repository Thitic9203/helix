# TC API prep — Phase E

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase E as its WORKFLOW.md section names. Every rule here is a full gate of the workflow.

## Phase E — Coverage & quality review (mandatory; 1–2 rounds) [medium freedom]

MUST complete **before** Phase F.

### E1 — Spec & Swagger coverage (API scope)

Follow [spec-coverage-review.md](references/spec-coverage-review.md):

- Build the **endpoint coverage matrix** (in-scope operations → `TC_API_*`).
- Confirm alignment with **API spec** and **Swagger** — no invented content, no speculation, nothing out of scope (no invented endpoints; out-of-scope list documented).
- Multiple TCs per endpoint allowed when scenarios differ (auth, validation, 4xx).

### E2 — International TC quality (ISTQB + ISO/IEC/IEEE 29119-3)

Follow [tc-quality-standards.md](../../../references/tc-quality-standards.md) on every row. API default set: Test Data is the step; Expected Result leads with the status code.

Also verify writing rules in [api-tc-guidelines.md](references/api-tc-guidelines.md) (status codes, payloads, no secrets).

### E3 — Post review summary in chat

Post the **API TC coverage review** block from spec-coverage-review.md: the endpoint matrix table (one row per in-scope operation) comes before **Ready for draft: YES**; a one-line "Endpoint coverage: complete" without the table is not the block.

🔴 **STOP —** MUST NOT post the full TC table until **Ready for draft: YES**.

### E3b — Coverage delta summary

Post the table from [coverage-delta-template.md](../../../references/coverage-delta-template.md) (API section).

If review fails → revise Phase D and re-run E1–E3b (max 2 rounds).

**After 2 failed rounds →** post the review block with **Ready for draft: NO** plus the gap list (each gap: operation or spec item + what is missing), then 🔴 **STOP** and ask the user to narrow the scope or supply the missing spec/Swagger. Do not draft (Phase F) until a new round reaches **Ready for draft: YES**.

**Go back:** On the user's answer, return to Phase D with the narrowed scope or new source; the round count restarts.
