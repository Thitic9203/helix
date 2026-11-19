# Inventory of project-specific coupling in Helix skills

Type: `wayfinder:research` (AFK) · Status: closed · Blocked by: — · Assignee: Claude (main thread)

## Question

Across `skills/`, `skills/procedures/`, `references/` and `commands/` on Helix `main`, where does skill
text depend on one project? Count more than the word "OLS": secrets paths (`~/.ols-qa-secrets`), Jira
key patterns (`OLS-\d+`), hostnames/URLs, private evidence-repo recipes, transition ids, project-named
examples. Classify each hit as runtime behaviour, example/illustration, or routing/menu text, per file.

## Resolution (2026-11-18, research subagent, spot-checked by main thread)

Coupling is concentrated in **test-data-prep**; other workflows are mostly clean (no real Jira keys,
transition ids, Slack channels, Figma ids or hosts — only placeholders).
- Runtime: `skills/procedures/test-data-prep-workflow/WORKFLOW.md` (17 hits: private
  `{EVIDENCE_REPO}/docs/ols-data-prep.md` :14, OLS roles :81, Thai TTS :187, Draw Things covers :145/:247,
  reads repo `CLAUDE.md` data-prep section :54); `skills/test-data-prep-workflow/SKILL.md` (5);
  `commands/test-data-prep.md:9` hard-links private `ols-qa-evidence` (verified).
- `references/pyrite-data-prep.md` has **no inbound links** (verified: 0) — the workflow never picks it.
- `workspace-guide-discovery.md` covers 5 workflows (tc-fe/tc-api/retest/testing-ticket/create-bug);
  no row for test-data-prep, tc-review, tc-change-format, review-result, taskfolio-log, catch-ai.
- Minor: retest evidence points at OLS-only `<workspace>/references/qa-capture-tooling.md`
  (`retest-bug-workflow/execute-and-evidence.md:248`); comment marker `src={ols-qa|helix}`;
  `skill-reference-index.md:147` dangling `ols-project-guide.md`.
- Routing/menu text: "(ols-qa workspace only)" in `skill-routing.md:20`, `menu-text.md:23`,
  `intent-shortcuts.md:16`, `result-quality-gate.md:260`.
