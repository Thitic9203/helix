# Tasks — untestable-case paths

| # | Task | Rule | Failing check first | Done when |
|---|------|------|---------------------|-----------|
| 1 | Write `references/untestable-case-paths.md` | R1–R8 | no reference covers device sandbox, account search, responsive locators, env rerun, by-design skips | file exists with §1–§8 + MUST / NEVER |
| 2 | Link it conditionally from testing-ticket E2/E3, retest 4h, no-wait gate, index | R1–R8, R9 | `token-budget` must stay at the budget | links present; token check passes |
| 3 | Run regression, script tests, token budget, portable checks | R9 | — | all pass, output in the PR |
