# Plan: Helix skills work in any project

> Implements [spec.md](spec.md) · 2026-11-18

## Files touched

| Repo | File | Rule |
|---|---|---|
| Helix | `skills/test-data-prep-workflow/SKILL.md` (description, announce line, source step) | R1, R4 |
| Helix | `skills/procedures/test-data-prep-workflow/WORKFLOW.md` (intake roles, covers, video voice, gates) | R1, R4, R5 |
| Helix | `commands/test-data-prep.md` (drop private ols-qa-evidence link) | R1 |
| Helix | `references/workspace-guide-discovery.md` (6 new rows; recipe = guide) | R3, R5 |
| Helix | `references/data-prep-recipe-template.md` (new) · delete `references/pyrite-data-prep.md` | R6 |
| Helix | `references/skill-reference-index.md`, `skill-routing.md`, `menu-text.md`, `intent-shortcuts.md`, `result-quality-gate.md` | R7 |
| Helix | `skills/procedures/retest-bug-workflow/{execute-and-evidence,comment-and-post}.md`, `skills/procedures/retest-bug-workflow/references/{comment-template-v2,worked-example}.md`, `skills/procedures/testing-ticket-workflow/results-update.md` | R7 |
| Helix | `helix-owned-files.txt` (new, repo root; test-data-prep 3 files + recipe template only) | R8 |
| Helix | `scripts/ci-check-portable-skills.sh`, new `scripts/project-token-hashes.txt` | R9 |
| Helix | `scripts/tests/guards.test.sh` + fixtures | R10 |
| ols-qa | `scripts/sync-skills-to-helix.sh` (read `$HELIX/helix-owned-files.txt`, skip + report) | R8 |
| ols-qa | `references/` OLS workspace guide: add a `data-prep` row pointing at `{EVIDENCE_REPO}/docs/ols-data-prep.md` | R6, R11 |
| ols-qa | same R3/R7 edits to the shared files (discovery, retest, testing-ticket, menu text) in the same change | R8 |
| ols-qa-evidence (private) | `docs/ols-data-prep.md`: receive every OLS rule removed from the skill | R4, R11 |
| SkillLane/Pyrite-monorepo | `references/pyrite-data-prep.md` (PR only, rule 30) | R6 |

No change by hand in SkillLane/team-pluton-skills: it receives the release through `helix-sync.yml`.

Path check (2026-11-18): discovery searches the **workspace** `references/` folder in both Helix and the
team-pluton-skills copy (`workspace-guide-discovery.md:18, :53`), so a project recipe at
`<project repo>/references/pyrite-data-prep.md` is found regardless of where the skills are installed.

## Data shapes

- `helix-owned-files.txt`: one repo-relative path per line, `#` comments; globs not allowed (explicit list
  is easier to review).
- `project-token-hashes.txt`: one SHA-256 hex per line of a whole-word token (e.g. a product name); the
  plain tokens stay in a local, untracked denylist like `check-no-secrets.sh` uses.

## Libraries / cost

Bash + coreutils `sha256sum`/`shasum` only; runs inside the existing `version.yml` jobs. No new service, no
new workflow, no extra CI minutes beyond a few seconds per run (rule 3: no new cost).

## Options weighed

- Ownership guard: list in Helix + ols-qa skip (chosen, ticket 10) vs CI alert only / PR mode / reversed sync.
- Recipe location: project repo (chosen, ticket 04) vs `references/projects/` in Helix vs private repo per project.
- Gate patterns: hashed whole-word tokens (chosen) vs plain words in the script — plain words would put
  product names back into the public repo.

## What could break

- OLS runs lose the recipe if the OLS guide row is missing → R11 regression check before merge.
- ols-qa sync script change ships before Helix has `helix-owned-files.txt` → script must treat a missing
  list as "skip nothing" and say so, then the list lands first (task order T1 → T6).
- Whole-word "OLS" matching hits legitimate text → allowlist only template paths; review hits by hand once.
- The ols-qa post-commit hook runs on one machine; a clone without the updated script can still overwrite
  → R10 test + note in ols-qa README.
