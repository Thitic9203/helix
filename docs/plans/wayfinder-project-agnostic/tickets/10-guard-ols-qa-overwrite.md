# How the ols-qa sync is kept from overwriting project-agnostic files

Type: `wayfinder:grilling` (HITL) · Status: closed · Blocked by: 09 · Assignee: Claude (main thread)

## Question

ols-qa's `scripts/sync-skills-to-helix.sh` (post-commit hook, `cp -f` + push to Helix main) has no skip
list. Which guard does the owner want: a skip list in the ols-qa script for files Helix now owns, a check
in Helix CI that rejects a sync commit touching those files, switching the sync to PR mode
(`HELIX_SYNC_MODE=pr`), or reversing ownership so ols-qa pulls these files from Helix? Changing ols-qa
is in scope only as this guard (owner, 2026-11-18); ols-qa skills themselves stay untouched.

## Resolution (2026-11-18, owner via AskUserQuestion)

**Ownership list kept in Helix; the ols-qa sync script skips every file on it.**

Facts that shaped the choice (verified 2026-11-18):
- Helix `main` has no branch protection (`gh api repos/Thitic9203/helix/branches/main/protection` →
  "Branch not protected"), and the sync pushes straight to main (`sync-skills-to-helix.sh:257`), so a
  Helix CI check could only report an overwrite after it landed, never stop it.
- The script already reads the Helix checkout and refuses to run without a Helix-side guard
  (`sync-skills-to-helix.sh:56-57`), so a list stored in Helix is a natural single source.
- Matches the "helix wins" rule for files present in both repos (team-pluton-skills map helix-sync,
  ticket 04).

Rejected: CI alert only (cannot prevent), PR mode (relies on a human catching every overwrite and slows
all other skills), reversing the sync direction (largest change to ols-qa tooling).

For the SDD (ticket 07): the list's file name/format, which files go on it (at least test-data-prep's
`SKILL.md`, `WORKFLOW.md`, `commands/test-data-prep.md`, plus every file the agnostic change touches), the
script change in ols-qa (skip + report skipped files), and a test that a sync touching a listed file
leaves Helix unchanged.
