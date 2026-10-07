---
labels: [wayfinder:map]
tracker: local-markdown (see README.md)
created: 2026-10-07
---

# Map: Cut per-round time for retest bug, test task, test story, and smoke test

## Destination

A decided spec of changes to `retest-bug-workflow`, `testing-ticket-workflow` (task and story), and `smoke-test-workflow` (pending its scope ticket). The spec cuts wall-clock time from the start of a round to its close, including the time spent waiting on the human. Every change keeps the evidence standard in `references/qa-evidence-gates.md`, or changes it through a recorded decision. Execution happens after this map, through normal PRs.

## Notes

- Domain: Helix QA workflows. The canonical procedures are `skills/deprecated/{retest-bug,testing-ticket}-workflow/WORKFLOW.md`. Smoke test lives outside this repo (see [Smoke-test scope](tickets/03-smoke-test-scope.md)).
- "Round time" is measured wall-clock from the first message to the closing action. It includes HUMAN-WAIT, AGENT-WORK, and EXECUTION phases.
- **Standing preference (user, 2026-10-07):** measure the baseline before deciding. Every "recommended" option in a ticket must cite a measured number or a doc. Guesses are not allowed (global rules 17 and 25).
- **Standing preference (user, 2026-10-07):** outward actions (post a comment, transition, assign, notify) collapse into **one approval at the end**. That approval shows the full bundle, listing every concrete action. Mid-run *decisions* are a separate question; see [Approvals vs decisions](tickets/04-approvals-vs-decisions.md).
- Never frame a gate change as "skip it to go faster". Frame it as "the minimal gate that still meets the evidence standard, given measured cost".
- This repo is public. Raw transcripts and timing data stay outside it; only redacted summaries are committed.
- With no grilling or domain-modeling skill installed, HITL tickets are worked via AskUserQuestion with the user.

## Decisions so far

<!-- one line per closed ticket -->

## Not yet specified

- **Playwright per-case speed and flaky reruns.** Is execution itself slow (login, waits, serial steps), or is the cost the reruns? This waits for the baseline numbers.
- **Picking the Jira post format late.** PM-1 forced a re-post with v2 wiki. The open question is whether format selection can move to intake or the workspace guide.
- **Success metric.** The target reduction per flow, and how the spec will be re-measured after rollout.
- **Rollout order and spec shape.** The question is whether there is one spec for all flows or one per workflow, and which flow goes first.

## Out of scope

<!-- closed tickets ruled beyond the destination -->
