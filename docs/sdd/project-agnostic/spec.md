# Spec: Helix skills work in any project

> Status: draft for owner approval (ADLC gate 3) · 2026-11-18 · Map: [wayfinder-project-agnostic](../../plans/wayfinder-project-agnostic/MAP.md)

## Scope

- In: every Helix skill (12: `helix` router + 11 workflows), their `skills/procedures/`, `references/`,
  `commands/`; the ols-qa → Helix sync guard (only the skip logic in ols-qa's sync script).
- Out: ols-qa skills (`smoke-test-workflow`, `content-takedown-workflow`), manual-maker, the team's
  `pm-*`/`eng-*` skills (owner, 2026-11-18). No new paid service or metered CI (global rule 3).
- Roles: owner (approves plan and PRs), QA user running a workflow in some project workspace.

## Rules

- **R1** Skill text (`skills/`, `skills/procedures/`, `commands/`, `references/`) must not contain a value
  tied to one project: product/env names, hosts, real Jira keys, secrets paths, private-repo URLs,
  required transition names. Placeholders like `{PROJECT}`, `{EVIDENCE_REPO}` are allowed.
  *Source:* `references/portable-content.md` table; owner destination 2026-11-18.
- **R2** Each project's guides and data recipes must live in that project's repo under `references/`;
  Helix must ship only templates. *Source:* ticket 04; `workspace-guide-discovery.md:53`.
- **R3** `references/workspace-guide-discovery.md` must list a glob row for all 11 workflows, including
  test-data-prep (`*-data-prep.md`, `*-test-data-guide.md`). *Source:* tickets 02, 04.
- **R4** `test-data-prep-workflow` must take roles, data types, naming rules, cover/media tooling and voice
  from the discovered recipe; when the recipe is silent it must not assume OLS defaults (OLS roles, Draw
  Things, `th-TH-NiwatNeural`). *Source:* ticket 02 (WORKFLOW.md :14, :54, :81, :145, :187, :247); owner
  "one skill + per-project recipe".
- **R5** When no guide/recipe value exists, the skill must ask once per value and save it immediately to the
  project's guide in the user's repo; it must never invent credentials, accounts, URLs or transitions, and
  must never write a secret into a repo (only the path of the local secrets file). A skeleton recipe row
  marked "not configured" counts as missing. *Source:* ticket 05; `workspace-guide-discovery.md:13, :49-54, :65`.
- **R6** `references/pyrite-data-prep.md` must leave Helix and be offered to the Pyrite repo as
  `references/pyrite-data-prep.md`; Helix gains `references/data-prep-recipe-template.md`. The OLS recipe
  stays in its private evidence repo and is reached via the OLS workspace guide, not linked from Helix.
  *Source:* ticket 04. Pyrite repo is not owner-created → PR only (global rule 30).
- **R7** Remaining couplings must become generic: comment marker `src=` takes the workspace name from the
  guide; retest evidence capture reads its tool contract from the guide; menu/routing text must not name
  one product's workspace. *Source:* ticket 02.
- **R8** Helix must keep an ownership list of files it owns; ols-qa's `scripts/sync-skills-to-helix.sh` must
  skip every listed file and print what it skipped. *Source:* ticket 10.
- **R9** `scripts/ci-check-portable-skills.sh` must also fail on whole-word, case-sensitive project tokens
  kept as SHA-256 hashes (as `check-no-secrets.sh` does), with a path allowlist for template files; it keeps
  running in `.github/workflows/version.yml` (PR + release). *Source:* ticket 03.
- **R10** `scripts/tests/guards.test.sh` must cover: a fixture with a project token fails R9; a simulated
  ols-qa sync touching an owned file leaves Helix unchanged (R8). *Source:* tickets 03, 06, 10.
- **R11** OLS must keep working: with the OLS guide + recipe present, test-data-prep Gate 0 shows the same
  intake fields as before the change. *Source:* ticket 06.

## Edge cases

- Workspace with both an old OLS-style `CLAUDE.md` data-prep block and a recipe → the recipe wins; the
  `CLAUDE.md` block is read only if the recipe names it.
- Two guides match one glob → list both and ask which once (existing discovery behaviour).
- Sync of an owned file from ols-qa → skipped and reported, never a silent drop.

## Done when

- [ ] R9 gate reports 0 hits on Helix `main` outside the allowlist, in CI.
- [ ] R10 test cases pass in `guards.test.sh`.
- [ ] Gate 0 dry run in a non-OLS workspace discovers or asks+saves the recipe (no data created).
- [ ] OLS Gate 0 intake fields unchanged (R11).
- [ ] team-pluton-skills receives the release via `helix-sync.yml`; README row for `/eng-qa-test-data-prep` no longer says "(OLS)".
