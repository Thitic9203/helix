# Where per-project guides and recipes live and how skills find them

Type: `wayfinder:grilling` (HITL) · Status: closed · Blocked by: 01, 02, 09 · Assignee: Claude (main thread)

## Question

Today `references/pyrite-data-prep.md` sits inside Helix, the OLS recipe is in a private evidence repo,
and `references/workspace-guide-discovery.md` has no row for test-data-prep. Where should each
project's guide and data recipe live (Helix `references/`, the project's own repo, a private repo), and
what discovery rule does every Helix skill use to find it?

## Resolution (2026-11-18, owner via AskUserQuestion)

1. **Guides and data recipes live in each project's own repo** under `references/`; Helix ships only
   templates. Matches the existing rule that answers are saved to `references/{PROJECT}-{workflow}-guide.md`
   "in the user's repo" (`references/workspace-guide-discovery.md:53`) and the ban on one product's values in
   skills (`references/portable-content.md`). Consequence: `references/pyrite-data-prep.md` leaves Helix.
   SkillLane/Pyrite-monorepo is not on the repo-guard allowlist (global rule 30), so moving it there is a
   feature branch + PR for that repo's reviewers only.
2. **Discovery = extend the existing table in `workspace-guide-discovery.md` to all 11 workflows**
   (6 missing: test-data-prep, tc-review, tc-change-format, review-result, taskfolio-log, catch-ai — ticket 02).
