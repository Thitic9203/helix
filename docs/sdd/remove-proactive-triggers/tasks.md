# Tasks

- T1 (R3, R4): add probe cases to guards.test.sh (fails first: script still requires the key), change ci-check-skill-structure.sh, delete helper and its test. Done: `bash scripts/tests/guards.test.sh` passes.
- T2 (R1, R2): strip the `metadata:` block from 11 SKILL.md, add `Also triggers on:` lines. Done: grep empty, phrases present.
- T3 (R5): update three docs. Done: grep empty.
- T4 (R6, R7): run run.sh, three ci-check scripts, token budget. Done: all pass, no `.github/` in diff.
