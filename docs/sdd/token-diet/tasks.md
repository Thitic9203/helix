# Tasks — token diet

| # | Task | Rule | Test that fails first | Done when |
|---|---|---|---|---|
| 1 | Router reads routing files only (lane L24) | R1, R6 | `graph.py` shows helix mandatory 28,860 > 14,430 | helix direct ≤ 14,430; routed totals drop 12.5K–26.1K; CI green |
| 2 | Session-start reference + one line in every stub and `commands/helix.md` (lane L24) | R5 | a scripts test that greps every SKILL.md for the link fails | test passes; the install question names both reasons; decline path present |
| 3 | Trigger-based loading in 6 stubs + phase checklist (lane L25) | R2, R6 | `graph.py` counts phase files as mandatory | retest, testing-ticket, tc-fe phase files no longer mandatory; each named at its checklist step |
| 4 | Split `qa-evidence-gates.md` (lane L26) | R3, R6 | a diff of rule lines (original vs union of parts) is empty only when nothing was dropped; link check | rule-line diff empty; all anchors resolve; catch-ai, tc-review link core only |
| 5 | Shared reference index + single copies of repeated blocks (lane L26) | R4 | `dup.py` lists the blocks; structure CI | `dup.py` shows none of the listed blocks repeated; CI green |
| 6 | Re-measure and eval round (lane L28) | Done when | — | every skill direct and routed ≤ 50% of the spec table; eval per skill not worse than after-10 |
| 7 | Release helix and sync ols-qa (lane L29) | Done when | — | GitHub Release on helix; ols-qa sync PR merged with parity files |

Order: 1 → 2 → 3 → 4 → 5 (each its own PR, ols-qa first for shared text) → 6 → 7. Tasks 1–5 need the owner's plan approval first (ADLC gate, global rule 27).

## Lanes (owner 11/Nov/2026: "แยกเลนทำให้มากที่สุด", every lane runs `superpowers:verification-before-completion` before claiming done)

File-disjoint, run in parallel, edits in ols-qa (shared skills) or helix (scripts):

| Lane | Files owned | Rules |
|---|---|---|
| ROUTER | `skills/helix/SKILL.md`, `commands/helix.md` | R1, R4, R5 |
| REFS | new `references/session-start-context.md`, `references/skill-reference-index.md` | R4, R5 |
| GATES | `references/qa-evidence-gates.md` + new `qa-evidence-capture.md`, `qa-evidence-rerecord.md`, `qa-evidence-coverage.md` | R3 |
| RETEST | retest stub + `skills/procedures/retest-bug-workflow/**` | R2, R4, R5, R9 |
| TT | testing-ticket stub + procedures + `references/parallel-test-lanes.md` | R2, R4, R5, R9 |
| TCFE | tc-fe stub + procedures | R2, R4, R5, R9 |
| SMALL | create-bug, tc-api-prep, review-result stubs + procedures | R2, R4, R5 |
| CR | `skills/catch-ai-workflow/SKILL.md`, `skills/tc-review-workflow/SKILL.md` | R2, R3 links, R4, R5 |
| INSTALL (helix) | `scripts/install.sh`, `scripts/link-skills.sh`, `scripts/helix-doctor.sh`, tests, README/wiki | R8 |
| DESC (after the skill lanes merge) | frontmatter `description` of every SKILL.md + trigger eval | R10 |

Merge order: REFS and GATES first (new files), then the skill lanes rebase; then sync to helix and parity; then DESC; then task 6 (re-measure + eval) and task 7 (release).
