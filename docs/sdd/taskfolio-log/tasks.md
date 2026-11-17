# Tasks

| # | Task | Rules | Check that fails first | Done when |
|---|------|-------|------------------------|-----------|
| T1 | Generalise menu test `tools/r7-helix-one-question/check.test.js` | R14 | new assertion fails on a menu whose last option is not Other / a stale Other number | test green on the final tree |
| T2 | Add `skills/taskfolio-log-workflow/` (SKILL.md + `scripts/tf.sh`, `scripts/vpn_check.sh`) and `commands/taskfolio-log.md` | R1–R11 | `node tools/skill-lint/lint.js` / skill-structure suites before the files are complete | lint 0 violations; skill-structure green |
| T3 | Menu 13 Taskfolio Log, Other → 14; routing rows; helix SKILL ranges | R12 | T1 fails with menu at 13 + skill row added | T1 green |
| T4 | Doc counts and command lists | R13 | — (doc text) | README/agent-entry/codex/copilot name the new skill |
| T5 | Gates | all | — | `bash scripts/run-test-suites.sh`, `node tools/sdd-gate/check.js --base origin/main`, `git ls-files -z \| xargs -0 bash scripts/check-no-secrets.sh` exit 0 |
