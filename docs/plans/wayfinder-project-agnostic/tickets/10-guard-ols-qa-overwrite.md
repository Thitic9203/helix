# How the ols-qa sync is kept from overwriting project-agnostic files

Type: `wayfinder:grilling` (HITL) · Status: open · Blocked by: 09 · Assignee: —

## Question

ols-qa's `scripts/sync-skills-to-helix.sh` (post-commit hook, `cp -f` + push to Helix main) has no skip
list. Which guard does the owner want: a skip list in the ols-qa script for files Helix now owns, a check
in Helix CI that rejects a sync commit touching those files, switching the sync to PR mode
(`HELIX_SYNC_MODE=pr`), or reversing ownership so ols-qa pulls these files from Helix? Changing ols-qa
is in scope only as this guard (owner, 2026-11-18); ols-qa skills themselves stay untouched.
