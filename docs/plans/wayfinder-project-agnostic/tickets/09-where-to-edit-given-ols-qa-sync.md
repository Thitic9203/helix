# Where to make the edits, given ols-qa overwrites Helix

Type: `wayfinder:grilling` (HITL) · Status: open · Blocked by: 01 · Assignee: —

## Question

Ticket 01 shows ols-qa's post-commit sync can `cp -f` over Helix's test-data-prep files. Does the owner
still fix at Helix only (and stop/skip-list the ols-qa sync for these files), edit ols-qa first and let
it flow to Helix (existing practice per `docs/sdd/token-diet/spec.md:20`), or edit both in step?
