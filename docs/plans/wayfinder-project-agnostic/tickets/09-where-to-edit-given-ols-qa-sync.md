# Where to make the edits, given ols-qa overwrites Helix

Type: `wayfinder:grilling` (HITL) · Status: closed · Blocked by: 01 · Assignee: Claude (main thread)

## Question

Ticket 01 shows ols-qa's post-commit sync can `cp -f` over Helix's test-data-prep files. Does the owner
still fix at Helix only (and stop/skip-list the ols-qa sync for these files), edit ols-qa first and let
it flow to Helix (existing practice per `docs/sdd/token-diet/spec.md:20`), or edit both in step?

## Resolution (2026-11-18, owner via next-step button)

Owner chose **"แก้ Helix + กันทับ"**: Helix stays the place where the project-agnostic edits are made,
and the ols-qa → Helix sync must be prevented from overwriting those files. How to prevent it is
graduated to [How the ols-qa sync is kept from overwriting project-agnostic files](10-guard-ols-qa-overwrite.md).
