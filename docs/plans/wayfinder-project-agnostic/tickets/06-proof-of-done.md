# What proof ends this map

Type: `wayfinder:grilling` (HITL) · Status: closed · Blocked by: 02 · Assignee: Claude (main thread)

## Question

What evidence shows the destination is reached: a CI gate with zero project-specific hits, a dry run of
`test-data-prep-workflow` with Pyrite's recipe, OLS still producing the same result, the change visible
in team-pluton-skills after `helix-sync.yml` — which of these, and measured how?

## Resolution (2026-11-18, Claude default; owner can override at plan approval)

The map ends when all of these are shown with real output:
1. Extended portable gate (ticket 03) runs in `.github/workflows/version.yml` and reports **0 hits** on
   Helix `main` outside the template allowlist.
2. `scripts/tests/guards.test.sh` gains passing cases: a fixture with a project token fails the gate; an
   ols-qa sync of an owned file leaves Helix unchanged (ticket 10).
3. Dry run of test-data-prep **Gate 0 intake** in a non-OLS workspace: the Pyrite recipe is discovered by
   the new glob, or the missing values are asked once and saved. Intake only, no data is created.
4. OLS regression: in an OLS workspace the OLS recipe is still reached through the guide and Gate 0
   shows the same intake fields as before.
5. The release reaches SkillLane/team-pluton-skills via `helix-sync.yml` and its generated README row for
   `/eng-qa-test-data-prep` no longer says "(OLS)".
