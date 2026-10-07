# Research: baseline phase timing

Resolves [Baseline phase timing](../tickets/01-baseline-phase-timing.md). Measured 2026-10-07 from local Claude Code session transcripts. Raw per-run data and the analysis script stay outside this public repo; only aggregates appear here.

## Method

- **Finding runs:** 171 runs, found by the skill invocations of retest-bug, testing-ticket, and smoke-test.
- **Classification:** every gap between consecutive messages gets one of these classes:
  - **AGENT model_generation:** time until each assistant message, meaning the AI reading, thinking, or writing.
  - **HUMAN reply_wait:** from the agent's turn ending to the user's next message, plus AskUserQuestion and permission waits.
  - **EXEC:** tool time for Playwright, API calls, login, MP4 capture, and Jira posting.
  - **IDLE:** any gap over 2 hours, counted separately.
- **"Active" time** = total time minus IDLE.
- **Task versus story** comes from the primary ticket's issue type. 23 testing runs have no detectable type ("testing, type unknown"), and only one task run was found.

## Results (minutes)

| Flow | Runs (closed) | Active median | Active max | HUMAN median | AGENT median | EXEC median | Runs ≤15 min active |
|---|---|---|---|---|---|---|---|
| Retest bug | 110 (81) | 68 | 713 | 7.3 | 39.2 | 5.5 | 18 / 110 |
| Test story | 27 (8) | 78 | 348 | 18.4 | 37.4 | 2.4 | 5 / 27 |
| Testing, type unknown | 23 (11) | 111 | 426 | 17.3 | 78.0 | 5.0 | 3 / 23 |
| Test task | 1 (0) | 150 | 150 | 47.0 | 90.3 | 13.0 | 0 / 1 |
| Smoke test | 8 (4) | 78 | 396 | 15.2 | 17.7 | 5.4 | 1 / 8 |

**Top sinks**, as a share of all recorded time including idle:

| Flow | 1st | 2nd | 3rd |
|---|---|---|---|
| Retest bug | AI generation, 25% (median 31 min) | Human reply wait, 11% (median 3 min) | Hooks, 4% |
| Test story | AI generation, 27% (median 30 min) | Human reply wait, 21% (median 17 min) | Local tools, 6% |
| Smoke test | Human reply wait, 24% (median 6 min) | AI generation, 20% (median 15 min) | Hooks, 7% |

**Other signals:**
- Retest runs edited posted comments 84 times across 110 runs, which shows a re-post/edit loop.
- In retest, single AI turns longer than 10 minutes total 1,174 minutes.
- Human touchpoints per round (median): retest 3, story 3, smoke 8.5.

## Reading

- The biggest active cost in every flow is **AI generation time**: reading, drafting, review loops, and gates. Test execution itself (EXEC) has a median of only 2–6 minutes.
- **Human wait** is second, and is largest in story and smoke runs.
- So a 15-minute round depends mainly on cutting agent work and human touchpoints. Faster Playwright would not get there on its own.

## Caveats

- The phase classification is heuristic. The main thread checked the gap rules in the analysis script but did not audit each run individually.
- `model_generation` includes time an agent spends waiting on its own subagents' output when that wait is not tagged as a background tool.
- The task versus story split is weak: 1 task run and 23 runs of unknown type.
- Unclosed runs (abandoned or continued in another session) are included in the medians.
- No per-gate breakdown exists for the Figma compare, MP4 capture, or self-review loops; they fall inside AGENT and EXEC. If those gate tickets need exact costs, they will need a finer-grained measurement.
