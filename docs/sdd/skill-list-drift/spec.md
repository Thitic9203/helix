# Spec — stop the skill list from drifting

## Problem

The list of shipped skills is written by hand in many places. When `review-result-workflow` and
`test-data-prep-workflow` arrived from ols-qa (6d8e4dd), none of them changed, and two audits on
2026-11-03 (8f3da7b, 403bb5a, 0e3de63) had to fix the same drift by hand in seven files.

Evidence (state of `main` at 0e3de63):

| Place | What it said | Real value |
|-------|--------------|------------|
| `scripts/link-skills.sh:33-35` | links every `skills/*/SKILL.md` except `procedures/` and `in-progress/` | 10 skills (helix + 9) — the source of truth |
| `scripts/helix-doctor.sh:43` | `EXPECTED_SKILLS` lists 8 | missing `review-result-workflow`, `test-data-prep-workflow` |
| `scripts/helix-doctor.sh:53` | "expect helix + 7 workflows" | helix + 9 |
| `docs/wiki/Home.md:57` | "`helix-doctor.sh` expects **8 skills**" | 10 |
| README, AGENTS.md, agent-entry, supported-agents, codex-tools, copilot-tools | counts 5–8, lists of 5–6 workflows | fixed by hand in 8f3da7b / 403bb5a |
| README (before 8f3da7b) | "Menus and questions are **English only**" | `scripts/tests/content.test.sh` scans `references skills commands hooks AGENTS.md` only, not README or docs/ |
| `scripts/helix-regression-check.sh` `[6/8]` | non-executable `*.sh` is only a WARN | `frontmatter-triggers.test.sh` sat at 100644 from b17272b until 0e3de63 |

Root cause: every list is maintained by hand, and no automated check compares it with the
skills that `link-skills.sh` actually links.

## Scope

In: `scripts/helix-doctor.sh`, `scripts/helix-regression-check.sh`, a new check script, a new
test under `scripts/tests/`, `docs/wiki/Home.md:57`.
Out: `install.sh`, `helix-auto-update.sh`, `.github/workflows/`, `hooks/`, `.claude-plugin/`
(CLAUDE.md "ต้องถามก่อน" list). CI already runs `bash scripts/tests/run.sh` in both jobs
(`.github/workflows/version.yml:52,130`), so a new `*.test.sh` is enforced without touching workflows.

## Rules

- **R1** — When `helix-doctor.sh` runs, the system must build the expected skill list from
  `skills/*/SKILL.md` with the same exclusions as `link-skills.sh` (`procedures/`, `in-progress/`),
  and must not hold a hand-written list. Source: `link-skills.sh:33-35`.
- **R2** — When `helix-doctor.sh` prints the global-links header, it must print the computed count,
  not a fixed number. Source: `helix-doctor.sh:53`.
- **R3** — When the doc check runs, it must fail if any of README.md, AGENTS.md,
  `docs/wiki/Home.md`, `references/agent-entry.md` does not name every linked workflow skill.
  Source: R1 list; these four files carry the direct-run tables fixed in 8f3da7b / 403bb5a / 0e3de63.
- **R4** — When the doc check runs, it must fail if any installed-count phrase
  (`helix + N workflow`, `**N skills**`, `expects **N skills**`) in README.md, `docs/`, `references/`
  states an N different from the computed count. Source: same.
- **R5** — When the doc check runs, it must fail if README.md or `docs/` says chat or menus are
  "English only". Source: `references/user-communication.md` ("Reply in the language the user writes in").
- **R6** — When `helix-regression-check.sh` finds a non-executable `*.sh` under `scripts/` or
  `hooks/`, it must report FAIL and exit non-zero, not WARN. Source: global CLAUDE.md rule 7
  (no silencing); the WARN let b17272b ship a 100644 test file.
- **R7** — The doc check must run in CI through a `scripts/tests/*.test.sh` file, with a case that
  proves it fails on a planted drift. Source: `docs/CONTRIBUTING.md` ("Add a `*.test.sh` next to them when you change a script").

## Edge cases

- A new skill in `skills/in-progress/` must not count (R1).
- `skills/procedures/*` has no `SKILL.md` stubs counted (R1).
- Number words ("nine `*-workflow`") — R4 checks digits only; word forms are a known gap, listed in plan.

## Done when

- `bash scripts/helix-doctor.sh` prints "all 10 skills linked" on a fresh install.
- Removing `test-data-prep-workflow` from README makes `bash scripts/tests/run.sh` fail.
- Writing "helix + 7 workflow" anywhere in scope makes it fail.
- A `chmod -x` on any `scripts/*.sh` makes `helix-regression-check.sh` exit non-zero.
- `bash scripts/tests/run.sh` and `helix-regression-check.sh` pass on `main`.
