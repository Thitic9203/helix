---
name: tc-api-prep-workflow
---

<!-- When to use / not use: see the description in ../../tc-api-prep-workflow/SKILL.md (single source). -->

# TC API Prep Workflow

Prepare **API manual test cases** from an **API spec** and **Swagger/OpenAPI**, show a draft in chat for approval, then either **post a comment** at a user-provided link or **write CSV/Excel** in the workspace for download.

## Contents

This file holds the start of the run (checklist, discipline, Refusal-first, Phases A–C) and MUST / NEVER. Phases D–G and QA closing live in their own files next to this one; open each when its checklist line is reached, not before.

## Progress checklist

Copy this block into your response when the run starts and tick each line as it completes. A
failed gate sends you back to the step its **Go back:** line names — untick from there.

```text
TC API prep progress:
- [ ] Refusal-first (precondition gate)
- [ ] Phase A — API sources
- [ ] Phase B — Table format
- [ ] Phase C — Delivery + its dependency checks
- [ ] Phase D — Scope and design
- [ ] Phase E — Coverage review (1–2 rounds)
- [ ] Phase F — Draft (approval gate)
- [ ] Phase G — Deliver (after approval)
- [ ] QA closing (before "done")
```

## Discipline

Follow [shared-preamble.md](../../../references/shared-preamble.md).

**Gates:** MUST NOT post a comment or write files until the user approves the draft in chat (Phase F) — because delivery is irreversible without rework.

## Refusal-first (precondition gate)

MUST refuse to start Phase D (design) until **both** are available:

| Input | Because |
|-------|---------|
| API spec (link, file, or pasted scope) | Defines in-scope behavior |
| Swagger/OpenAPI (URL or local path) | Source of truth for endpoints and schemas |

On first response after constraints, follow [workspace-guide-discovery.md](../../../references/workspace-guide-discovery.md) for **TC API prep**, then show [intake-one-pager.md](../../../references/intake-one-pager.md) (TC API section).

---

## Phase A — API sources (mandatory) [medium freedom]

Collect in **one** message (skip fields already provided):

| Field | Required | What to collect |
|-------|----------|-----------------|
| **API Spec** | Yes | Link, file path in workspace, Confluence page, or pasted summary of scope |
| **Swagger** | Yes | OpenAPI/Swagger URL (JSON or YAML) or local spec path |

🔴 **STOP — wait** until both are answered (or user says spec is only in Swagger → treat Swagger as both).

Load the spec:

- Fetch the URL. When it returns 401/403 or a login page, ask the user for an authenticated export or session — never guess credentials.
- Parse paths, methods, parameters, request bodies, response schemas, security schemes.
- Spec requires auth but Swagger has no `security` (operation or global) → say so in the sources summary and ask how the 401/403 rows are sourced (Phase D gap rule).
- Note base URL / servers from `servers` or user override.

If load fails → stop and report; ask for an export file or VPN. Loads but does not parse as OpenAPI → stop, report the parser error and location, ask for a valid export. Never invent endpoints.

Count the Swagger operations in scope (one operation = one method + path pair). If the count is **more than 15**, or the user asks for a whole service, follow [tc-api-chunked-scope.md](../../../references/tc-api-chunked-scope.md) before Phase D — 🔴 STOP until the user agrees the chunk list.

### Phase A optional — Swagger / spec diff

If the user mentions Swagger **changed**, a **new API version**, or updating existing API TCs, run [swagger-diff-phase.md](../../../references/swagger-diff-phase.md) before Phase D.

---

## Phase B — Test case table format (mandatory) [medium freedom]

Read [references/default-columns.md](references/default-columns.md) and pick the branch from the user's messages so far:

| User's messages so far | Phase B action |
|------------------------|----------------|
| Already said they want the default columns (e.g. "default columns", "no extra columns", "the default set is fine") | State the default columns in **one line** (`Columns: default — Test Case ID, Module / Feature, …`) and record them — **do not ask the question below again**; the user has already answered it. |
| Already fixed the delivery (Phase C answer, e.g. "as CSV", "comment on {link}") but say nothing about columns | State the default columns in **one line** instead of the summary table, and still ask the question below — a delivery answer does not answer the column question. Phase C then skips only the delivery fields already fixed. |
| Ask for custom, extra or different columns | Show the default column summary table, apply the user's changes, and ask the question below. |
| Silent on delivery | Show the default column summary table (summary only — do not duplicate the full definitions here) and ask the question below. |
| Anything else (e.g. delivery only partly fixed — "comment" with no link) | Same as *Silent on delivery*: show the summary table and ask the question below. |

```text
Do you want to add any columns beyond the default API set?
If the default set is fine, reply **default** or **no changes**.
```

🔴 **STOP — wait for an answer in every branch except the first** (the user has not said which columns they want until they answer this question; silence on columns is not "default"). Record the final column list for Phases D–G.

