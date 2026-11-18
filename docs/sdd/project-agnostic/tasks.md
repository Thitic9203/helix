# Tasks: Helix skills work in any project

> From [plan.md](plan.md) · each task: rule served · failing test first · done when

| # | Task | Rules | Failing test first | Done when |
|---|---|---|---|---|
| T1 | Add `helix-owned-files.txt` listing test-data-prep's 3 files + the recipe template only | R8, R10 | `guards.test.sh`: owned-list integrity check fails while the list is missing | list merged; integrity test green (sync-skip test is in ols-qa, T6) |
| T2 | Extend `ci-check-portable-skills.sh` with hashed whole-word tokens + template path allowlist | R9 | fixture skill file with a denylisted token passes today → test fails | test green; gate run on `main` lists current hits (expected: the files T3–T5 fix) |
| T3 | Move every OLS rule into `ols-data-prep.md` (evidence repo) first, then make test-data-prep generic (SKILL.md, WORKFLOW.md, command); follow the writing-skills note at `SKILL.md:15` | R1, R4, R5 | T2 gate reports hits in these 3 files | 0 hits in these files; Gate 0 text asks for missing recipe values |
| T4 | Discovery rows for 6 workflows; recipe template; remove `pyrite-data-prep.md` | R3, R5, R6 | grep finds no `test-data-prep` row in discovery | rows present; template exists; Pyrite file gone from Helix |
| T5 | Generic marker, capture tooling, menu/routing text — same edit mirrored in ols-qa | R7 | T2 gate hits in those files | 0 hits Helix-wide outside allowlist |
| T6 | ols-qa sync script reads `helix-owned-files.txt`, skips + reports; missing list = skip nothing + warning | R8, R10 | new ols-qa test: sync of an owned file changes Helix → red | ols-qa test green; dry run prints skipped files |
| T7 | OLS guide row for data-prep in ols-qa; Pyrite recipe PR to SkillLane/Pyrite-monorepo | R6, R11 | OLS Gate 0 dry run cannot find recipe after T4 | OLS Gate 0 fields unchanged; Pyrite PR opened (merge = that repo's reviewers) |
| T7b | Regression: `helix-regression-check.sh`, token budget, eval-harness re-run of helix / retest-bug / testing-ticket | R12 | — | all pass; Exit gate kept |
| T8 | Release + verify downstream | Done-when | — | `version.yml` green; `helix-sync.yml` brings it to team-pluton-skills; README row without "(OLS)" |

Order: T1 → T2 → T3/T4/T5 (parallel-safe, disjoint files) → T6 → T7 → T8. Commits cite `Spec: docs/sdd/project-agnostic R<n>`.
