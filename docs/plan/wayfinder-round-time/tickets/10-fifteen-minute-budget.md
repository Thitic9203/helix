---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07 c)
blocked_by: [01]
---

# 15-minute budget

## Question

The user set a hard cap: every round finishes within 15 minutes. Given the measured baseline, how is those 15 minutes divided across phases, per flow (retest, test task, test story, smoke)?

Four points need deciding:

1. Whether human wait time counts against the cap.
2. Which steps are must-keep, and which are skip candidates. Each candidate is shown with its measured cost and what it would stop catching, and the user decides.
3. What happens when a round's scope cannot fit, for example a story with many screens: split it into several rounds, cut scope with approval, or stop and report.
4. How the workflow tracks the remaining budget while it runs.

## Framing (pre-baseline, no recommendation yet)

Prepared while [Baseline phase timing](01-baseline-phase-timing.md) runs. The allocation itself needs the measured split per flow, so no slice is proposed here and no option is marked recommended.

**Point 1: does human wait count?** The map has already answered this. Its Destination defines the cap as "measured from the start of the round to its close, including the time spent waiting on the human" (`MAP.md`, Destination). [Approvals vs decisions](04-approvals-vs-decisions.md) shrinks that wait to at most two end popups (decisions, then approval), plus the scope gate while [Scope gate timing](12-scope-gate-timing.md) is open. This point is put to the user only as a confirmation, together with the measured human-wait share from ticket 01.

**Point 2: must-keep vs skip candidates.**

| Must-keep (the evidence standard; changing any needs a recorded decision) | Source |
|---|---|
| Fresh verification of every claim this round | `references/qa-evidence-gates.md:10` |
| Pre-delivery 7-layer gate | `references/qa-evidence-gates.md:327` |
| Guard run on the manifest and the posted body (where the workspace provides it) | retest `WORKFLOW.md` §6·0, `:779` |
| Post-publish re-read of the Jira comment | `references/qa-evidence-gates.md` claim map, "Jira comment posted" |

| Skip candidate (decided in its own ticket, with measured cost) | Ticket |
|---|---|
| Figma compare on untouched screens · extra breakpoint widths | [07](07-figma-compare-gate.md) options C, D |
| Per-case MP4 evidence | [08](08-mp4-evidence-gate.md) |
| Independent reviewer loop with no round cap | [09](09-self-review-loop-gate.md) |
| Re-running unaffected cases on round N | [06](06-retest-round-n-reuse.md) |

This ticket only allocates minutes. Each skip is decided in its own ticket, so no skip is pre-decided here.

**Point 3: scope that cannot fit.** The options to put to the user:

- (a) split into several rounds, each a scoped round (`CASES: <ids>`, the mechanism retest already has);
- (b) cut scope with approval, where the cut cases are listed under `Out of scope this round`;
- (c) stop and report with the measured overrun.

Lanes are the throughput lever that comes before any of these (`references/parallel-test-lanes.md` §1–§2). Their capacity is `min(units, accounts that can be leased, lane cap)` (§2). The local account notes today list 1 Teacher and 1 Student (count only, from the operator's local secrets file), so lanes add little for single-role stories until the account pool grows.

**Point 4: tracking the remaining budget while running.** Options:

- (a) stamp the wall-clock at each phase boundary into the round's manifest (retest already writes `run.json` per round, `WORKFLOW.md` §6·0), and check it against the phase slice at each boundary;
- (b) the same stamps in the handoff file that [Intake persistence](05-intake-persistence.md) now writes every round (works for testing-ticket and smoke, which have no `run.json`);
- what happens when a slice is exceeded follows from the answer to point 3.

**Reserve.** [Approvals vs decisions](04-approvals-vs-decisions.md) recorded that a "B re-test" answer in the decisions popup starts a second execution pass inside the cap. The allocation needs a named reserve for it, sized from the measured execution time per case.

**Numbers needed before asking:** per flow, the median and max round time and its HUMAN-WAIT / AGENT-WORK / EXECUTION split; per-phase medians where labelled; cases per round; execution minutes per case.

## Resolution

Decided with the user on 2026-10-07 (one AskUserQuestion popup, four questions), using the numbers in [research/01-baseline.md](../research/01-baseline.md).

**The fact the decision rests on.** Few complete rounds (closed, with real test execution) have ever fit 15 active minutes: retest 2 of 77, testing 1 of 16, smoke 1 of 4. Runs under 15 minutes that were not complete rounds (aborted, no execution) are not used as a template.

**Answers**

1. **Human wait is excluded from the cap, and reported separately.** The 15 minutes covers AGENT + EXEC time only. Every round reports human-wait minutes on their own line. This narrows the Destination's original wording. Measured median of AGENT + EXEC per round today: retest 48.9 min, story 43.1 min, all testing 64.7 min, smoke 22.1 min (computed per run from the baseline raw data; corrected 2026-10-07, after the first version wrongly added the per-class medians).
2. **Scope too large for one round: fan out across agents so the round still finishes in 15 minutes.** The round is not split, scope is not cut, and work does not stop. How work is divided across subagents is a new ticket, [Agent fan-out for large scope](14-agent-fan-out.md).
3. **A "B re-test" chosen at the end opens a new round with its own 15 minutes.** No reserve is held inside the first round.
4. **When the round nears 15 minutes: warn, then continue to completion.** The round is not cut. The overrun minutes are recorded in the round report. This is the user's choice of a soft cap over a hard stop.

**Allocation.** The split stays at class level (AGENT vs EXEC) because the baseline has no per-gate breakdown. Hitting 15 minutes means cutting AGENT time from roughly 39 to roughly 10 minutes in retest and story. Which gates and phases give back those minutes is measured by [Per-gate timing](13-per-gate-timing.md) and decided in the Figma, MP4 and self-review gate tickets, which now wait on it.

**Accepted cost (user):**
- Under the soft cap, a round can still finish past 15 minutes; the overrun is reported rather than prevented.
- Fanning out spends more tokens per round in exchange for wall-clock time.
