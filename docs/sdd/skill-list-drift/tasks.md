# Tasks — skill-list-drift

| # | Task | Rule | Failing test first | Done when |
|---|------|------|--------------------|-----------|
| T1 | `scripts/lib/skill-list.sh` helper | R1 | test: helper output equals the set of links `link-skills.sh` creates in a throwaway HOME | lists 10 names on `main` |
| T2 | doctor uses helper + computed header | R1, R2 | test: add a fake `skills/zz-workflow/SKILL.md` in the repo copy → doctor reports 11 | doctor prints "all 10 skills linked" |
| T3 | `ci-check-doc-skill-lists.sh` names check | R3 | test: delete the `test-data-prep-workflow` row from README copy → exit 1 with `README.md` in output | passes on `main` |
| T4 | count check | R4 | test: write "helix + 7 workflow" into `docs/wiki/Home.md` copy → exit 1 | passes on `main` after wiki:57 fix |
| T5 | language check | R5 | test: write "Menus are **English only**" into README copy → exit 1 | passes on `main` |
| T6 | regression `[6/8]` FAIL + `[9/9]` doc check | R6 | test: `chmod -x scripts/link-skills.sh` in repo copy → `helix-regression-check.sh` exits non-zero | exits 0 on `main` |
| T7 | CONTRIBUTING quick-check line | R7 | — | line present |

Commits reference `Spec: docs/sdd/skill-list-drift R<n>`. Branch: `chore/skill-list-drift`.
