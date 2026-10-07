# Spec: Cut per-round time for retest bug, test task/story, and smoke test

This spec is the Destination of [MAP.md](MAP.md). Every line below traces to a closed ticket, and the ticket holds the rationale and evidence. No decision is restated here with different meaning. If this file and a ticket disagree, the ticket wins.

- **Status:** decided 2026-10-07, not yet implemented.
- **Rollout:** all flows at once ([Spec shape, rollout and re-measure](tickets/18-spec-shape-rollout.md)).
- **Where changes land:** `skills/deprecated/{retest-bug,testing-ticket}-workflow/WORKFLOW.md` plus the `references/` files named below in this repo; smoke test changes land in the `ols-qa` repo.

## 1. Target

| Item | Decision | Ticket |
|---|---|---|
| Cap | 15 minutes of **AGENT + EXEC** time per round | [15-minute budget](tickets/10-fifteen-minute-budget.md) |
| Human wait | Excluded from the cap; reported on its own line every round | same |
| Nearing 15 min | Warn, then finish the round; report the overrun minutes (soft cap) | same |
| "B re-test" chosen at the end | Opens a new round with its own 15 minutes | same |
| Large scope | Fan out across agents (section 3) | same, [Agent fan-out](tickets/14-agent-fan-out.md) |

**Baseline**, AGENT + EXEC median per round ([research/01-baseline.md](research/01-baseline.md)):

| Flow | Median per round | Complete rounds already within 15 min |
|---|---|---|
| Retest | 48.9 min | 2 / 77 |
| Story | 43.1 min (all testing: 64.7) | 1 / 16 (all testing) |
| Smoke | 22.1 min | 1 / 4 |

**Honest outlook.** No measured run proves these changes reach 15 minutes. The largest measured lever, scripted execution (about 27% of retest), was declined ([Scripted vs agent-driven execution](tickets/17-scripted-execution.md)). The route therefore rests on four things:

- fan-out (section 3);
- removing human-blocking gates (section 2);
- the dedupes (section 4);
- the comment render check (section 5).

Re-measurement (section 7) decides whether the cap holds.

## 2. Human touchpoints (all flows)

| Change | Ticket |
|---|---|
| Outward writes (comment, transition, assign, unblock linked stories, notify, result update) fold into **one approval popup at the end**, listing every concrete action by name | [Approvals vs decisions](tickets/04-approvals-vs-decisions.md) |
| Mid-run decisions (non-pass A/B/C, missing design, cross-ticket conflict) take the documented unattended-mode default, and the question is queued to an **end decisions popup** shown before the approval popup | same |
| Retest cross-ticket conflict check moves **ahead of** the Step 6 approval | same |
| Scope gate (retest 2b/2c, testing Phase C): **show the plan and run**; the plan rides in the end decisions popup | [Scope gate timing](tickets/12-scope-gate-timing.md) |
| Per-project values (env, accounts, Jira format, transition names, notify field, results destination) are **saved to the workspace guide automatically** after the first ask | [Intake persistence](tickets/05-intake-persistence.md) |

**End-of-round sequence:**

1. The reviewer finishes CLEAN, running in parallel with the next two steps.
2. The render and media check passes.
3. The decisions popup appears, only if decisions are queued.
4. The draft is re-rendered and the guard re-run.
5. One approval popup is shown.
6. Post, then re-read the posted comment.

## 3. Execution and fan-out (all flows)

| Change | Ticket |
|---|---|
| Fan out whenever a round has **2 or more units**; units as in `references/parallel-test-lanes.md:41-49`; barrier units still run alone | [Agent fan-out](tickets/14-agent-fan-out.md) |
| **Each lane owns its unit end to end:** cases, Figma compare, recording, and investigation of any non-pass. The main thread only merges into one report and one bundle | same |
| Lane count = min(units, accounts leasable without collision). **No fixed cap**; this replaces the default 4 at `parallel-test-lanes.md:54` | same |
| Execution stays **agent-driven** (MCP browser steps), not a scripted Playwright run | [Scripted vs agent-driven execution](tickets/17-scripted-execution.md) |
| **Login reuse per operator.** The file is `{auth dir from guide}/{env}-{role}-{alias}.json` (replacing lane-named `storageState-{Lx}.json`) and gitignored. The session endpoint must confirm the expected user before any result counts; otherwise the run logs in fresh and overwrites the file. No account is shared across concurrent sessions | [Login reuse option](tickets/11-login-reuse-option.md) |

## 4. Evidence gates (standard unchanged unless stated)

