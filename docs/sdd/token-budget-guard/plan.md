# Plan — token budget guard

## The ten layers

| # | Layer | Where | Rule |
|---|-------|-------|------|
| 1 | Budget file, the single baseline; its history may rise only through `[token-budget-raise]` commits | `token-budget.json` + `scripts/check-budget-baseline.sh` | R1 |
| 2 | Measurement with a known-answer self-test | `scripts/token-measure.py` (ported from ols-qa-evidence `graph_v2.py`) | R2 |
| 3 | Pre-commit refuses an increase | `scripts/hooks/pre-commit` | R3 |
| 4 | Pre-push re-checks, catching `--no-verify` | `scripts/hooks/pre-push` | R4 |
| 5 | PR CI job `token-budget` | `.github/workflows/version.yml` (new job) | R5 |
| 6 | Required check on `main` | GitHub branch protection (owner approval) | R6 |
| 7 | Release gate on the exact commit | `publish` job `needs` + re-measure | R7 |
| 8 | Rule-line diff: no gate cut to save tokens | `scripts/check-rule-lines.sh` in layers 5 and 7; reword register `rule-line-register.json` gated by `scripts/check-rule-reword.sh` | R8 |
| 9 | Budget may only go up with the owner's approval | CI job + `CODEOWNERS` + auto-ratchet down after release | R9 |
| 10 | User-side refusal of a failing release | `token-report.json` release asset + `scripts/helix-auto-update.sh` | R10 |

Each layer checks on its own, so one layer being skipped never lets a release through.

## Files

`token-budget.json` (new), `scripts/token-measure.py` (new), `scripts/check-budget-baseline.sh` (new, R1 provenance), `scripts/check-rule-lines.sh` (new), `scripts/hooks/pre-commit`, `scripts/hooks/pre-push`, `.github/workflows/version.yml`, `.github/CODEOWNERS` (new), `scripts/helix-auto-update.sh`, `scripts/tests/token-budget-*.test.sh` (new), `docs/CONTRIBUTING.md` (one paragraph).

Helix CLAUDE.md says CI workflows, `helix-auto-update.sh` and hooks config need the owner's approval. They are asked together in the plan approval.

## Libraries

Python 3 standard library and bash only (free, rule 3). The CI time increase is about 10 s per run, within the free tier.

## Alternatives weighed

- CI-only check: one layer, and it can be bypassed by pushing without a PR while `main` is unprotected. Rejected; the owner asked for 10 layers.
- Measuring in ols-qa-evidence only: helix releases would not depend on it. Rejected.

## What could break

- A false fail that blocks a needed security fix. The R9 raise path with an owner quote covers it.
- The hooks add about 1 s per commit when skill files change.
- If the auto-update check is too strict, existing users stay on the old version. That is the intended failure mode: failing closed is safe.

## R1 provenance (12/Nov/2026)

The first R1 test compared the budget with a fresh measurement of its named release. An approved R9 raise
(helix#38) can never pass that, because a raise is above the measurement by design. Weighed:

- Equality only when the last change to the file is the ratchet commit: passes any later raise without
  checking how it got there. Rejected.
- Record the raised commit in the budget file: needs a new field written by hand in every raise PR. Rejected.
- Chosen: the release's own copy (first commit naming the tag + commit) must equal the measurement, and each
  later commit may raise only with `[token-budget-raise]` in its message. History is the record; no new field.
