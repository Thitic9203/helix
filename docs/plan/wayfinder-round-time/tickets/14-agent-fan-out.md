---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07)
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

## Resolution

Decided with the user on 2026-10-07.

1. **Each lane owns its whole unit.** A lane runs the cases, the Figma compare, recording during execution, and the investigation of any non-pass for its own unit. Units are grouped as in `references/parallel-test-lanes.md:41-49`, with barrier units still run alone. The main thread only merges results into one report and one end bundle. This spreads the per-step generation cost of agent-driven browsing (17.6% of retest AGENT + EXEC, [research/15-unattributed-agent-time.md](../research/15-unattributed-agent-time.md)) across lanes. It complements keeping agent-driven execution ([Scripted vs agent-driven execution](17-scripted-execution.md)).
2. **The reviewer subagent runs in parallel with building the bundle** (render check, decisions popup, approval list). It must finish CLEAN before the approval popup is shown, so the standard is unchanged. Today the main thread overlaps only 7.5 of 220 reviewer minutes in retest ([research/13-per-gate-timing.md](../research/13-per-gate-timing.md)).
3. **Lane cap: as many as possible.** Lanes = min(units, accounts leasable without collision), with no fixed cap. This replaces the default cap of 4 at `references/parallel-test-lanes.md:54` for these flows. Accepted cost (user): more live browsers, machine load, and tokens per round. The account pool is still the binding limit; per [Login reuse option](11-login-reuse-option.md), one account belongs to one lane.
4. **Fan out whenever a round has 2 or more units**, with no time prediction. This follows `references/parallel-test-lanes.md:176` ("serial-by-habit is the main cost").