| Gate | Change | Ticket |
|---|---|---|
| Figma compare | Keep the full compare. One compare per screen × width per round, and cache the design-side export keyed by Figma `lastModified` | [Figma compare gate](tickets/07-figma-compare-gate.md) |
| MP4 | **Record during execution**, with no separate capture pass. The 7 layers and full re-capture on a red layer (`qa-evidence-gates.md:147`) are unchanged | [MP4 evidence gate](tickets/08-mp4-evidence-gate.md) |
| Posted-body guard | Skip it when the posted body is byte-identical to the guarded draft; the identity check runs fresh | [Self-review loop gate](tickets/09-self-review-loop-gate.md) |
| Reviewer 6c | Loop unchanged (no cap). It runs in parallel with building the bundle and must be CLEAN before approval | [Self-review loop gate](tickets/09-self-review-loop-gate.md), [Agent fan-out](tickets/14-agent-fan-out.md) |
| Fresh evidence (`qa-evidence-gates.md:10`) | Unchanged | [Retest round-N reuse](tickets/06-retest-round-n-reuse.md) |

## 5. Posting

The comment render check is decided in [Comment render check](tickets/16-comment-render-check.md). Before the approval popup, two checks run on the final body:

- render the ADF or wiki body locally, and confirm tables and formatting;
- confirm every referenced image or clip resolves.

The post-publish re-read stays as the proof that the comment was posted.

## 6. Per flow

### Retest bug

- **Round N is a scoped round.** It re-runs the cases the fix touches plus every previously failed case. All other cases go under `Out of scope this round` (`WORKFLOW.md:472`). The agent proposes the scope, and the user confirms it in the end decisions popup. See [Retest round-N reuse](tickets/06-retest-round-n-reuse.md).
- **Per-ticket state** lives in `references/helix-handoff-{KEY}.md`, written every round.
- **Fingerprints are checked fresh each round:** ticket `updated` plus comment count, Figma `lastModified`, Swagger hash, and build version. A full re-read happens only for a source whose fingerprint changed. See [Intake persistence](tickets/05-intake-persistence.md).
- Sections 2–5 apply in full.

### Test task / story

- **Phase C becomes "show the plan and run".** Phase G result updates join the end approval bundle.
- **Story human wait has a median of 18.4 min.** It is excluded from the cap, but removing the Phase C block and the mid-run waits is what shortens it.
- Sections 2–5 apply in full.

### Smoke test (lands in `ols-qa`)

- **The same cap and the same end-of-round shape apply.** See [Smoke-test scope](tickets/03-smoke-test-scope.md).
- **The baseline is approximate** (8 runs). The measured guard share is 2.9%. The largest buckets are generation between parts of one turn and waiting on background agents.
- **The PR must answer "touches another repo" = YES.**

## 7. Re-measure

- Every round report prints AGENT + EXEC minutes, human-wait minutes, and any overrun.
- After **10 real rounds per flow**, re-run the baseline analysis script on the new transcripts and compare with [research/01-baseline.md](research/01-baseline.md). The figure of 10 is a proposal and can be adjusted. See [Spec shape, rollout and re-measure](tickets/18-spec-shape-rollout.md).

## 8. Accepted risks and costs (user-chosen)

| Risk / cost | Ticket |
|---|---|
| The soft cap means a round can still finish past 15 minutes; the overrun is reported, not prevented | [15-minute budget](tickets/10-fifteen-minute-budget.md) |
| More tokens per round from fan-out; more live browsers and machine load with no lane cap | [15-minute budget](tickets/10-fifteen-minute-budget.md), [Agent fan-out](tickets/14-agent-fan-out.md) |
| A login file stays on the operator's disk between runs | [Login reuse option](tickets/11-login-reuse-option.md) |
| A wrong-scope run wastes execution minutes instead of being caught before it starts | [Scope gate timing](tickets/12-scope-gate-timing.md) |
| The handoff file may be committed with ticket content in the user's workspace | [Intake persistence](tickets/05-intake-persistence.md) |
| A "B re-test" answer at the end opens another round | [Approvals vs decisions](tickets/04-approvals-vs-decisions.md) |
| The ~27% retest lever (scripted execution) is not taken | [Scripted vs agent-driven execution](tickets/17-scripted-execution.md) |
| All flows roll out at once, so a regression hits every flow together | [Spec shape, rollout and re-measure](tickets/18-spec-shape-rollout.md) |

## 9. Ship questions (global rule 3)

- **New cost?** No new paid service or infrastructure. Token use per round rises with fan-out (user-accepted). If tokens are billed per use to the organisation, confirm that before rollout.
- **Touches another repo?** **YES**, `ols-qa`, for the smoke test section only.
