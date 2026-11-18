# Inventory of project-specific coupling in Helix skills

Type: `wayfinder:research` (AFK) · Status: open · Blocked by: — · Assignee: —

## Question

Across `skills/`, `skills/procedures/`, `references/` and `commands/` on Helix `main`, where does skill
text depend on one project? Count more than the word "OLS": secrets paths (`~/.ols-qa-secrets`), Jira
key patterns (`OLS-\d+`), hostnames/URLs, private evidence-repo recipes, transition ids, project-named
examples. Classify each hit as runtime behaviour, example/illustration, or routing/menu text, per file.
