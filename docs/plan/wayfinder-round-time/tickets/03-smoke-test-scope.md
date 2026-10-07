---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07)
blocked_by: []
---

# Smoke-test scope

## Question

`smoke-test-workflow` lives in `~/.claude/skills`, not in Helix, and arrives through a sync from another repo. Where is its canonical source? Would changing it mean touching another repo? Is it in or out of this map's destination?

## Resolution

**In scope** (user, 2026-10-07). `~/.claude/skills/smoke-test-workflow` is a symlink to the `ols-qa` repo (`skills/smoke-test-workflow`), and that repo holds the canonical source. Its content is OLS-specific, so `references/portable-content.md` keeps it out of Helix skills. The spec carries a separate smoke-test section, and the 15-minute cap applies to smoke as well. When the spec is executed, smoke-test changes land through a PR in `ols-qa`, so "touches another repo" = YES for that part. That answer must be stated in the PR.
