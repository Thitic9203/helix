# Plan — untestable-case paths

## Files

| File | Change |
|---|---|
| `references/untestable-case-paths.md` | new: §1–§8 + MUST / NEVER (R1–R8) |
| `skills/procedures/testing-ticket-workflow/execute-and-summarize.md` | E2 bullet (R1, R3–R8) and E3 bullet (R2), both conditional |
| `skills/procedures/retest-bug-workflow/execute-and-evidence.md` | 4h bullet, conditional |
| `references/no-wait-decision-gate.md` | pointer after layer 16 |
| `references/skill-reference-index.md` | one index line |

## Choices

- One reference, linked with "only when" wording, so the token measure classes it as conditional (R9). Adding the text to
  SKILL.md or WORKFLOW.md (mandatory reads) would raise the budget and need an owner-approved `[token-budget-raise]`.
- Only additions; no MUST / NEVER line removed (rule-line check).

## What could break

- A link line without a conditional keyword would make the file mandatory and fail `token-budget`; checked by the PR job.
- Portable-content guard: no project names, hosts or accounts in the reference.
