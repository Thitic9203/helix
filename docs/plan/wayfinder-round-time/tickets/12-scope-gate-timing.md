---
type: grilling
status: open
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
