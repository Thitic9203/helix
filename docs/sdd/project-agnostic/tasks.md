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

## Status (main-thread verified)

| Task | Status | Evidence |
|---|---|---|
| T1 | done 2026-11-18 | 331840b — owned list + integrity test; guards 13/13, regression 9/9 |
| T2 | done 2026-11-18 | acc9cd9 — hashed project-token scan; guards 19/19; runtime list finds the 13 files from ticket 02 |
| T3 | done 2026-11-18 | 3ab9228, 025560c — OLS rules moved first (ols-qa-evidence 7ea5187e, Appendix H); RED run: skill announced OLS + offered OLS roles in a Pyrite workspace; GREEN run: announces the project, reads `references/pyrite-data-prep.md`, no OLS lists; all tests 0 failed; token budget no increase |
| T4 | done 2026-11-18 | 74851c0, 60a426a — discovery rows `Test data prep` + `Any other workflow`; `references/data-prep-recipe-template.md` (Helix-owned, plain path so ols-qa's link check passes); `pyrite-data-prep.md` removed. RED: content.test had no data-prep row. Budget first +60, then +23/+5 → trimmed discovery to `token-budget: pass (no increase over v1.5.216)`; 29 test files 0 failed; regression `All critical checks passed` |
| T5 | done 2026-11-18 | 4eec8b0 — 4 token hashes added first: scan RED 20 hits in 9 files (exit 1); after edits `ok: no portable-content violations` (also with the plain-token file). Marker `src=` from the workspace guide (`helix` if none); capture contract where the guide says; menu/routing `(workspace only)`; dangling `ols-project-guide.md` entry dropped. Budget no increase; 29 test files 0 failed. Mirror: ols-qa PR #298 (SDD, merge first) + #299 (same text, `cmp` clean vs 60a426a; OLS guide names `ols-qa`; 2 parsers + 2 tests re-pinned; `run-test-suites` ✅ 100 suites) |
| T6–T8, T7b | todo | — (Pyrite recipe already in SkillLane/Pyrite-monorepo main 67c9462, part of T7) |

Open items found by the GREEN run, owned by later tasks: discovery has no data-prep row (T4); the OLS guide does not point at the recipe (T7); the Pyrite recipe text still says the workflow is written for the other project and names undefined gates (T7, Pyrite repo).
