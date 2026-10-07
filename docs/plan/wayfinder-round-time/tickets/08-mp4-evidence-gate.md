---
type: grilling
status: open
assignee: main-thread (session 2026-10-07 c)
blocked_by: [01, 10, 13]
---

# MP4 evidence gate

## Question

Given the measured cost from the baseline, what is the minimal MP4 evidence policy that still meets the evidence standard? Today the workflow records one MP4 per case per role and re-captures in full when any layer fails (`qa-evidence-gates.md:147`). Options to weigh include capture during execution rather than as a separate pass, partial re-capture, and which cases need video versus screenshots. The answer must fit the allocation set by [15-minute budget](10-fifteen-minute-budget.md). Any part the user chooses to skip is recorded as an accepted risk.

## Framing (pre-baseline, no recommendation yet)

Prepared while [Baseline phase timing](01-baseline-phase-timing.md) and [15-minute budget](10-fifteen-minute-budget.md) are open.

**Today:** retest needs a whole-flow MP4 per case, per role, plus one screenshot per Expected Result on text-verification cases (`references/qa-evidence-gates.md`, evidence rule table). Each clip passes 7 layers (`:140-147`). A red layer on any case means that case is re-captured and all 7 layers are re-run (`:147`). Clips come from the existing compliant recorder (capture spec, `:149`).

| # | Option | Saves | Evidence standard | Kind |
|:-:|---|---|---|---|
| A | **Record during execution:** the Playwright run that executes the case is the recording; no separate capture pass | one full re-drive of every case | unchanged if the run-time clip passes the same 7 layers | dedupe |
| B | **Partial re-capture:** a red layer re-captures only the failing case and role and re-checks only the layers its fix can affect (layers 6–7 always) | re-runs of green layers and green cases | needs a recorded decision: `:147` says "re-run the 7 layers" | gate change; the user decides |
| C | **Screenshots instead of video** for single-state cases (one ER, no flow) | encode and upload per such case | **reduced**: layers 2–3 (whole flow, reaches target) lose their proof | skip candidate; never recommended |
| D | **Video only on the cases the fix touches**, screenshots elsewhere | as C, wider | reduced as C | skip candidate; never recommended |

**Numbers needed:** per-case EXECUTION split into Playwright, MP4 capture/encode and upload (requested from ticket 01); how often a layer failed and forced a re-capture; the MP4 slice from ticket 10.
