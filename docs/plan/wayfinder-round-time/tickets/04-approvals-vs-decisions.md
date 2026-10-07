---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07 b)
blocked_by: []
---

# Approvals vs decisions

## Question

Each workflow's HUMAN-WAIT points mix approvals (post, transition, assign, notify) with decisions (scope approval in retest 2b/2c and testing Phase C, Figma missing in retest 2d, the non-pass A/B challenge in retest 4i and testing E3, the cross-ticket conflict check at closing). Given the standing preference for one approval at the end, which points are approvals that fold into the final bundle? Which decisions must stay inline, and which can be answered ahead of time (workspace guide, intake defaults)? What exact shape does the final bundle take?

## Resolution

Decided with the user on 2026-10-07 (AskUserQuestion, one popup, three questions).

**Inventory of human-wait points**

| Point | Kind | Outcome |
|---|---|---|
| Retest Step 6 post comment · 8a transition · 8c assign · 8d unblock linked stories (transitions *other* tickets) · Step 9 notify · testing G3 result update | Approval (outward write) | Folds into the one end-of-round approval (standing preference). Retest already approves once at Step 6 and runs Step 8 without a second approval. |
| Retest 2b/2c case list + lane plan · testing Phase C | Decision (scope, before execution) | **Not decided here.** The gate exists because "runs and writes are costly to undo" (testing WORKFLOW:24), and the cost of a wrong-scope run is unmeasured. Moved to [Scope gate timing](12-scope-gate-timing.md), blocked by [Baseline phase timing](01-baseline-phase-timing.md). |
| Retest 4i / testing E3 non-pass A/B/C · retest 2d missing design · cross-ticket conflict check (Investigate / Close) | Decision (mid-run) | **Non-blocking.** Apply the documented unattended-mode default and queue the question for the end of the round: `references/non-pass-challenge-gate.md:134-138` (BLOCKED + remark, continue), retest 2d "Unattended / bot mode" (send the design request, hold visual points BLOCKED), `references/qa-closing-shared.md` cross-ticket step 5 (table in the report, no block). |
| Retest 1b first-time config · 8a transition names · Step 9 recipient field · testing G1/G2 destination | Pre-answerable | Answer ahead of time from project config. Where it is stored and how staleness is detected belongs to [Intake persistence](05-intake-persistence.md). |

**End-of-round shape (two stages)**

1. **Decisions popup**, only when queued decisions exist: one AskUserQuestion holding the queued questions (non-pass A/B/C per item, missing design, conflict Investigate/Close), batched by 4. The cross-ticket conflict check therefore runs **before** the approval, not after the post as retest does today.
2. Re-render the draft from the answers (BLOCKED rows become PASSED / FAILED / removed) and re-run the guard.
3. **Approval popup**: one approval for the whole bundle, listing every concrete action by name — the comment (target ticket + endpoint), each transition (ticket + from → to), each assign (ticket + person), each linked story unblocked, each notify (channel + resolved recipient), each external result update (destination + rows).

No queued decisions means step 1 is skipped and the round has a single human touch at the end.

**Accepted cost (user, 2026-10-07):** choosing **B re-test** in the decisions popup starts a second execution pass, which spends budget inside the 15-minute cap. How much budget that reserve gets is a question for [15-minute budget](10-fifteen-minute-budget.md).

**Changes this implies for the spec:** retest moves the cross-ticket conflict check ahead of Step 6 approval; retest Step 6 and Step 8/9 and testing Phase G become one bundle; the attended path of 4i/E3/2d/conflict check adopts the unattended default plus a queued question.
