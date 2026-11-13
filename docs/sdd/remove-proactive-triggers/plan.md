# Plan: remove metadata.proactive_triggers

## Files
- `skills/*/SKILL.md` (11 files: catch-ai, create-bug, helix, retest-bug, review-result, tc-api-prep, tc-change-format, tc-fe-prep, tc-review, test-data-prep, testing-ticket): delete the `metadata:` block (it holds only this key); add `Also triggers on:` line for uncovered phrases.
- `scripts/ci-check-skill-structure.sh`: replace the require-check with a reject-check (awk over the frontmatter).
- `scripts/lib/frontmatter-triggers.py`, `scripts/tests/frontmatter-triggers.test.sh`: delete.
- `scripts/tests/guards.test.sh`: add probe cases.
- `docs/new-skill-template.md`, `docs/pluton-ship-checklist.md`, `docs/skill-rules-authoring.md`: drop the field.
- `docs/plan/done_helix-ai-improvement-plan.html`: historical, left as is.

## Moved phrases (phrase not carried by description)
- catch-ai: review your work again; find your own mistakes; audit this deliverable
- create-bug: open bug; log defect
- retest-bug: retest task; check if bug is fixed
- review-result: review results; review evidence videos
- tc-api-prep: API test cases; Swagger test cases; OpenAPI test cases
- tc-change-format: move tc to template
- tc-fe-prep: TC FE prep; manual test cases from story; acceptance criteria test cases
- tc-review: review test cases; review the test case sheet; check tc coverage; review testcase
- test-data-prep: prepare test data; create test data; build training content; make covers; seed media / course / learning path
- testing-ticket: testing ticket; Playwright ticket; test ticket; run playwright on ticket
- helix: none

## Alternatives weighed
- Move into `description`: rejected, always-on bytes are ratcheted and would rise.
- Keep the check optional: rejected, owner said fix CI; reject-check prevents the field creeping back.

## Risks
- ols-qa vendors these skills and its `tools/skill-structure/check.js` still requires the field; helix sync must not land in ols-qa before ols-qa drops the requirement (ols-qa-plan.md). Order: ols-qa first or together.
- Direct tokens: removing ~100-250 bytes per skill outweighs the one-line additions.
