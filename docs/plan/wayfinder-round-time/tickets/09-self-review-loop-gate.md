---
type: grilling
status: open
assignee: main-thread (session 2026-10-07 c)
blocked_by: [01, 10, 13]
---

# Self-review loop gate

## Question

Given the measured cost from the baseline, what is the minimal self-review structure that still catches what it is meant to catch? Today the reviewer subagent repeats rounds with no cap (retest 6c), the guard runs twice (draft and posted), and the pre-delivery gate opens every evidence file. Which runs are redundant with each other, and which need to stay? The answer must fit the allocation set by [15-minute budget](10-fifteen-minute-budget.md). Any part the user chooses to skip is recorded as an accepted risk.

## Framing (pre-baseline, no recommendation yet)

Prepared while [Baseline phase timing](01-baseline-phase-timing.md) and [15-minute budget](10-fifteen-minute-budget.md) are open.

**The review runs in one retest round today**

| Run | What it checks | Source |
|---|---|---|
| 6b author re-read | own draft, fresh-eyes rule when > 80 lines or > 15 rows | retest `WORKFLOW.md:770` |
| Guard on manifest (6·0) | rules enforced from data, before drafting | `WORKFLOW.md` §6·0, `:779` |
| 6c reviewer subagent | four adversarial questions; loops until `CLEAN`, **no cap**, each round reported | `WORKFLOW.md:672-693` |
| Pre-delivery 7-layer gate | opens every evidence file | `references/qa-evidence-gates.md:327`; checked at `WORKFLOW.md:764` |
| Guard on posted body (8·0) | the posted body matches the rules | `WORKFLOW.md:779` |
| Post-publish re-read | the comment renders; max 3 fix rounds | `WORKFLOW.md:766` |

**Overlap to test against the transcripts, not assume:** does the 6c reviewer find anything the guard or the 7-layer gate did not already flag? If its findings are always a subset, that is a measured case for capping it; if it finds unique gaps, it stays.

| # | Option | Kind |
|:-:|---|---|
| A | Order the runs cheapest-first (guard, then 6b, then 6c) so that 6c never reviews a draft the guard would reject | dedupe, no standard change |
| B | Cap 6c at N rounds (the bot-mode rule already does 1 round + BLOCKED rows, `WORKFLOW.md:691`), with any finding still open recorded as BLOCKED | gate change; needs a recorded decision |
| C | Skip the posted-body guard when the post is byte-identical to the guarded draft | dedupe if identity is checked fresh; the user confirms |
| D | Drop 6c | skip candidate; never recommended |

**Numbers needed:** 6c rounds per post (median/max) and minutes per round; the share of 6c findings not already raised by the guard or gate (marked unmeasured if the transcripts cannot show it); the review slice from ticket 10.
