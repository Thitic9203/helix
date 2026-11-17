# Spec — taskfolio-log-workflow description within R10

Trigger: board audit 17/Nov/2026 (ols-qa-evidence #148) re-measured always-on at v1.5.212: longest description 657 bytes
(`taskfolio-log-workflow`, added in #59). Owner 17/Nov/2026: "แก้เลย".

- R1. The `taskfolio-log-workflow` SKILL.md description MUST be ≤ 500 bytes.
  Source: `docs/sdd/token-diet/spec.md` R10 ("Skill descriptions are cut to ≤ 500 bytes").
- R2. It MUST keep every trigger phrase (ลง taskfolio, ลง timesheet, ลงเวลางาน, fill taskfolio, log timesheet, /taskfolio-log),
  every "Do NOT use" case (leave, another person's timesheet, Submit week, Jira worklogs), and the evidence-only / confirm-before-save /
  re-read / never-submit behaviour. Only wording is shortened.
- R3. ols-qa `skills/taskfolio-log-workflow/SKILL.md` gets the same bytes (parity, ols-qa #214).

Out of scope: `commands/taskfolio-log.md` (not a skill description; R10 does not cover it), the workflow body.

Done when: description 450 bytes; `bash scripts/ci-token-budget.sh pr origin/main` passes (always-on goes down);
`ci-check-skill-structure.sh` and `scripts/tests/run.sh` pass; ols-qa file blob-identical.

Plan: one file in each repo. Risk: routing — every trigger phrase and negative case is kept verbatim. No new cost.
Tasks: T1 edit (R1, R2) · T2 checks · T3 ols-qa parity PR (R3).
