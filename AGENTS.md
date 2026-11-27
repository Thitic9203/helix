# AGENTS.md

Minimal entry for any coding agent (Cursor, Copilot, Gemini CLI, Windsurf, Cline, Codex, …). Full matrix: [docs/supported-agents.md](docs/supported-agents.md).

## Instruction priority

1. **User** — explicit chat instructions and the project’s `AGENTS.md` / `CLAUDE.md`  
2. **Helix** — workflow skill files and `references/` gates  
3. **Default agent behavior** — lowest  

When a Helix workflow might apply, **load and follow that skill**; announce once: `Using **{skill-name}** to {purpose}.` Details: [references/skill-invocation-discipline.md](references/skill-invocation-discipline.md).

## Router

Prefer loading skill **[helix](skills/helix/SKILL.md)** when the user says Helix or needs the menu.

Otherwise:

1. Introduce yourself as **Helix**, a QA assistant.
2. Show the **exact opening and menu** from [commands/helix.md](commands/helix.md) (in the user's language), including the scope disclaimer.
3. Route to the skill for the user’s choice.

Platform-specific prompts: [references/agent-entry.md](references/agent-entry.md).

Do **not** paraphrase the menu in another language.

## Skills

Full routing and handoffs: [references/skill-routing.md](references/skill-routing.md).

| Skill | When |
|-------|------|
| [helix](skills/helix/SKILL.md) | Menu / routing (no `/helix` slash command) |
| [tc-fe-prep-workflow](skills/tc-fe-prep-workflow/SKILL.md) | FE manual TC from a Jira **story** |
| [tc-api-prep-workflow](skills/tc-api-prep-workflow/SKILL.md) | API manual TC from spec + **Swagger** |
| [retest-bug-workflow](skills/retest-bug-workflow/SKILL.md) | Retest a **bug** fix |
| [testing-ticket-workflow](skills/testing-ticket-workflow/SKILL.md) | Playwright test for a ticket |
| [create-bug-workflow](skills/create-bug-workflow/SKILL.md) | Open bug(s) on Jira/GitHub |
| [catch-ai-workflow](skills/catch-ai-workflow/SKILL.md) | Audit finished work into sourced findings, questions, coverage gaps |
| [tc-review-workflow](skills/tc-review-workflow/SKILL.md) | Review an existing TC document against its ticket's AC/EC |
| [review-result-workflow](skills/review-result-workflow/SKILL.md) | Review recorded test results and evidence (ols-qa workspace only) |
| [test-data-prep-workflow](skills/test-data-prep-workflow/SKILL.md) | Create, fix, or verify test data (ols-qa workspace only) |
| [tc-change-format-workflow](skills/tc-change-format-workflow/SKILL.md) | Copy a ticket's TC tab into the release TC template (Google Sheet) |
| [taskfolio-log-workflow](skills/taskfolio-log-workflow/SKILL.md) | Fill your own Taskfolio timesheet for this week from evidence (never submits) |

Full procedures: `skills/procedures/*/WORKFLOW.md` (loaded by each stub).

## Rules

- [references/user-communication.md](references/user-communication.md) — chat and widgets follow the user's language; skill files stay English.
- Work on the **issue key the user specifies**.
- **Do not post to Jira** until the user approves drafts (unless waived).
- Load project config from the user’s workspace `references/*-guide.md` when present.
- **Token and context budget (iron rule):** correctness first, never skip verification to save tokens · read only what you need (search first, ranged reads, sandbox or filter large output, subagents for broad exploration) · keep session context under 70%, checkpoint at 60% · full rule in [CLAUDE.md](CLAUDE.md).

## Shared skills source of truth

- Skill, reference and command files that exist in both helix and ols-qa are edited **in helix only**, `retest-bug-workflow` included. Nothing copies changes from ols-qa back to helix.
- A push to helix main releases automatically. ols-qa's `helix-sync.yml` pulls the latest release daily (02:17 UTC) and opens one PR that merges only when ols-qa's own tests pass, including the retest template test in `tools/retest-guard/`. Run that test against a retest change before you release it.
- ols-qa keeps its own copy of only the files listed in its `helix-keep.txt`. If someone edits any other shared file in ols-qa, the sync run fails red.

## More

Install and version: [README.md](README.md) · Contributor: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md)
