# Plan — skill-list-drift

## Files

| File | Change | Rule |
|------|--------|------|
| `scripts/lib/skill-list.sh` (new) | `helix_linked_skills <repo>` prints one name per line, same `find` as `link-skills.sh` | R1 |
| `scripts/helix-doctor.sh` | source the helper; `EXPECTED_SKILLS` from it; header uses `${#EXPECTED_SKILLS[@]}` | R1, R2 |
| `scripts/ci-check-doc-skill-lists.sh` (new) | R3 names, R4 counts, R5 language; prints each miss as `path:line` | R3–R5 |
| `scripts/helix-regression-check.sh` | `[6/8]` sets the failure flag; add `[9/9]` calling the doc check | R6 |
| `scripts/tests/doc-skill-lists.test.sh` (new) | passes on the repo copy; fails after planting a missing name, a wrong count, and "English only" | R7 |
| `docs/wiki/Home.md:57` | "expects **10 skills**" | R4 |
| `docs/CONTRIBUTING.md` | add the new check to "Quick check before commit" | R7 |

Not touched: `link-skills.sh` stays as is; the helper copies its rule and the test asserts both
give the same list, so a later change to one is caught.

## Data

Linked skills = basenames of directories holding `SKILL.md` under `skills/`, excluding paths
containing `/procedures/` or `/in-progress/`. Workflow count = that list minus `helix`.

## Libraries / cost

Bash, `find`, `grep`, `sed` only — already required (README Prerequisites). No new dependency,
no paid service, no other repo touched. New cost: none.

## Options weighed

1. **Generate the doc tables from the skills** — removes drift fully but rewrites hand-written
   prose in four user docs and needs a generator step contributors must remember. Rejected for now.
2. **Check, do not generate (chosen)** — small, fails loudly in CI, keeps docs hand-written.
3. **Replace the tables with a link to `skill-routing.md`** — less to maintain, but README and
   AGENTS.md are the entry points users read first; removing tables changes their shape (rule 5 — ask).

## What may break

- The ols-qa sync job (`chore(sync)` commits) will start failing CI when it adds a skill without
  updating the docs. That is the intended signal; the sync author then adds the rows.
- `[6/8]` turning into FAIL blocks any branch that currently ships a 100644 script. `main` is clean
  at 0e3de63; open branches may need `chmod +x`.
- Known gap: number words ("nine") are not checked (R4 digits only).
