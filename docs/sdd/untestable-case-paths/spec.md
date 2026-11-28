# Spec — untestable-looking cases: testing skills find the honest way to test them

## Problem

Owner order (28/Nov/2026): "อัปเดตสกิลการทดสอบให้รู้จักการหนทางเพื่อทดสอบได้แบบนี้มาด้วย อัปเดตสกิลใน helix นะ". A rerun of
80 stale automated cases left 38 blocked and 32 failed. Tracing every one showed that most "cannot be tested" cases could be
tested: the cause was a test-side locator, data the test could create, an account nobody searched for, a device step with a
provider sandbox, or a ticket-vs-app conflict that later tickets already decided. The Helix testing skills had the general
no-wait rules (no-wait-decision-gate layers 13–16) but no concrete paths for these situations.

## Rules

- **R1.** When a case is skipped, BLOCKED or not PASSED because it looks untestable, the testing skills must classify it with one
  cause (test / data / env / spec-question / app-differs / by-design) from the test code, app code and every ticket + comment,
  never from the error line alone.
- **R2.** When a ticket and the app disagree, the skill must decide from later sources (later Done ticket, PO/QA retest comments,
  the commit that made the behaviour, breakpoint design frames); with no later source it must assert the ticket line verbatim and
  send a FAIL through the project's bug gate, never park it for the PO.
- **R3.** For an external device or scan step the skill must use the provider's sandbox that keeps the real server exchange,
  probe environments' callbacks, never mock identity data, label the simulated hop, and switch environment only with the owner's OK.
- **R4.** Before "no account fits" the skill must search the project's account sheet and the app's admin user list by the needed
  attributes; a new account is made only through a real product path and with the owner's OK.
- **R5.** Missing data must be created in the test through the real API/UI on QA-owned items and cleaned up through allowed
  transitions; a shared item is never edited to make a state.
- **R6.** Responsive failures must be located by the visible control (hidden duplicates, cards vs table, more-menu / drawer /
  filter sheet, folded rows, tap-to-show controls, mobile user agent).
- **R7.** An environment-broken run must be rerun only for the broken projects, whole, at the same commit, recorded; never a retry to green.
- **R8.** By-design skips must be recorded with their written source and reported apart from real blocked cases.
- **R9.** The guidance must be portable (no project names, hosts, accounts) and must not raise any skill's mandatory-read tokens
  (token-budget-guard): it lives in one reference read only when it applies.

Sources: the owner order above; the rerun analysis of 28/Nov/2026 (consuming project's plan, sections "W1 result" and "W1 follow-up").

## Edge cases

- A hedged or self-contradicting spec with no later decision stays under no-wait-decision-gate layer 17 (R2 does not replace it).
- Retest keeps its own supersession rules (bug ER first); R2's verbatim-assert path is linked from testing-ticket E3 only.
- test-data-prep is not linked: its WORKFLOW.md is a mandatory read with zero budget slack (R9), and it is user-requested data
  prep with its own intake; in-test data creation belongs to test runs.

## Done when

- `references/untestable-case-paths.md` covers R1–R8 with a MUST / NEVER table.
- testing-ticket E2 + E3, retest 4h, no-wait-decision-gate section C and the reference index link it conditionally.
- `bash scripts/helix-regression-check.sh`, `bash scripts/tests/run.sh` and `bash scripts/ci-token-budget.sh pr origin/main` pass.
