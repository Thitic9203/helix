# Research: unattributed agent time

Resolves [Unattributed agent time](../tickets/15-unattributed-agent-time.md). Measured 2026-10-07 over the same 171 runs. The main thread re-ran the script and the headline numbers matched. Scripts stay outside this repo.

## Coverage

Measured AGENT + EXEC came to 92% of the baseline figure for retest, 93% for testing, and 65% for smoke, so smoke numbers are approximate.

The named gates cover 13.7% (retest), 9.9% (testing), and 4.9% (smoke) of that time.

## Where the rest goes

**Generation (the model writing between steps) is the largest share:** 61% of retest, 57% of testing, and 56% of smoke AGENT + EXEC. That is a median of 26.6, 30.8, and 11.2 min per round. Almost all of it follows a tool result; only about 2–3% follows a user message.

Top buckets outside the named gates (share of AGENT + EXEC):

| Flow | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Retest | Generation after a browser-automation result, 17.6% | Generation between parts of one turn, 10.5% | Generation after a file Read, 10.0% | Browser-automation tools running, 9.1% | Generation after other Bash, 7.9% |
| Testing | Generation between parts of one turn, 14.8% | Waiting on a background agent, 10.7% | `node` scripts running, 7.7% | Generation after a file Read, 7.3% | Generation after other Bash, 6.1% |
| Smoke | Generation between parts of one turn, 18.3% | Waiting on a background agent, 16.9% | Other Bash running, 13.6% | Generation after context-mode tools, 10.8% | Generation after other Bash, 6.8% |

## Other findings

**Long generation gaps.** Retest has 1,024 min in gaps over 10 min, across 17 rounds (14.2%). What came before them:
- a browser tool (22 gaps, 364 min);
- a Read (11 gaps, 234 min);
- other Bash (9 gaps, 133 min).

Testing has 116 min of such gaps (3%). Smoke has none.

**Repeated work is small.**
- Retest and testing repeats (re-reads, re-fetches, re-runs) cost under 1% of time.
- Smoke repeated commands cost 5%, most likely polling.

**Interrupted turns are not counted as AGENT time.** The agent noted that turns ended by a user interrupt (retest 1,251 min) would be a large share if the baseline counted them as AGENT time. The main thread checked the baseline classifier: it counts interrupts as HUMAN `reply_wait`. They are therefore not inside the AGENT + EXEC figures.

## Reading

In retest, the biggest single lever is the agent driving the browser step by step through MCP and generating after every result. That is about 27% of retest AGENT + EXEC: 17.6% generation after browser results plus 9.1% browser tools running.

Testing already leans more on scripts (`node`), but loses time to generation between parts of one turn and to waiting on background agents.

## Caveats

- Time spent waiting on a permission prompt cannot be separated from tool run time.
- "Generation between parts of one turn" may include output streaming.
- When tools run in parallel, overlapping time is attributed to whichever tool's result arrived next.
- Repeated-fetch counts are approximate.
