# Create bug — Phase B3

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase B3; every rule here is a full gate.

## 🔴 GATE: Phase B3 — Falsification (before create) [high freedom]

Runs after Phase B2 for every candidate that cleared it. **🔴 GATE:** no candidate reaches Phase C until it survives falsification.

For each bug, run every check below once and record its result (the board-conflict search is Phase B2 —
do not skip it just because a bug "looks obvious"). A check counts as already done only when a
testing-ticket run **in this same chat** recorded, for this exact defect, the evidence that check asks
for (design source text, roles/accounts seen, occurrence count) — cite that record in the Record
column. Anything else (a summary, memory, a run in another chat, "I tested it earlier") does not count:
run the check.

| Check | How | Record |
|-------|-----|--------|
| Intentional design? | Open the design frame / AC / PRD line the expected side cites (Refusal-first) and compare char-exact with the evidence | Source link + the matching or differing text |
| Role-only or data-only? | From the reporter's evidence, note which roles / accounts / entry points showed it; if only one, ask the reporter whether another was tried (never reproduce it yourself with new steps) | Roles/accounts seen, and the reporter's answer |
| Flake? | Check the evidence for more than one occurrence (two screenshots, a repeated error, the reporter's "every time"); if a single occurrence, ask the reporter how often it happens | Occurrence count + evidence refs |

Then give each candidate one label, written on its draft summary line:

- **Confirmed** — every check passed with evidence → goes to Phase C.
- **Likely** — a defined status here, not a cause hedge (the hedge ban in root-cause-investigation.md covers cause sentences) — checks passed but one rests on the reporter's word only, or a question only the reporter
  can answer is still open (another role tried? how often?) and nothing in the evidence argues against
  the defect → goes to Phase C marked **Likely**, with that open question on its Likely line; filed only
  if the user approves it as Likely there.
- **Needs Review** — a check failed, or the evidence argues against the defect (design source matches
  the app, the reporter's own evidence contradicts the report) → **drafted and shown, never filed**
  (never a hedged expected side, which stops at Refusal-first). Draft its body like any other and show it
  under the Phase C confirm block labelled **Needs Review — not filed**, with its open question on the
  `Needs Review:` line; it is not counted in Bug count and `confirm` does not create it. It is filed only
  after the user answers the question and it is re-checked here as Confirmed or Likely, and the confirm
  block is shown again.
- **Dropped** — the check proves it is not a defect (e.g. the design shows the current behavior) →
  report it in chat with the source link, as for a Phase B2 conflict.

Two observations that contradict each other (one shows the defect, one does not) → never re-run it
yourself: ask the reporter for one clean re-run of that surface, or hand it to testing-ticket-workflow;
the candidate stays **Needs Review** until the answer comes. Same for re-runs that non-pass-challenge-gate.md §3 and defect-report-completeness.md §3a/§3b ask for.

**Go back:** If the disproof attempt finds the item already settled in another ticket, return to Phase B2 — Board-conflict re-check for that candidate. When the user answers a Needs Review question, return to the top of this phase for that candidate. Confirmed and Likely candidates move to Phase C.

### Result-quality-gate layer map (filing)

[result-quality-gate.md](../../../references/result-quality-gate.md) is written for test rounds. Filing runs no
case and writes no `results.jsonl`, so `check.js` is not run; apply these rows by hand, at the step named,
before any label, BLOCKED line or `Verdict:` leaves the run.

| Layer | When filing |
|-------|-------------|
| 1–5, 8–10, 12, 19 | n/a: no case, environment, account, fixture, clip, PASSED row or result line; reproducing goes to testing-ticket (all 20 layers) |
| 6, 7 | Refusal-first: char-exact source; hedged or contradictory → `BLOCKED: spec unconfirmed` |
| 11, 13 | Reporter's evidence and What happens (none → `BLOCKED (no evidence)`); a cause sentence carries its label |
| 14 | B2 tickets + Intentional-design check; product code and regression results when the workspace holds them, else named as not read |
| 15 | [non-pass-challenge-gate.md](../../../references/non-pass-challenge-gate.md) per candidate, before its label |
| 16 | Flake check; one occurrence → never Confirmed |
| 17 | Matrix cell, verified quote, evidence; filed only after Phase C **confirm** |
| 18 | Each BLOCKED names what is missing and who supplies it |
| 20 | Phase F re-fetch before the `Verdict:` line |
