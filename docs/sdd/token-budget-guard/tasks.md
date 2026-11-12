# Tasks — token budget guard

| # | Task | Rule | Failing check first | Done when |
|---|------|------|---------------------|-----------|
| 1 | Port graph_v2 to `scripts/token-measure.py` with a known-answer self-test on 18200e2 | R2 | self-test expects the token-diet numbers | self-test passes; output matches graph_v2 byte for byte |
| 2 | Generate `token-budget.json` from the latest release tag | R1 | test: file missing, check fails closed | file committed with its commit SHA |
| 3 | Pre-commit check | R3 | test: staging a +1-token change is refused | refused; a decrease is allowed |
| 4 | Pre-push check | R4 | test: a `--no-verify` commit is refused at push | refused |
| 5 | PR job `token-budget` with a summary table | R5 | test PR with +1 token fails | job red on the increase, green on a decrease |
| 6 | Branch protection requires `token-budget` and `pr-check` | R6 | API shows 404 | API shows both required |
| 7 | `publish` re-measures and gates the tag | R7 | dry run on an over-budget commit creates no tag | no tag, no release |
| 8 | Rule-line diff | R8 | test: deleting a MUST line fails; moving it passes; a registered, owner-approved reword passes; a register entry whose replacement is missing or not a rule fails; new entries without a [rule-reword] title + quote fail | all behave as stated |
| 9 | Raise-only-with-approval job, CODEOWNERS, ratchet-down write after release | R9 | test: a budget increase without the title or quote fails | fails; a raise PR with both passes |
| 10 | `token-report.json` asset and auto-update refusal | R10 | update test: a release with verdict `fail` is installed | install stays on the old version with one line of reason |
