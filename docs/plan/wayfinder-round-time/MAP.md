---
labels: [wayfinder:map]
tracker: local-markdown (see README.md)
created: 2026-10-07
---

# Map: Cut per-round time for retest bug, test task, test story, and smoke test

## Destination

A decided spec of changes to `retest-bug-workflow`, `testing-ticket-workflow` (task and story), and `smoke-test-workflow` (canonical in the `ols-qa` repo; its changes land there). The spec makes **every round finish within 15 minutes** (hard cap set by the user, 2026-10-07), measured from the start of the round to its close, including the time spent waiting on the human. Every change keeps the evidence standard in `references/qa-evidence-gates.md`, or changes it through a recorded decision. Execution happens after this map, through normal PRs.

## Notes

- Domain: Helix QA workflows. The canonical procedures are `skills/deprecated/{retest-bug,testing-ticket}-workflow/WORKFLOW.md`. Smoke test's canonical source is the `ols-qa` repo (see [Smoke-test scope](tickets/03-smoke-test-scope.md)).
- "Round time" is measured wall-clock from the first message to the closing action. It includes HUMAN-WAIT, AGENT-WORK, and EXECUTION phases.
- **Standing preference (user, 2026-10-07):** measure the baseline before deciding. Every "recommended" option in a ticket must cite a measured number or a doc. Guesses are not allowed (global rules 17 and 25).
- **Standing preference (user, 2026-10-07):** outward actions (post a comment, transition, assign, notify) collapse into **one approval at the end**. That approval shows the full bundle, listing every concrete action. Mid-run *decisions* are a separate question; see [Approvals vs decisions](tickets/04-approvals-vs-decisions.md).
- **Standing preference (user, 2026-10-07):** skip anything that is not important, so that each round fits in 15 minutes. The agent does not decide what is unimportant. Each skip candidate goes to the user with its measured cost and what it would stop catching. The user decides, and each skip is recorded as an accepted risk in the resulting spec (global rule 7).
- For each gate, first look for the minimal gate that still meets the evidence standard at its measured cost. Only what still does not fit the budget after that goes to the user as a skip candidate. A skip is never marked "(recommended)".
- This repo is public. Raw transcripts and timing data stay outside it; only redacted summaries are committed.
- With no grilling or domain-modeling skill installed, HITL tickets are worked via AskUserQuestion with the user.

## Decisions so far

<!-- one line per closed ticket -->

- [Cross-run login reuse](tickets/02-cross-run-login-reuse.md): reuse across runs is safe for one operator when files are named by account and a session check runs first; reuse across sessions needs an account lease. Picking the option is a separate ticket.
- [Smoke-test scope](tickets/03-smoke-test-scope.md): in scope with the 15-minute cap; the spec has a separate smoke section, and its changes land in `ols-qa`, which counts as touching another repo.
- [Approvals vs decisions](tickets/04-approvals-vs-decisions.md): all outward writes fold into one end approval; mid-run decisions take the documented bot-mode default and queue to the end (decisions popup, then one approval popup listing every action); the scope gate waits for the baseline.

## Not yet specified

- **Playwright per-case speed and flaky reruns.** Is execution itself slow (login, waits, serial steps), or is the cost the reruns? This waits for the baseline numbers.
- **Picking the Jira post format late.** PM-1 forced a re-post with v2 wiki. The open question is whether format selection can move to intake or the workspace guide.
- **Re-measuring after rollout.** How the spec proves the 15-minute cap holds in real runs once it ships.
- **Rollout order and spec shape.** The question is whether there is one spec for all flows or one per workflow, and which flow goes first.

## Out of scope

<!-- closed tickets ruled beyond the destination -->
