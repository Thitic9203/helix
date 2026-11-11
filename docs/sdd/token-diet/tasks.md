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
