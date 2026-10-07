---
labels: [wayfinder:map]
tracker: local-markdown (see README.md)
created: 2026-10-07
---

# Map: Cut per-round time for retest bug, test task, test story, and smoke test

## Destination

A decided spec of changes to `retest-bug-workflow`, `testing-ticket-workflow` (task and story), and `smoke-test-workflow` (canonical in the `ols-qa` repo; its changes land there). The spec makes **every round finish within 15 minutes of AGENT + EXEC time** (set by the user, 2026-10-07). Time spent waiting on the human is excluded and reported separately. The cap is soft: near 15 minutes the round warns, then finishes, and the overrun is reported. Every change keeps the evidence standard in `references/qa-evidence-gates.md`, or changes it through a recorded decision. Execution happens after this map, through normal PRs.

## Notes

- Domain: Helix QA workflows. The canonical procedures are `skills/deprecated/{retest-bug,testing-ticket}-workflow/WORKFLOW.md`. Smoke test's canonical source is the `ols-qa` repo (see [Smoke-test scope](tickets/03-smoke-test-scope.md)).
- "Round time" against the cap = AGENT-WORK + EXECUTION. HUMAN-WAIT is reported on its own line (see [15-minute budget](tickets/10-fifteen-minute-budget.md)).
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
- [Intake persistence](tickets/05-intake-persistence.md): project values auto-saved to the workspace guide; per-ticket state in the handoff file every round; a fresh fingerprint check per source decides what to re-read.

- [Baseline phase timing](tickets/01-baseline-phase-timing.md): median active round time is 68–78 min, and only about 1 in 6 rounds fits in 15 min. AI generation time is the biggest cost; test execution takes only 2–6 min.
- [15-minute budget](tickets/10-fifteen-minute-budget.md): the cap counts AGENT + EXEC time only and is soft (warn, then finish, report the overrun). Large scope fans out across agents. A B re-test is a new round. The AGENT target is about 10 min, against about 39 today.
- [Per-gate timing](tickets/13-per-gate-timing.md): the named gates (Figma, MP4, review, guard, read, draft, edit) are only about 13–15% of AGENT + EXEC time and cost most in the tail; about 85% is unattributed. The comment edit loop is a post-then-fix pattern.

- [Retest round-N reuse](tickets/06-retest-round-n-reuse.md): scoped round; re-run touched and previously failed cases, list the rest as out of scope, and confirm the scope in the end popup. The fresh-evidence rule is unchanged.
- [Figma compare gate](tickets/07-figma-compare-gate.md): keep the full compare (median 0.5 min); dedupe per screen × width and cache design exports by fingerprint.
- [MP4 evidence gate](tickets/08-mp4-evidence-gate.md): record during execution, with no separate capture pass; the 7 layers are unchanged.
- [Self-review loop gate](tickets/09-self-review-loop-gate.md): skip the posted-body guard when the post is byte-identical to the guarded draft. The reviewer loop is unchanged and stays about 15 min when present.
- [Unattributed agent time](tickets/15-unattributed-agent-time.md): generation is about 60% of AGENT + EXEC, and MCP browser driving is about 27% of retest, the largest lever. Repeated work is under 1%.

## Not yet specified

- **Re-measuring after rollout.** How the spec proves the 15-minute cap holds in real runs once it ships.
- **Rollout order and spec shape.** The question is whether there is one spec for all flows or one per workflow, and which flow goes first.

## Out of scope

<!-- closed tickets ruled beyond the destination -->
