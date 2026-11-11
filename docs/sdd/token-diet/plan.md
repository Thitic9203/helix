# Plan — token diet

## Where changes land

Shared skill text is edited in **ols-qa** (source for the sync) and reaches helix through the existing sync PR; helix-only files (`skills/helix/`, `references/` owned by helix, scripts) are edited in helix. Each change is one PR per area so a regression is easy to trace.

## Files

| Rule | Files | Change |
|---|---|---|
| R1 | `skills/helix/SKILL.md:129-141` | drop the three forced gate reads from the router; keep the routing table, intent shortcuts, menu text |
| R2 | 6 stubs (`create-bug`, `retest-bug`, `review-result`, `tc-api-prep`, `tc-fe-prep`, `testing-ticket` SKILL.md) · their WORKFLOW.md Contents sections | replace "every step, gate, and reference" with "open each file at the step that names it"; checklist line per phase file |
| R3 | `references/qa-evidence-gates.md` → `qa-evidence-gates.md` (core) + `qa-evidence-capture.md` + `qa-evidence-rerecord.md` + `qa-evidence-coverage.md`; all links to its anchors | split by section; a link checker run proves every anchor resolves |
| R4 | `references/skill-reference-index.md` (new) · stub bullet lists · duplicated blocks in `parallel-test-lanes.md`, `bug-priority-matrix.md`, retest and testing-ticket procedure files | one index; keep one copy, link from the rest |
| R5 | `references/session-start-context.md` (new) · first line of each SKILL.md and `commands/helix.md` | the rule, the install question and reasons, the decline path, host note |

## Measuring

- Tokens: `graph.py` / `dup.py` from ols-qa-evidence `docs/helix-quality/wayfinder-token-diet/` on a `git archive` copy, before and after each PR.
- Results: one eval round with the after-10 exam folder layout (`make_round.sh <commit>`), compared skill by skill with after-10 `GATE.md`.

## Options weighed

- Delete gate references to save tokens → rejected (R6).
- Load everything lazily with no checklist trigger → rejected: a gate could be skipped; the checklist names each file (R2).
- One big PR → rejected: a regression could not be traced to one change.

## What could break

- Anchor links after the split (R3) → link check in CI and `scripts/tests`.
- Skill-structure CI expects certain stub sections → run `ci-check-skill-structure.sh` per PR.
- Eval scores: darwin dims reward clear required-reading lists; moving them may change dim scores → measured in the eval round, not assumed.
- ols-qa parity: the sync PR must carry the new references (memory: new helix skill → ols-qa parity files).

## Cost

No new paid service. caveman and context-mode are free plugins; R5 only asks the user to install them (global rule 3).