---

## Phase C — Where to deliver (mandatory) [medium freedom]

Ask in **one** message:

```text
After you approve the draft, how should I deliver the test cases?

A) **Comment on a link** — paste the full URL (e.g. Jira issue, Confluence page).
B) **Downloadable file** — I will create CSV and/or Excel in your workspace (you choose format), and/or a Test.md file (agent hand-off, alongside CSV/Excel).

You can pick A, B, or both. For (A), provide the link now. For (B), say CSV, Excel (.xlsx), or both, whether you also want Test.md, and preferred folder (default: references/).
```

| Choice | Collect now |
|--------|----------------|
| **A — Comment** | Full destination URL (a Jira issue is always published as ADF in G2) |
| **B — File** | `CSV` / `Excel` / `both`, and/or a Test.md file (agent hand-off, alongside CSV/Excel); optional path e.g. `references/{name}_API_TC.csv` |
| **Both** | Link + file preferences |

Link is neither a Jira issue nor a Confluence page → 🔴 **STOP**: say it is unsupported; offer B or a Jira/Confluence link.

Skip the question for any field the user's messages already fixed (the link for A; format and folder for B — folder defaults to `references/`), and state the recorded choice in one line instead.

🔴 **STOP — wait for an answer** to every field still missing before designing and drafting (Phases D–F).

Delivery recorded → before Phase D, check each SKILL.md § Dependencies row it uses, at the point that row names; a failed check is a stop.

---

## Phase D — Scope and design [medium freedom]

At Phase D, open [phase-d-scope-design.md](phase-d-scope-design.md) and follow every line of it before you move on.

---

## Phase E — Coverage & quality review (mandatory; 1–2 rounds) [medium freedom]

At Phase E, open [phase-e-review.md](phase-e-review.md) and follow every line of it before you move on. Mandatory: 1–2 review rounds before any draft is shown.

---

## Phase F — Draft in chat (approval gate) [medium freedom]

At Phase F, open [phase-f-draft.md](phase-f-draft.md) and follow every line of it before you move on.

---

## Phase G — Deliver (after approval only) [low freedom]

At Phase G, open [phase-g-deliver.md](phase-g-deliver.md) and follow every line of it before you move on.

---

## QA closing (mandatory before "done") [low freedom]

It is the last section of phase-g-deliver.md; finish it before reporting done.

---

## Out of scope

- Automated API test scripts (Postman/Playwright API) unless user asks separately
- Executing tests — see [skill-routing.md](../../../references/skill-routing.md)
- Opening bugs — see [skill-routing.md](../../../references/skill-routing.md)

---

## References

All shared references and the trigger that opens each: [skill-reference-index.md](../../../references/skill-reference-index.md). This skill's own files, opened at the step that names them: [default-columns.md](references/default-columns.md) (Phase B), [api-tc-guidelines.md](references/api-tc-guidelines.md) (Phase D/E), [spec-coverage-review.md](references/spec-coverage-review.md) (Phase E), [delivery-options.md](references/delivery-options.md) (Phase C/G), [markdown-template.md](references/markdown-template.md) (Phase F), [worked-example.md](references/worked-example.md) only when a format sample is needed, [scripts/README.md](scripts/README.md) (optional CSV helper).

---

## MUST / NEVER

Shared rules: at Phase G, before the first write, read [shared-must-never.md](../../../references/shared-must-never.md). Skill-specific:

| Rule | Because |
|------|---------|
| MUST refuse without API spec + Swagger (Swagger counts as both only when the user says the spec lives there) | No authoritative coverage |
| MUST order rows: success (2xx) first within each module | Reviewers verify happy path before error paths |
| MUST NOT invent endpoints not in spec/Swagger | False coverage |
| MUST NOT guess credentials when the spec or Swagger URL returns 401/403 or a login page — ask for an authenticated export or session | Guessed credentials can lock the account and are a security risk |
| MUST NOT fall back from xlsx to CSV without warning the user and asking first | The user asked for Excel; a silent CSV is the wrong deliverable |
| MUST run Phase E review before draft table | Prevents out-of-scope API cases |
| MUST apply tc-quality-standards on every row | ISTQB / 29119-3 consistency |
| MUST convert `<br>` to Jira-native line breaks before posting (see [jira-linebreak-conversion.md](../../../references/jira-linebreak-conversion.md)) | `<br>` renders as literal text on Jira |
| MUST pass post-publish review ([jira-comment-post-review.md](../../../references/jira-comment-post-review.md)) before reporting "commented" or "done" to user | Prevents false success claims with broken formatting |
| MUST attach CSV/Excel to the Jira issue whenever a file was generated in this run and the delivery includes A (A alone or both) — not just leave it in the workspace | User expects downloadable file on the issue |
| MUST verify destination UI when using delivery A | Truncation + literal `<br>` |
