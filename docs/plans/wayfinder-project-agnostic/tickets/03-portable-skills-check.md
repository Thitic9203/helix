# What the portable-skills CI check enforces today

Type: `wayfinder:research` (AFK) · Status: closed · Blocked by: — · Assignee: Claude (main thread)

## Question

What does `scripts/ci-check-portable-skills.sh` (and `scripts/tests/content.test.sh`) check, where does
it run, and why do the OLS mentions in `skills/procedures/test-data-prep-workflow/WORKFLOW.md` pass it?
Can it become the gate that proves "no project-specific values in skill text"?

## Resolution (2026-11-18, research subagent, spot-checked by main thread)

`scripts/ci-check-portable-skills.sh` runs `grep -rnF` over `skills/ commands/ references/` with 12
hardcoded fixed strings (:18-31, e.g. `/Users/`, `pd3-api`, `.ols-qa-secrets` :29 — verified); skips
`portable-content.md`, `gotchas.md`. Ran it: `EXIT=0`. Runs in `.github/workflows/version.yml`
(`pr-check` + release job). `scripts/tests/content.test.sh` checks unrelated content. "OLS" passes
because it is not a pattern; `check-no-secrets.sh` only blocks hashed exact identifiers.
`references/portable-content.md:13` already forbids product env names but nothing enforces it.

Can be the gate with: case-sensitive whole-word patterns kept outside the script (hashed like
`check-no-secrets.sh`), a path allowlist for per-project files (e.g. a `references/projects/` folder),
rewriting the 5 OLS files to placeholders, and `guards.test.sh` cases. Limit: a denylist only catches
listed values, so it cannot prove absence alone.
