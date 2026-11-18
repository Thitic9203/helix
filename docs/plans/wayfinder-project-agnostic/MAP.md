# Map: Helix skills work in any project, not only OLS

Label: `wayfinder:map` · Tracker: local markdown (tickets in [tickets/](tickets/)) · Charted 2026-11-18

## Destination

Every Helix skill (the 12 shared QA skills, their `skills/procedures/`, `references/` and `commands/`)
runs in any project without OLS-specific values in the skill text. Project-specific facts (URLs, Jira
key, accounts, data recipe, transitions) come from a per-project guide or recipe the skill discovers.
`test-data-prep-workflow` becomes one central skill that reads a per-project recipe, so no
`/pyrite-test-data-prep` custom skill is needed. The fix is made **in Helix** and reaches
SkillLane/team-pluton-skills through the existing daily `helix-sync.yml`.

The map ends with (owner chose "spec + build inside the map", 2026-11-18):

1. decided SDD docs in `docs/sdd/project-agnostic/` (`spec.md`, `plan.md`, `tasks.md`), approved by the owner, and
2. the change implemented in Helix and synced into team-pluton-skills, proven by the proof decided in
   [What proof ends this map](tickets/06-proof-of-done.md).

## Notes

- Domain: Helix QA skill pack (Thitic9203/helix) → synced into SkillLane/team-pluton-skills (`eng-qa-*`).
- Scope rule (owner, 2026-11-18): **only skills that come from Helix.** Never edit skills owned by others
  (team `pm-*` / `eng-*`, ols-qa, manual-maker).
- Owner answers 2026-11-18: fix at Helix upstream (not an overlay in the team repo) · test-data-prep =
  one skill + per-project recipe · all Helix skills, not a pilot.
- Every code/skill change follows SDD (global rule 26) and the ADLC gates (rule 27): plan approval
  before implementation, PR approval before merge.
- Known risk to settle first: Helix itself receives `chore(sync): pull shared skill updates from ols-qa`
  commits (latest `9f32fae`, 2026-11-18). Ticket 01 checks whether that sync can overwrite Helix edits.
- repo-guard warning (2026-11-18): Pyrite-monorepo has no repo-guard pre-push hook; nothing is pushed or
  merged to main until the owner resolves it.
- Free tooling only (rule 3); no metered CI added.

## Decisions so far

<!-- one line per closed ticket -->

## Not yet specified

- Implementation tickets: one per SDD task, graduated after the owner approves the plan.
- How the OLS recipe now kept in the private evidence repo (`ols-data-prep.md`) is reached by the
  central skill, and whether OLS behaviour must stay byte-identical.
- What fills Pyrite's recipe (`references/pyrite-data-prep.md` is a skeleton: roles, accounts, data
  types are "not configured"). Facts must come from the Pyrite team, not guesses.
- Menu, routing and intent text that names OLS (`menu-text.md`, `skill-routing.md`, `intent-shortcuts.md`).
- How the team repo's generated docs drop the "(OLS)" label from `/eng-qa-test-data-prep` after sync.

## Out of scope

- `smoke-test-workflow` and `content-takedown-workflow`: come from ols-qa, not Helix (owner scope rule
  2026-11-18). `/eng-qa-smoke-test` stays OLS-bound; `/pyrite-smoke-test` stays a separate proposal.
- manual-maker skills and the team's `pm-*` / `eng-*` skills: owned by others.
