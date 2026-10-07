---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07)
blocked_by: []
---

# Spec shape, rollout and re-measure

## Question

This ticket graduated from the map's "Not yet specified" section. It settles three things:

1. Is there one spec for all flows, or one spec per workflow?
2. Which flow does the spec roll out to first?
3. How is the 15-minute cap proven in real runs after rollout?

## Resolution

Decided with the user on 2026-10-07.

1. **One spec, with a section per flow:** retest, test task/story, and smoke. Decisions shared across flows are written once. This follows the Destination ("a decided spec") and [Smoke-test scope](03-smoke-test-scope.md), which gives smoke its own section that lands in `ols-qa`.
2. **Roll out to all flows at once.** Retest-first was offered as the recommended option (most runs, so the fastest measurement), and the user chose all at once instead. Accepted risk (user): if the change regresses, every flow is affected together, and the cause is harder to isolate.
3. **Re-measure in two ways.**
   - Every round report prints its AGENT + EXEC minutes, its human-wait minutes, and any overrun ([15-minute budget](10-fifteen-minute-budget.md)).
   - After 10 real rounds per flow, the baseline analysis script runs again over the new transcripts and is compared with [research/01-baseline.md](../research/01-baseline.md). The figure of 10 rounds is a proposal and can be adjusted.
