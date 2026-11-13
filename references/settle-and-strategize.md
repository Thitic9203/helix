# Settle and strategize (before any test action)

Do this right after the session-start context skills, **before** any other tool call — before intake,
login, or reading the ticket. It prevents the two failure modes that waste the most time: guessing, and blind loops.

## 1. Plan the approach with `engineering:testing-strategy`

Invoke the **`engineering:testing-strategy`** skill first and let it shape the run — what to test, in
what order, what "done" looks like, where the risk is. Announce it once:
`Using **engineering:testing-strategy** to plan the test approach.` Then carry that plan into the
workflow's own phases; do not improvise a test order that the strategy did not cover.

## 2. Settle — one deliberate pass before acting

State to yourself (and in chat when the run is non-trivial): the target, the environment + account in
scope, the scenarios in scope, and the single next action.

## 3. Never guess — verify the expected side against an authoritative source

An expected value you **assumed** is not a spec. The app differing from a guess is **not a defect**.
Before writing FAILED / PWMI / BLOCKED or filing a bug, read the authoritative source (Figma / PRD /
AC / PO / the ticket's own Expected Result) **character-exact**, both sides. A transliteration, an
English feature name, or an unconfirmed-spec hedge ("confirm with PO") is a **question, not a bug** →
BLOCKED + ask, never a verdict.

## 4. No blind loops — a repeat failure is a signal to stop and diagnose

If the **same** action fails the **same** way twice (a tool error, a login churn, an empty result),
**stop**. Do not retry a third time hoping it changes. Switch to root-cause mode
(`superpowers:systematic-debugging`, Phases 1–3), find why, then act once on the fix. Reproducing a
product FAILED to the result gate's layer-16 count (3 of 3) is not a retry. Retrying an unchanged call
or re-deriving a settled fact or decision are loops — break them by naming the actual blocker, not by trying harder.
