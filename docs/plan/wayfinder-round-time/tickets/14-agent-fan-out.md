---
type: grilling
status: open
assignee:
blocked_by: [13]
---

# Agent fan-out for large scope

## Question

When a round is too large to finish in 15 minutes of AGENT + EXEC time, how is the work fanned out across subagents? The questions to settle:

- which phases split (reading, Figma compare per screen, execution lanes, evidence, drafting);
- what the unit of a split is (a screen, a case, or a role);
- the maximum number of agents;
- how results merge into one report and one end bundle;
- how the existing parallel test lanes and account lease (`references/parallel-test-lanes.md`) extend to agent work.

The choice has to be weighed against the measured per-phase cost from [Per-gate timing](13-per-gate-timing.md), and against token cost.
