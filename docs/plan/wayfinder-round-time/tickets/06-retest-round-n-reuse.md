---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07 c)
blocked_by: [01, 05]
---

# Retest round-N reuse

## Question

When a bug comes back for round N, what from round N-1 may be reused (case list, unaffected-case evidence, Figma refs), and what must run fresh? This must be reconciled with the "fresh in this session" rule (`references/qa-evidence-gates.md:10`) and the pre-delivery re-count. Does that rule change, and if so, how, through a recorded decision?

## Framing (pre-baseline, no recommendation yet)

Prepared while [Baseline phase timing](01-baseline-phase-timing.md) runs. No option below is marked recommended: the map requires a measured number or a doc behind every recommendation, and the cost of each fresh step is what ticket 01 measures.

**What exists today**

- `references/qa-evidence-gates.md:10` — every claim's check is run "fresh in this session (not an earlier turn)"; the claim map lists "prior run" as **not sufficient** for a pass.
- Pre-delivery gate (`references/qa-evidence-gates.md:327`, checked at `skills/procedures/retest-bug-workflow/WORKFLOW.md:764`) — scope is "re-counted from the bug **this round**".
- Scoped rounds already exist (`WORKFLOW.md:472`, `:488`, `:502`, `:611`): a round may re-run only named cases, print `*Scope:* CASES: <ids>`, a `PASSED (scoped: …)` verdict, and an `Out of scope this round:` line naming every case left unverified.
- [Intake persistence](05-intake-persistence.md) (closed) stores the case list, AC/EC list, Figma node refs, Swagger version, last-round results and one fingerprint per source in the handoff file every round, and re-reads a source only when its fingerprint changed. Whether last-round **results** may be reused was left to this ticket.

**Questions for the user, one per reuse candidate**

| # | Item from round N-1 | Options to put to the user | Conflict with the evidence standard |
|:-:|---|---|---|
| 1 | Case list | (a) rebuild from the bug every round · (b) reuse the stored list when the bug fingerprint (`updated` + comment count) is unchanged, re-count it against the bug fresh | (b) must still satisfy "scope re-counted this round"; a fresh fingerprint is not a re-count, so the re-count step stays |
| 2 | Evidence of cases the fix did not touch | (a) re-run every case fresh (today's full round) · (b) scoped round: re-run fixed + previously failed cases, list the rest under `Out of scope this round` (already allowed) · (c) carry PASSED evidence forward with its round stamp | (c) contradicts `qa-evidence-gates.md:10` and the "prior run" row; it needs a recorded decision changing the gate. (a) and (b) need no gate change |
| 3 | Figma node refs | reuse when the Figma `lastModified` fingerprint is unchanged (already decided in 05) · the screen comparison itself is always captured fresh | none — refs are inputs, not evidence |
| 4 | Who decides the scope of round N | (a) agent proposes scope from the fix description, user confirms in the end decisions popup ([Approvals vs decisions](04-approvals-vs-decisions.md)) · (b) always full round | (a) adds one decision to the end popup, not a mid-run wait |

**Numbers needed from ticket 01 before asking:** median and max minutes of a retest round split by EXECUTION per case (Playwright + MP4 capture + upload) vs AGENT-WORK, and the number of cases per round. These decide whether option 2(b) alone fits the 15-minute cap, or whether 2(c) has to be put to the user as a skip candidate with its measured saving and what it would stop catching.

## Resolution

Decided with the user on 2026-10-07. **Scoped round.** Round N re-runs only the cases the fix touches plus every previously failed case. The rest are listed under `Out of scope this round`, which is the existing mechanism at retest `WORKFLOW.md:472`. The agent proposes the scope from the fix description, and the user confirms it in the end-of-round decisions popup ([Approvals vs decisions](04-approvals-vs-decisions.md)), so this adds no mid-run wait. Carrying PASSED evidence forward from round N-1 was not chosen. `references/qa-evidence-gates.md:10` (fresh in this session) stays unchanged. The case list is still re-counted against the bug fresh every round, and Figma refs are reused through the fingerprint decided in [Intake persistence](05-intake-persistence.md).
