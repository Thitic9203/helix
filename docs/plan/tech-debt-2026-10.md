# Helix tech-debt audit — 2026-10-07

Evidence sweep of `main` at v1.5.97 (read-only subagent). The main thread re-checked findings 1, 2, 7, 11, 12, 13, 16 and 20 before scoring.

**Score** = (Impact + Risk) × (6 − Effort). Each axis runs 1–5. Impact and Risk come from the evidence column. **Effort is an estimate**: nothing in the repo measures it.

## Prioritized list

| # | Item | Category | Evidence | I | R | E | Score |
|:-:|---|---|---|:-:|:-:|:-:|:-:|
| 1 | The ols-qa sync pushes straight to `main`, bypassing `pr-check`, and never registers new skills in `plugin.json` | Architecture / Infra | `7055d50`: main red from `8b0dd36` (2026-09-15) for about 21 days; the same gap hit catch-ai (`c743408`); dangling links shipped (`3b43215`, `04ff932`) | 4 | 5 | 2 | **36** |
| 2 | Auto-update pulls `origin main` with no CI or release check, so users received versions 1.5.89–1.5.92 that were never released | Infra | `scripts/helix-auto-update.sh:108`; `hooks/session-start:9` claims "latest GitHub release"; `git tag` has no v1.5.89–92 | 3 | 5 | 2 | **32** |
| 3 | The portable-content check passes when `rg` is missing, and it never scans `references/` | Test | `scripts/ci-check-portable-skills.sh:7,34`; it exits 0 with `rg` absent from `PATH`; `references/bug-priority-matrix.md:11` holds a machine path; `mcp__Control_Chrome__*` ships in 6 places | 2 | 4 | 1 | **30** |
| 4 | The skill count disagrees in six places, and `helix-doctor` misses 2 skills | Doc / Infra | `plugin.json` = 8; README:56 = 7; wiki:53/57, supported-agents:35 and `helix-doctor.sh:43` = 6; `.github/skills/` links = 6 | 3 | 3 | 1 | **30** |
| 5 | The tc-fe-prep stub description no longer matches its WORKFLOW, so routing reads the stale text | Content | `skills/tc-fe-prep-workflow/SKILL.md:3` vs `skills/deprecated/tc-fe-prep-workflow/WORKFLOW.md:3` | 3 | 2 | 1 | **25** |
| 6 | `version.yml` has no `concurrency:`; three bump paths (pre-commit, CI, sync) duplicate the same logic | Infra | `.github/workflows/version.yml` (no `concurrency`); `scripts/hooks/pre-commit:38` = `ci-needs-version-bump.sh:17`; 1.5.95 skipped by `2c3b0a1` | 2 | 3 | 1 | **25** |
| 7 | Language rules contradict each other: "English-only chat" vs a skill that posts Thai chat | Doc | `references/user-communication.md:5-12`, `DOC-MAP.md:19` vs `tc-fe-prep WORKFLOW.md:181,550,271` | 3 | 3 | 2 | **24** (needs a decision, see below) |
| 8 | The regression gate is not in CI, and parts of it cannot fail | Test | `scripts/helix-regression-check.sh:61-63` (always OK); [5/8] and [6/8] warn only; `version.yml` never calls it | 2 | 3 | 2 | **20** |
| 9 | Docs drift: wiki stuck at 1.5.31, DOC-MAP describes the wrong layout, one broken link | Doc | `docs/wiki/Home.md:5`; `DOC-MAP.md:81,93,94` and the per-skill table; `CONTRIBUTING.md:35` points at a renamed file | 2 | 2 | 1 | **20** |
| 10 | The update chain fails silently and a legacy path is hardcoded | Infra | `scripts/hooks/post-merge:19-23` (once moved the whole repo into the plugin cache); `|| true` / `2>/dev/null` in the chain; `~/.helix/tc-fe-prep` appears 37 times in 8 files | 2 | 4 | 3 | **18** |
| 11 | Tools the scripts need are not declared anywhere | Dependency | `rg`, `perl`, `python3`, `jq` (see #3, `check-no-secrets.sh:151`, `ci-check-skill-structure.sh:20`, `helix-setup-devenv.sh:66`) | 1 | 2 | 1 | **15** |
| 12 | Scripts and hooks have no tests | Test | no test files in the repo; only `export-test-md.py --self-test` exists, and CI does not run it | 3 | 4 | 4 | **14** |
| 13 | Rule text is copied instead of linked, and the WORKFLOW files are very large | Content | retest `WORKFLOW.md:362-405` = testing `:300-344`; 44 repeated lines of 90+ characters; retest WORKFLOW is 1041 lines / 92 KB | 3 | 3 | 4 | **12** |
| 14 | `skills/deprecated/` holds the canonical procedures | Content / naming | `DOC-MAP.md:18`; `skills/deprecated/README.md:7`; a wrong-depth link was fixed in `f118f0b`; 55 path references | 3 | 2 | 4 | **10** |
| 15 | A dead script duplicates CI logic | Code | `scripts/ci-auto-bump-commit.sh` (referenced nowhere) | 1 | 1 | 1 | **10** |

**Checked and clean:** no package manifests or lockfiles; no tracked file over 500 KB; no TODO/FIXME markers; no duplicate VERSION values; `sync-version --check`, `ci-check-skill-structure` and `export-test-md --self-test` pass at HEAD.

## Phased plan (alongside feature work)

**Phase 1: quick wins — DONE 2026-10-07** (helix `eed65a9`, CI green; mirrored to ols-qa `458ee7c`). Shipped straight to `main` at the user's request. The portable check now uses `grep`, because `rg` turned out to be a shell function on the operator machine, not a binary.
- #3: fail when `rg` is missing; scan `references/` too; add `mcp__Control_Chrome__` to the banned list.
- #4: fix every skill count, and add the 2 missing skills to `helix-doctor.sh`.
- #5: sync the tc-fe-prep stub description.
- #9: wiki version, DOC-MAP rows, and the `CONTRIBUTING.md:35` link.
- #11: list the required tools in README.
- #15: delete the dead script. This needs a yes under global rule 5 (removing a file).

**Phase 2 — DONE 2026-10-07** (approved by the user). helix `c85e60b` (v1.5.99): CI green, the regression gate ran in `publish`, release `v1.5.99` created. ols-qa `efeeb51`: sync gate, 9/9 sync tests pass, and 46 pre-push suites pass. Original scope:
- #1: make the ols-qa sync run `ci-check-skill-structure.sh` and register new skills before it pushes, or land through a PR. This touches the ols-qa repo.
- #2: auto-update follows the latest release tag instead of `main`. This changes `helix-auto-update.sh`, which affects every user.
- #6 and #8: add a `concurrency:` group to `version.yml` and run the regression gate in CI. This edits `.github/workflows/`.

**Phase 3 — mostly DONE 2026-10-07** (approved by the user)
- #14 done: `skills/deprecated/` was renamed to `skills/procedures/` in lockstep, helix `f877486` and ols-qa `ea70c78`. All 46 ols-qa suites pass, and the link check found no new breaks.
- #12 done: added `scripts/tests/`, mutation-checked and run in CI (helix `450a992`). It now has **33 checks in 5 files** after the follow-ups below.
- Follow-up, also done:
  - **Auto-update had never worked on the operator machine.** The clone was stuck at 1.5.90 while the plugin claimed 1.5.100. There were two causes: the `curl` VERSION probe failed TLS (MacPorts curl, exit 60), and 10 stale local `v1.5.x` tags made `git fetch --tags` refuse with "would clobber".
  - Fixes: clone installs now skip curl (`076e046`), and origin release tags take precedence over local ones (`58f76b5`). Each fix has a test that was red before it, and failures are now recorded.
  - Result: the local install updated to 1.5.103.
  - `scripts/tests/content.test.sh` (`c7b00f5`) guards against two regressions: losing the catch-ai Defect scope line in `references/non-pass-challenge-gate.md`, and the return of an "English-only chat" rule. It caught one rule the language change had missed, in `references/shared-must-never.md`, now fixed in both repos (ols-qa `90dae3d`).
- #10 done, in part: update-chain failures are now recorded and surfaced by session-start (`450a992`). The install path `~/.helix/tc-fe-prep` stays, because moving it would break every existing install.
- #13 **deferred**: the map session's `feat/round-time-spec` is editing the same WORKFLOW files. Dedupe after that branch merges.
- Incident found while doing #14: the ols-qa sync committed onto that feature branch (`cc9b698`, carrying an older `references/non-pass-challenge-gate.md`), because it assumed helix was on main. The sync now refuses unless helix is on `main` (ols-qa `d024676`, plus a test), and ols-qa has helix's newer file. **Follow-up:** when `feat/round-time-spec` merges, restore the catch-ai "Defect" scope line in `references/non-pass-challenge-gate.md` on main.

Original phase 3 scope:
- #12: a minimal test harness for bump, sync-version, check-no-secrets and link-skills.
- #13: replace the copied blocks with links to `references/root-cause-investigation.md` and `references/non-pass-challenge-gate.md`.
- #10: remove the legacy path and make the update-chain failures visible.
- #14: rename `skills/deprecated/`. This renames a directory, so it needs approval (Helix CLAUDE.md).

**Cost:** CI on a public repository runs on GitHub-hosted runners at no charge, so no item adds a new cost. Only #1 touches another repo (ols-qa).

## Decisions

- #7 (user, 2026-10-07): shipped skill chat follows **the user's language**; skill files stay English. Shipped in phase 1.
