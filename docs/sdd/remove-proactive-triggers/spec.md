# Spec: remove metadata.proactive_triggers

Owner decision 13 Nov 2026 (answer to "tc-fe มี metadata.proactive_triggers ซ้ำกับ description (มีอยู่ใน 12 สกิล) จะลบออกไหมครับ?"): "ลบ + แก้ CI ด้วย".
Source for "the field is not read at runtime": Claude Code routes skills from `description` only; the only readers of `proactive_triggers` in helix are `scripts/ci-check-skill-structure.sh` and `scripts/lib/frontmatter-triggers.py`.

## Rules

- R1. When a helix `skills/*/SKILL.md` frontmatter is read, the system must not contain `proactive_triggers` (under `metadata:` or top level), and an emptied `metadata:` block must be removed too.
- R2. When a trigger phrase of the removed list is not carried by that skill's `description`, the phrase must still exist in the skill body as one line `Also triggers on: ...`. No phrase is dropped. `description` bytes must not grow (always-on budget).
- R3. When `scripts/ci-check-skill-structure.sh` runs, it must not require `proactive_triggers`, and it must fail a shipped SKILL.md whose frontmatter still has the key (stops reintroduction). Every other check in the script stays unchanged.
- R4. When the helper `scripts/lib/frontmatter-triggers.py` and its test have no remaining reader, they must be deleted, and `scripts/tests/guards.test.sh` must test R3 (passes as shipped, fails with a probe key).
- R5. When `docs/new-skill-template.md`, `docs/pluton-ship-checklist.md`, `docs/skill-rules-authoring.md` are read, they must not tell authors to add `proactive_triggers`.
- R6. The token budget check must still print `token-budget: pass` and `rule-lines: pass`; direct tokens must not rise per skill.
- R7. Must not touch `.github/workflows/`, ols-qa files, or other Helix checks. ols-qa gets a separate change list after PRs #250-#258 merge.

## Done when
- R1: `git grep proactive_triggers -- skills` is empty.
- R2: every phrase listed in plan.md "Moved phrases" is found in its SKILL.md body.
- R3/R4: `bash scripts/tests/run.sh` passes with the new probe cases.
- R5: `git grep proactive_triggers -- docs/*.md` is empty.
- R6: `bash scripts/ci-token-budget.sh pr origin/main` prints both pass lines.
- R7: `git diff --stat origin/main` lists no `.github/` path.
