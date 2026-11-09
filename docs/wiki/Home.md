# Helix Wiki

> **Canonical docs:** [README](https://github.com/Thitic9203/helix/blob/main/README.md) on `main`. **Keep this wiki in sync** when install/update/plugin behaviour changes.

**Version:** see the [VERSION file](https://github.com/Thitic9203/helix/blob/main/VERSION) · **Releases:** [releases](https://github.com/Thitic9203/helix/releases)

---

## What is Helix?

Portable **QA skill pack** for AI coding agents ([Agent Skills](https://agentskills.io) / `SKILL.md`):

- **TC FE prep** — manual test cases from Jira story AC/EC (coverage + ISTQB/29119-3 quality review, optional Test Type column, CSV/Excel/Test.md, Jira post-publish verification, four-axis final review report)
- **TC API prep** — manual test cases from API spec + Swagger (spec coverage + quality review, row ordering, CSV/Excel/Test.md, post-publish verification)
- **Testing ticket** — Playwright on one Jira ticket
- **Retest bug** — verify fix, post evidence, transition
- **Create bug** — file issues on Jira or GitHub
- **Catch AI** — audit finished work into sourced findings, questions, coverage gaps
- **TC review** — review an existing TC document against its ticket's AC/EC
- **TC change format** — copy a ticket's TC tab into the release TC template (Google Sheet)
- **Review result**, **Test data prep** — ols-qa workspace only

**Not tied to one vendor** — same skills in Claude Code, Cursor, Copilot, Gemini CLI, Windsurf, Cline, Codex, and more.

Full agent list: [supported-agents.md](https://github.com/Thitic9203/helix/blob/main/docs/supported-agents.md)

---

## Supported AI agents (summary)

| Agent | Global folder after install | Start Helix |
|-------|-----------------------------|-------------|
| Claude Code | `~/.claude/skills/` + plugin **`helix@helix-dev`** | `/helix` or `/tc-fe-prep`, … |
| Cursor | `~/.cursor/skills/` | `@helix` or skill **helix** |
| Codex | `~/.codex/skills/` | skill **helix** |
| GitHub Copilot | `~/.copilot/skills/` | skill **helix** in chat |
| Gemini CLI | `~/.gemini/skills/` | `/skills list` → **helix** |
| Windsurf | `~/.codeium/windsurf/skills/` | `@helix` |
| Cline | `~/.cline/skills/` | skill **helix** |
| OpenCode | `~/.config/opencode/skills/` | per tool docs |
| Pi | `~/.pi/agent/skills/` | per tool docs |
| Cross-agent | `~/.agents/skills/` | shared alias |

Prompts: [agent-entry.md](https://github.com/Thitic9203/helix/blob/main/references/agent-entry.md)

---

## Install (one-time)

Use the pinned install block in the README: [Install (one-time)](https://github.com/Thitic9203/helix#install-one-time). It downloads the installer of one named release, checks its SHA-256, and runs it only if the check passes.

**Installer does:**

- Clone/update `~/.helix/tc-fe-prep`
- Symlink **helix + 11 workflow skills** into global agent folders (`~/.cursor/skills/`, etc.)
- Enable Claude marketplace plugin **`helix@helix-dev`** (disable legacy **`helix@local`**)
- Register **SessionStart** hooks (bootstrap + **update check**)

**Skill layout:** Discovery stubs at `skills/{name}/SKILL.md` → full procedure at `skills/procedures/{name}/WORKFLOW.md`. `helix-doctor.sh` expects **12 skills** linked per agent.

| Agent | After install |
|-------|----------------|
| Claude Code | New session → `/helix` |
| Cursor | **Reload Window** → `@helix` |
| Copilot / Cline / Gemini / Codex | skill **helix** |

**Health check:**

```bash
bash ~/.helix/tc-fe-prep/scripts/helix-doctor.sh
HELIX_DOCTOR_FIX=1 bash ~/.helix/tc-fe-prep/scripts/helix-doctor.sh   # repair symlinks + plugin
```

**Team repo (optional):**

```bash
HELIX_LINK_WORKSPACE=$PWD ~/.helix/tc-fe-prep/scripts/link-skills.sh
```

Commit `.github/skills/` if the team uses Copilot in the same repository.

---

## Usage

**You do not have to start with `/helix`.** Call a workflow directly when you know the goal; use `/helix` or skill **helix** only for the menu.

| Goal | Claude Code | Other agents |
|------|-------------|--------------|
| FE test cases | `/tc-fe-prep` | `tc-fe-prep-workflow` (stub in `~/.cursor/skills/`) |
| API test cases | `/tc-api-prep` | `tc-api-prep-workflow` |
| Retest bug | `/retest-bug` | `retest-bug-workflow` |
| Test ticket | `/testing-ticket` | `testing-ticket-workflow` |
| Create bug | `/create-bug` | `create-bug-workflow` |
| Audit finished work | `/catch-ai` | `catch-ai-workflow` |
| Review a TC document | `/tc-review` | `tc-review-workflow` |
| Review recorded results (ols-qa workspace only) | `/review-result` | `review-result-workflow` |
| Prepare test data (ols-qa workspace only) | `/test-data-prep` | `test-data-prep-workflow` |
| Copy a TC tab into the release TC template | `/tc-change-format` | `tc-change-format-workflow` |
| Fill your Taskfolio timesheet from evidence | `/taskfolio-log` | `taskfolio-log-workflow` |
| Menu (optional) | `/helix` | skill **helix** |

Menu text: [menu-text.md](https://github.com/Thitic9203/helix/blob/main/references/menu-text.md) · Routing: [skill-routing.md](https://github.com/Thitic9203/helix/blob/main/references/skill-routing.md)

**TC prep delivery:** CSV/Excel (default), Jira comment + attachment, optionally **Test.md** for agent hand-off ([test-md-format.md](https://github.com/Thitic9203/helix/blob/main/references/test-md-format.md)). All Jira-posting workflows run **post-publish review** on the live comment before reporting done.

---

## Update — Helix tells you, you update

After install, a new **release tag** (created only after CI passes on `main`) is **announced**, not installed: each new session reads the release tag list once (read-only) and the agent mentions a newer release once. Nothing is fetched or moved at session start. To update:

```bash
bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh
```

| Trigger | Action |
|---------|--------|
| New Claude Code / Cursor session | [helix-auto-update.sh](https://github.com/Thitic9203/helix/blob/main/scripts/helix-auto-update.sh) `--check` (notice only) |
| You run the update command | same script, no arguments (updates) |
| `git pull` in `~/.helix/tc-fe-prep` | post-merge hook → sync plugin + symlinks |

**What the update command does:**

1. Fast-forward `~/.helix/tc-fe-prep` to the newest release tag (never unreleased `main`)
2. Refresh skill symlinks (`link-skills.sh`)
3. `claude plugin update helix@helix-dev` (Claude Code)

| Setting | Meaning |
|---------|---------|
| `HELIX_AUTO_UPDATE=0` | Turn off the session-start check (the update command still works) |
| `HELIX_FORCE_UPDATE`, `HELIX_AUTO_UPDATE_INTERVAL_SEC` | Ignored (accepted, no effect) |
| `HELIX_AUTO_UPDATE_VERBOSE=1` | Print to terminal |
| Log | `~/.helix/auto-update.log` |

**Manual fallback:**

```bash
bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh
# or
cd ~/.helix/tc-fe-prep && git pull
bash ~/.helix/tc-fe-prep/scripts/claude-plugin-sync.sh
```

**Claude plugin:** use **`helix@helix-dev` only** — not `helix@local` (legacy, auto-disabled).

**After update:** Cursor → Reload Window; Claude Code → new session if `/helix` still looks old.

Full detail: [README — Update](https://github.com/Thitic9203/helix/blob/main/README.md#update-when-a-new-version-ships)

---

## Workflow docs

| Workflow | Discovery stub | Full procedure |
|----------|----------------|----------------|
| Router | [helix](https://github.com/Thitic9203/helix/blob/main/skills/helix/SKILL.md) | — |
| TC FE | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/tc-fe-prep-workflow/SKILL.md) | [WORKFLOW.md](https://github.com/Thitic9203/helix/blob/main/skills/procedures/tc-fe-prep-workflow/WORKFLOW.md) |
| TC API | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/tc-api-prep-workflow/SKILL.md) | [WORKFLOW.md](https://github.com/Thitic9203/helix/blob/main/skills/procedures/tc-api-prep-workflow/WORKFLOW.md) |
| Retest | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/retest-bug-workflow/SKILL.md) | [WORKFLOW.md](https://github.com/Thitic9203/helix/blob/main/skills/procedures/retest-bug-workflow/WORKFLOW.md) |
| Testing ticket | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/testing-ticket-workflow/SKILL.md) | [WORKFLOW.md](https://github.com/Thitic9203/helix/blob/main/skills/procedures/testing-ticket-workflow/WORKFLOW.md) |
| Create bug | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/create-bug-workflow/SKILL.md) | [WORKFLOW.md](https://github.com/Thitic9203/helix/blob/main/skills/procedures/create-bug-workflow/WORKFLOW.md) |
| Catch AI | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/catch-ai-workflow/SKILL.md) | — (self-contained) |
| TC review | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/tc-review-workflow/SKILL.md) | — (self-contained) |
| Review result | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/review-result-workflow/SKILL.md) | [WORKFLOW.md](https://github.com/Thitic9203/helix/blob/main/skills/procedures/review-result-workflow/WORKFLOW.md) |
| Test data prep | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/test-data-prep-workflow/SKILL.md) | [WORKFLOW.md](https://github.com/Thitic9203/helix/blob/main/skills/procedures/test-data-prep-workflow/WORKFLOW.md) |
| TC change format | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/tc-change-format-workflow/SKILL.md) | — (self-contained) |
| Taskfolio log | [SKILL.md](https://github.com/Thitic9203/helix/blob/main/skills/taskfolio-log-workflow/SKILL.md) | — (self-contained) |

Plugin registers every linked skill in [.claude-plugin/plugin.json](https://github.com/Thitic9203/helix/blob/main/.claude-plugin/plugin.json).

---

## Maintainer scripts

| Script | Role |
|--------|------|
| [install.sh](https://github.com/Thitic9203/helix/blob/main/scripts/install.sh) | Full setup |
| [helix-auto-update.sh](https://github.com/Thitic9203/helix/blob/main/scripts/helix-auto-update.sh) | `--check` at session start (notice only) · no args = update you run |
| [claude-plugin-sync.sh](https://github.com/Thitic9203/helix/blob/main/scripts/claude-plugin-sync.sh) | `helix@helix-dev` marketplace sync |
| [helix-doctor.sh](https://github.com/Thitic9203/helix/blob/main/scripts/helix-doctor.sh) | Verify install |
| [link-skills.sh](https://github.com/Thitic9203/helix/blob/main/scripts/link-skills.sh) | Refresh symlinks |
| [export-markdown-table-to-csv.py](https://github.com/Thitic9203/helix/blob/main/scripts/export-markdown-table-to-csv.py) | TC table → CSV |
| [export-test-md.py](https://github.com/Thitic9203/helix/blob/main/scripts/export-test-md.py) | TC table → Test.md |
| [helix-regression-check.sh](https://github.com/Thitic9203/helix/blob/main/scripts/helix-regression-check.sh) | Contributor: pre-merge regression gate (`/helix-check`) |
| [helix-setup-devenv.sh](https://github.com/Thitic9203/helix/blob/main/scripts/helix-setup-devenv.sh) | Retired — undo only (`--uninstall`) ([CONTRIBUTING](https://github.com/Thitic9203/helix/blob/main/docs/CONTRIBUTING.md#dev-environment--fewer-agent-questions-two-layers)) |

---

## More links

- [Documentation map](https://github.com/Thitic9203/helix/blob/main/docs/DOC-MAP.md)
- [Contributing / versioning](https://github.com/Thitic9203/helix/blob/main/docs/CONTRIBUTING.md)
- [Domain glossary (CONTEXT)](https://github.com/Thitic9203/helix/blob/main/CONTEXT.md)
- [AGENTS.md](https://github.com/Thitic9203/helix/blob/main/AGENTS.md) — entry for generic agents
