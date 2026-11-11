---
name: tc-api-prep-workflow
description: |
  Prepare API manual test cases from API spec and Swagger with mandatory spec/Swagger coverage review and ISTQB/29119-3 quality check — confirm columns and delivery (Jira comment link and/or CSV/Excel in workspace).
  Use when the user chooses TC API Preparation from Helix, invokes /tc-api-prep, or asks for API test cases from Swagger/OpenAPI. Use it whenever the user wants manual test cases for REST endpoints, an OpenAPI/Swagger file or a Postman collection — even if they do not say Swagger or TC (e.g. "เขียนเทสเคส API").
  Do NOT use for frontend story AC/EC tables (tc-fe-prep-workflow), Playwright or test execution (testing-ticket-workflow), retest-after-fix (retest-bug-workflow), or opening bugs (create-bug-workflow).
metadata:
  proactive_triggers:
    - /tc-api-prep
    - TC API prep
    - API test cases
    - Swagger test cases
    - OpenAPI test cases
---

# TC API Prep (discovery stub)

**Thin entry for agent skill discovery.** Full procedure: [WORKFLOW.md](../procedures/tc-api-prep-workflow/WORKFLOW.md).

When invoked:

1. First, before any other work, follow [session-start-context.md](../../references/session-start-context.md) (caveman lite + context-mode).
2. Announce once: `Using **tc-api-prep-workflow** to prepare API manual test cases.`
3. Read [WORKFLOW.md](../procedures/tc-api-prep-workflow/WORKFLOW.md) and run its progress checklist in order; open each phase or reference file at the step that names it, not before. Never skip a step or gate.

Slash-command shortcut (runtimes that support commands): `/tc-api-prep` → [commands/tc-api-prep.md](../../commands/tc-api-prep.md).

## Contents

Shared reference index, with the trigger that opens each file (see also): [skill-reference-index.md](../../references/skill-reference-index.md).

At the start of every run: [shared-preamble.md](../../references/shared-preamble.md), [user-communication.md](../../references/user-communication.md), [long-workflow-todos.md](../../references/long-workflow-todos.md), then [workspace-guide-discovery.md](../../references/workspace-guide-discovery.md) and [intake-one-pager.md](../../references/intake-one-pager.md) on the first response (WORKFLOW Refusal-first).

API-specific notes on shared files (apply when the step opens them):

- [tc-quality-standards.md](../../references/tc-quality-standards.md) — at Phase E, on every TC row. API mapping: with no Test Steps column (the default set, [default-columns.md](../procedures/tc-api-prep-workflow/references/default-columns.md)), Test Data (method, path, headers, body) is the step and Expected Result leads with the status code.
- [csv-export-rules.md](../../references/csv-export-rules.md) — at Phase G1, when exporting. API mapping: its `{ISSUE_KEY}_FE_TC` file names become `references/{SCOPE}_API_TC.csv` / `.xlsx` (WORKFLOW G1).
- [swagger-diff-phase.md](../../references/swagger-diff-phase.md) — when Swagger changed, a new API version shipped, or existing API TCs are being updated; [tc-api-chunked-scope.md](../../references/tc-api-chunked-scope.md) — when more than 15 Swagger operations are in scope or the user asks for a whole service.
- [csv-template-types.md](../../references/csv-template-types.md) — at Phase G1, before exporting a CSV; [test-md-format.md](../../references/test-md-format.md) — only when the user picks Test.md at Phase C.
- [qa-evidence-gates.md](../../references/qa-evidence-gates.md) — before any completion claim (Phase G-verify, QA closing).
- [skill-routing.md](../../references/skill-routing.md) — read only when the request turns out not to be API TC drafting and another skill owns it.
- Execution-only files (bug priority matrix, Playwright, non-pass and result gates) are never triggered: this workflow writes test cases; it never runs tests, records verdicts or opens bugs. The TC **Priority** column follows [api-tc-guidelines.md](../procedures/tc-api-prep-workflow/references/api-tc-guidelines.md) § Priority.

Also read each only when its trigger (in WORKFLOW.md or the index) fires: [coverage-delta-template.md](../../references/coverage-delta-template.md), [helix-session-constraints.md](../../references/helix-session-constraints.md), [jira-comment-post-review.md](../../references/jira-comment-post-review.md), [jira-linebreak-conversion.md](../../references/jira-linebreak-conversion.md), [proactive-qa-triggers.md](../../references/proactive-qa-triggers.md), [result-quality-gate.md](../../references/result-quality-gate.md), [root-cause-investigation.md](../../references/root-cause-investigation.md), [round-time-contract.md](../../references/round-time-contract.md), [session-closing.md](../../references/session-closing.md), [shared-must-never.md](../../references/shared-must-never.md), [skill-invocation-discipline.md](../../references/skill-invocation-discipline.md), [skill-rules-style.md](../../references/skill-rules-style.md), [swagger-diff-phase.md](../../references/swagger-diff-phase.md), [tc-api-chunked-scope.md](../../references/tc-api-chunked-scope.md), [tc-quality-standards.md](../../references/tc-quality-standards.md), [phase-d-scope-design.md](../procedures/tc-api-prep-workflow/phase-d-scope-design.md), [phase-e-review.md](../procedures/tc-api-prep-workflow/phase-e-review.md), [phase-f-draft.md](../procedures/tc-api-prep-workflow/phase-f-draft.md), [phase-g-deliver.md](../procedures/tc-api-prep-workflow/phase-g-deliver.md), [default-columns.md](../procedures/tc-api-prep-workflow/references/default-columns.md), [agent-rationalizations.md](../../references/agent-rationalizations.md), [bug-priority-matrix.md](../../references/bug-priority-matrix.md), [csv-export-rules.md](../../references/csv-export-rules.md), [customer-escape-prevention.md](../../references/customer-escape-prevention.md), [figma-design-comparison.md](../../references/figma-design-comparison.md), [non-pass-challenge-gate.md](../../references/non-pass-challenge-gate.md), [qa-closing-shared.md](../../references/qa-closing-shared.md), [qa-debug-discipline.md](../../references/qa-debug-discipline.md), [delivery-options.md](../procedures/tc-api-prep-workflow/references/delivery-options.md), [spec-coverage-review.md](../procedures/tc-api-prep-workflow/references/spec-coverage-review.md).

## Refusal-first (precondition gate)

All preconditions and refusal rules are in WORKFLOW.md. MUST NOT start without API spec + Swagger and delivery choices confirmed.

## QA closing (mandatory before "done")

All close-out gates are in WORKFLOW.md and [verify-closing-checklist.md](../../references/verify-closing-checklist.md) § *TC FE / TC API prep* (skip its tc-fe-prep-only final-report item, and skip its attachment item unless a file was generated and the delivery includes A). MUST NOT report done until G-verify and post-publish review pass.

## Dependencies

Run the check for each of these before step 1 — check commands and install hints are in [dependencies.md](../../references/dependencies.md):

- Python 3 + `openpyxl` (xlsx only)
- Atlassian MCP
- Jira REST credentials (ADF-direct publish and the REST v3 fallback)
- `superpowers:systematic-debugging`
