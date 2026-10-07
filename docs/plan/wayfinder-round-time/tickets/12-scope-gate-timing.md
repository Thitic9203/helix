---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07 c)
blocked_by: [01]
---

# Scope gate timing

## Question

Retest 2b/2c and testing Phase C stop the round so the user approves the case list and lane plan before any execution. Given the measured baseline (how long the user takes to answer this gate, and how often a scope correction has forced a re-run), should the gate stay blocking, become "show the plan and run, plan rides in the end bundle", or be conditional (for example, blocking only when the case list is not derived one-to-one from the ticket's expected results)? Carved out of [Approvals vs decisions](04-approvals-vs-decisions.md), where the user chose to wait for the numbers.

## Framing (pre-baseline, no recommendation yet)

The three options are already stated in the question (stay blocking · show the plan and run, with the plan riding in the end bundle · conditional blocking). They are put to the user as written, with these numbers from ticket 01, each marked unmeasured if the transcripts cannot show it:

- how long the user takes to answer this gate (HUMAN-WAIT at retest 2b/2c and testing Phase C), median and max;
- how often the user changed the case list or lane plan at the gate;
- how often a scope correction after execution forced a re-run, and the minutes it cost.

The gate exists because "runs and writes are costly to undo" (testing `WORKFLOW.md:24`). Under [Approvals vs decisions](04-approvals-vs-decisions.md), no outward write happens before the end approval, so a wrong-scope run costs execution minutes, not an outward write. That cost is the figure to measure.

## Resolution

Decided with the user on 2026-10-07. **Show the plan and run.** The case list and lane plan are printed and execution starts without waiting. The plan rides in the end-of-round decisions popup from [Approvals vs decisions](04-approvals-vs-decisions.md), where the user can correct it. This removes one blocking human touch per round. The basis: the user wants fewer questions overall, and no outward write happens before the end approval, so a wrong-scope run costs only execution minutes. Those minutes count toward the cap, and the user correcting the scope in the end popup triggers a new round (inferred from [15-minute budget](10-fifteen-minute-budget.md) point 3, which the user decided for B re-test). How often scope corrections happen is unmeasured. Accepted risk (user): a wrong-scope run wastes execution time instead of being caught before it starts.
