# Helix — AI QA assistant

**Version: 1.5.173** · [Releases](https://github.com/Thitic9203/helix/releases)

> ⚠️ **Security notice (2026-11-04, fixed in v1.5.167):** install and auto-update risks — read [SECURITY-NOTICE.md](SECURITY-NOTICE.md) and update to v1.5.167 or later.

Portable skill pack for AI agents: **FE/API manual test-case prep** (with coverage + quality review), **Playwright ticket testing**, **create bug**, **Jira bug retests**, **TC review**, and **Catch AI** self-audit of finished work — one entry menu across tools.

> **Scope & expectations**  
> Helix is built for QA work with **clear boundaries**—a defined ticket, environment, inputs, and what “done” looks like. When the scope is vague or still in flux, you may need extra clarification rounds, and the output may require more review. Sharper scope upfront usually means stronger, faster results.

## Why Helix

| Workflow | Summary |
|----------|---------|
| **TC FE Preparation** | Story AC/EC → coverage + quality review → optional **Test Type** column → draft table → CSV/Excel and/or **Test.md** → Jira comment with post-publish verification → **four-axis final review report** |
| **TC API Preparation** | API spec + Swagger → coverage review → API TC table (ordered: happy path first) → comment, CSV/Excel, and/or **Test.md** → post-publish verification |
| **Retest Bug** | Verify a fix — API/UI, Swagger, evidence, comment, transition |
| **Testing Ticket** | Intake → Playwright → summary in chat → optional result update elsewhere |
| **Create Bug** | Jira/GitHub target + format + details → confirm → file and verify |
| **Catch AI** | Audit finished work — your own output, a document, a report, or a feature — into sourced findings, open questions, coverage gaps, and a verdict |
| **TC Review** | Review an existing TC document against its ticket's AC/EC and business rules → traceability matrix, Good vs Need Improve |
| **Review Result** | Review already-recorded test results and evidence clips → PASSED / FAILED / AWAITING RE-REVIEW per case (ols-qa workspace) |
| **Test Data Prep** | Create, fix, or verify test data on a named environment before testing (ols-qa workspace) |
| **TC Change Format** | Copy a ticket's TC tab into the project's release TC template (Google Sheet) |

TC prep workflows include **AC/EC or spec/Swagger alignment review**, **ISTQB / ISO/IEC/IEEE 29119-3–aligned** quality checks, and **mandatory Jira post-publish review** before close-out (see [qa-evidence-gates.md](references/qa-evidence-gates.md)). FE prep also ends with a **four-axis final TC review report** (AC/EC alignment, spelling, numbering, scope).

**Delivery formats (TC prep):** CSV/Excel (default for spreadsheets), Jira comment + attachment, and optionally **Test.md** — an agent-native format for Kane CLI / Playwright agents ([test-md-format.md](references/test-md-format.md)). Test.md is additive; never replaces CSV for spreadsheet users.

## Supported AI agents

Helix uses the open **[Agent Skills](https://agentskills.io)** format (`SKILL.md`). One install links skills for every path your machine supports.

| Agent / IDE | Supported | Global skills folder (after install) |
|-------------|-----------|--------------------------------------|
| **Claude Code** | Yes | `~/.claude/skills/` + plugin cache |
| **Cursor** | Yes | `~/.cursor/skills/` |
| **OpenAI Codex** | Yes | `~/.codex/skills/` |
| **GitHub Copilot** (VS Code) | Yes | `~/.copilot/skills/` |
| **Gemini CLI** | Yes | `~/.gemini/skills/` |
| **Windsurf Cascade** | Yes | `~/.codeium/windsurf/skills/` |
| **Cline** | Yes | `~/.cline/skills/` |
| **OpenCode** | Yes | `~/.config/opencode/skills/` |
| **Pi** | Yes | `~/.pi/agent/skills/` |
| **Other (Agent Skills)** | Yes | `~/.agents/skills/` (shared alias) |

**Team / repo scope (optional):** `.github/skills/`, `.agents/skills/`, `.windsurf/skills/`, `.cline/skills/`, `.gemini/skills/` when you run workspace linking (below).

Details: [docs/supported-agents.md](docs/supported-agents.md) · copy-paste prompts: [references/agent-entry.md](references/agent-entry.md)

Web-only chat without skill discovery is not supported — use an agent that loads `SKILL.md` folders.

## Install (one-time)

### Step 1 — Everyone (same command)

This downloads the installer of one named release, checks its SHA-256, and runs it only if the check passes. If a download fails or the hash does not match, nothing is installed and nothing is written under your home folder (the two files land in the current folder only).

```bash
HELIX_TAG=v1.5.173
base="https://github.com/Thitic9203/helix/releases/download/$HELIX_TAG"
curl -fsSLO "$base/install.sh" && curl -fsSLO "$base/install.sh.sha256" \
  && [ "$(wc -l < install.sh.sha256)" -eq 1 ] \
  && IFS= read -r line < install.sh.sha256 && case "$line" in *"$(printf '\r')"*) false ;; *) true ;; esac \
  && { if command -v sha256sum >/dev/null; then sha256sum -c install.sh.sha256; else shasum -a 256 -c install.sh.sha256; fi; } \
  && HELIX_TAG="$HELIX_TAG" bash install.sh
```

The installer then checks out that same tag (not `main`) and refuses to touch a clone that has local changes or local commits. This clones Helix to `~/.helix/tc-fe-prep`, symlinks **helix + 10 workflow skills** into the global folders above (skips paths that do not exist on your OS yet), registers the **Claude Code** plugin cache, enables **`helix@helix-dev`** (and disables legacy `helix@local`), and wires **SessionStart** hooks for bootstrap and a read-only notice when a newer release exists (it never updates by itself).

### Step 2 — By agent (what you do next)

| Agent / IDE | After the install script | Optional: skills in your git repo (team) |
|-------------|------------------------|------------------------------------------|
| **Claude Code** | Open the project → run `/helix` | `HELIX_LINK_WORKSPACE=$PWD ~/.helix/tc-fe-prep/scripts/link-skills.sh` |
| **Cursor** | Reload window → `@helix` or ask for skill **helix** | Same `HELIX_LINK_WORKSPACE=…` from repo root |
| **Codex** | Run Codex in a folder → skills auto-discovered | Same workspace command → `.agents/skills/` etc. |
| **GitHub Copilot** | VS Code: ensure Agent Skills enabled → skill **helix** in chat | **Recommended:** workspace link → `.github/skills/` |
| **Gemini CLI** | `gemini` → `/skills list` → use **helix** | Workspace link → `.gemini/skills/` or `.agents/skills/` |
| **Windsurf** | `@helix` in Cascade | Workspace link → `.windsurf/skills/` |
| **Cline** | Enable Skills → pick **helix** | Workspace link → `.cline/skills/` |
| **OpenCode / Pi** | Open project → skill list per tool docs | Workspace link → `.agents/skills/` |

**Workspace link (one line, from your project root):**

```bash
HELIX_LINK_WORKSPACE=$PWD ~/.helix/tc-fe-prep/scripts/link-skills.sh
```

Commit `.github/skills/` if your team uses Copilot on the same repository. The **Helix repo** ships portable relative symlinks under `.github/skills/` (safe to commit).

### Health check (`helix doctor`)

After install (or when skills do not appear):

```bash
bash ~/.helix/tc-fe-prep/scripts/helix-doctor.sh
# optional: also check project skill folders
HELIX_LINK_WORKSPACE=$PWD bash ~/.helix/tc-fe-prep/scripts/helix-doctor.sh
```

Reports Helix version, global skill symlinks per agent, and Claude plugin cache. **Works best with:** Jira (MCP or logged-in browser), Playwright in your app repo, optional `references/*-guide.md` in your project.

## Usage

**You do not have to start with `/helix`.** If you already know the workflow, call it directly — that skips the menu and is the recommended path. Use `/helix` (or skill **`helix`**) only when you want the menu or are unsure which workflow fits.

### Run a workflow directly (recommended when you know the goal)

| Goal | Claude Code | Other agents (skill name) |
|------|-------------|---------------------------|
| FE manual TC from story | `/tc-fe-prep` | `tc-fe-prep-workflow` (stub → WORKFLOW) |
| API manual TC from spec + Swagger | `/tc-api-prep` | `tc-api-prep-workflow` |
| Retest a bug after a fix | `/retest-bug` | `retest-bug-workflow` |
| Playwright test for one ticket | `/testing-ticket` | `testing-ticket-workflow` |
| File bugs on Jira or GitHub | `/create-bug` | `create-bug-workflow` |
| Audit finished work (self-check, second opinion) | `/catch-ai` | `catch-ai-workflow` |
| Review an existing TC document against AC/EC | `/tc-review` | `tc-review-workflow` |
| Review recorded test results and evidence | `/review-result` | `review-result-workflow` |
| Prepare test data before testing | `/test-data-prep` | `test-data-prep-workflow` |
| Copy a TC tab into the release TC template | `/tc-change-format` | `tc-change-format-workflow` |

Append a Jira key or URL when your tool supports it, e.g. `/tc-fe-prep PROJ-123` or “run `retest-bug-workflow` on PROJ-456”.

Full map: [references/skill-routing.md](references/skill-routing.md) · copy-paste prompts: [references/agent-entry.md](references/agent-entry.md)

### Open the Helix menu (optional — when unsure)

| Agent / IDE | How to open the menu |
|-------------|----------------------|
| **Claude Code** | `/helix` |
| **Cursor** | `@helix` or “use skill helix” |
| **Windsurf** | `@helix` |
| **GitHub Copilot** | “Follow the **helix** skill and show the QA menu” |
| **Gemini CLI** | `/skills list` then skill **helix** |
| **Cline** | Select skill **helix** |
| **Codex** | Ask to load skill **helix** |
| **OpenCode / Pi** | Invoke **helix** per tool’s skill UI |

The menu offers options 1–13 (TC FE, TC API, retest, testing ticket, create bug, Catch AI, TC review, four ols-qa-workspace-only options, TC change format, other) and routes to the same workflows as the table above. Exact text: [references/menu-text.md](references/menu-text.md).

### First run tips

- Workflows auto-load **`references/*-guide.md`** in your repo when present ([workspace-guide-discovery.md](references/workspace-guide-discovery.md)) — fewer repeated questions.
- Long sessions may write **`references/helix-handoff-{KEY}.md`** so you can resume in a new chat ([session-closing.md](references/session-closing.md)).
- Menus, questions, and replies follow **the language you write in**; technical terms, file names, and ticket keys stay as-is — [references/user-communication.md](references/user-communication.md). Skill files themselves stay in English.
- Non–Claude Code agents: read [AGENTS.md](AGENTS.md) if the tool loads repo-level agent instructions.

## Update (when a new version ships)

Releases: [github.com/Thitic9203/helix/releases](https://github.com/Thitic9203/helix/releases) (tagged on every `main` push that bumps [VERSION](VERSION)).

### Updates: Helix tells you, you update

After a **one-time** [install](#install-one-time), a new **released** version (a `vX.Y.Z` tag, created only after CI passes on `main`) is **announced**, not installed. Each agent session start runs one read-only `git ls-remote` on the release tags; when a newer release exists, the agent mentions it once. **Nothing is fetched, moved or re-linked at session start.** You update when you choose to:

```bash
bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh
```

| Trigger | What runs |
|---------|-----------|
| New **Claude Code** session (`helix@helix-dev` enabled) | [hooks/session-start](hooks/session-start) → `helix-auto-update.sh --check` (read-only; prints one line if a newer release exists) |
| New **Cursor** session (Helix hooks active) | same |
| **You** run the update command above | [scripts/helix-auto-update.sh](scripts/helix-auto-update.sh) (no arguments) |
| You run `git pull` in `~/.helix/tc-fe-prep` | [scripts/hooks/post-merge](scripts/hooks/post-merge) → refresh symlinks + [claude-plugin-sync](scripts/claude-plugin-sync.sh) |

**What the update command does:**

1. Fetch `main` and tags, then fast-forward `~/.helix/tc-fe-prep` to the newest release tag — never to unreleased `main`, never backwards (skill symlinks pick up new `SKILL.md` immediately)
2. `link-skills.sh` (refresh global + optional workspace symlinks)
3. `claude plugin update helix@helix-dev` (Claude Code marketplace plugin + hooks)

Failures are recorded in `~/.helix/last-update-error` and shown once at the next session start. Log file: `~/.helix/auto-update.log` · Doctor: [helix-doctor.sh](scripts/helix-doctor.sh)

| Setting | Environment variable |
|---------|----------------------|
| Turn off the session-start check (the update command still works) | `HELIX_AUTO_UPDATE=0` |
| Print progress to terminal | `HELIX_AUTO_UPDATE_VERBOSE=1` |
| Ignored since this change (accepted, no effect) | `HELIX_FORCE_UPDATE`, `HELIX_AUTO_UPDATE_INTERVAL_SEC` |

**Notes**

- The session-start check needs **network**; offline → no notice, no error.
- **Cursor / Copilot / Codex / …** — skills update via symlinks after pull; **Reload window** (Cursor) if the agent still shows old skill text.
- **Claude Code** — after a plugin version jump, **start a new session** once if `/helix` or slash commands look stale (skills via `~/.claude/skills` are usually current sooner).

### Claude Code plugin id

| Plugin | Status |
|--------|--------|
| **`helix@helix-dev`** | Canonical — install/update/enable (installer + update command) |
| **`helix@local`** | Legacy — **disabled** automatically (do not enable; uninstall can break `helix@helix-dev`) |

`install.sh` and `claude-plugin-sync.sh` keep the marketplace plugin aligned with [VERSION](VERSION).

### Manual update (fallback)

Use if the session-start check is off, you deleted `~/.helix/tc-fe-prep`, or you want to force sync now:

```bash
cd ~/.helix/tc-fe-prep && git pull
bash ~/.helix/tc-fe-prep/scripts/claude-plugin-sync.sh   # Claude Code: helix@helix-dev
bash ~/.helix/tc-fe-prep/scripts/link-skills.sh            # if symlinks missing
```

Or re-run the full installer: use the pinned install block under [Install (one-time)](#install-one-time).

### By agent (when something still looks old)

| Agent / IDE | Usually enough | Re-run only if… |
|-------------|----------------|-----------------|
| **Claude Code** | Run the update command, then open a **new session** | `/helix` still old → `bash ~/.helix/tc-fe-prep/scripts/claude-plugin-sync.sh` or full `install.sh` |
| **Cursor** | New session + Reload Window | Skills missing → `link-skills.sh` |
| **Codex / Copilot / Gemini / Windsurf / Cline / Pi** | New session | Symlinks removed → `link-skills.sh` |
| **Team `.github/skills/`** | Update the clone with the update command + pull your app repo | New Helix skill added → `HELIX_LINK_WORKSPACE=$PWD …/link-skills.sh` |

### Marketplace-only install (no `~/.helix` clone)

If you only installed **`helix@helix-dev`** from Claude marketplace (never ran the install block):

- **Plugin + hooks** can still update via SessionStart → `claude-plugin-sync.sh`
- **Global skills** (`~/.cursor/skills`, etc.) need **`install.sh` once** so symlinks point at `~/.helix/tc-fe-prep`

Current release: **README version line above** or [Releases](https://github.com/Thitic9203/helix/releases).

<details>
<summary>Manual install (contributors)</summary>

```bash
git clone https://github.com/Thitic9203/helix.git
cd helix
./scripts/setup.sh
git config core.hooksPath scripts/hooks
```

**Fewer agent questions while developing Helix.** Opening the repo in
Claude Code already gives you read-only command allows + context hooks (committed
`.claude/settings.json`). The old global opt-in script is retired and adds nothing.
If you ran it in the past, undo it (restores your files from the backups it made):

```bash
bash scripts/helix-setup-devenv.sh --uninstall
```

Requires `jq`. Details: [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md#dev-environment--fewer-agent-questions-two-layers).

</details>

## Skills

| Skill (discovery stub) | Full procedure | Description |
|------------------------|----------------|-------------|
| [helix](skills/helix/SKILL.md) | — | Router menu (agents without `/helix`) |
| [tc-fe-prep-workflow](skills/tc-fe-prep-workflow/SKILL.md) | [WORKFLOW.md](skills/procedures/tc-fe-prep-workflow/WORKFLOW.md) | FE manual TC from story AC/EC |
| [tc-api-prep-workflow](skills/tc-api-prep-workflow/SKILL.md) | [WORKFLOW.md](skills/procedures/tc-api-prep-workflow/WORKFLOW.md) | API manual TC from spec + Swagger |
| [retest-bug-workflow](skills/retest-bug-workflow/SKILL.md) | [WORKFLOW.md](skills/procedures/retest-bug-workflow/WORKFLOW.md) | Bug retest with evidence |
| [testing-ticket-workflow](skills/testing-ticket-workflow/SKILL.md) | [WORKFLOW.md](skills/procedures/testing-ticket-workflow/WORKFLOW.md) | Playwright ticket test + optional result update |
| [create-bug-workflow](skills/create-bug-workflow/SKILL.md) | [WORKFLOW.md](skills/procedures/create-bug-workflow/WORKFLOW.md) | File bugs on Jira/GitHub |
| [catch-ai-workflow](skills/catch-ai-workflow/SKILL.md) | [reference.md](skills/catch-ai-workflow/reference.md) | Audit finished work — sourced defects vs questions, coverage gaps, sourced fix + prevention, pre-delivery second-reviewer pass |
| [tc-review-workflow](skills/tc-review-workflow/SKILL.md) | — (self-contained) | Review an existing TC document against its ticket's AC/EC → traceability matrix, Good vs Need Improve |
| [test-data-prep-workflow](skills/test-data-prep-workflow/SKILL.md) | [WORKFLOW.md](skills/procedures/test-data-prep-workflow/WORKFLOW.md) | Prepare test data on a named environment before testing |
| [review-result-workflow](skills/review-result-workflow/SKILL.md) | [WORKFLOW.md](skills/procedures/review-result-workflow/WORKFLOW.md) | Review recorded test results and evidence before sign-off |
| [tc-change-format-workflow](skills/tc-change-format-workflow/SKILL.md) | — (self-contained) | Copy a ticket's TC tab into the project's release TC template (Google Sheet) |

**Skill layout:** Thin `SKILL.md` stubs (linked into `~/.cursor/skills/`, etc.) point to full procedures in `skills/procedures/*/WORKFLOW.md` — except `catch-ai-workflow`, `tc-review-workflow` and `tc-change-format-workflow`, whose procedures live in their own `SKILL.md`. Claude Code also exposes `/helix`, `/tc-fe-prep`, `/catch-ai`, … via `commands/`.

## Prerequisites (human)

- Command-line tools used by the scripts: `git`, `bash`, `python3` (skill-structure check, CSV/Test.md export), `jq` (opt-in dev setup), `perl` or `shasum` (secret check)

- Jira access to the issues you name
- Browser logged into Jira when posting large comments or UI retests
- Optional workspace guides: `references/*-tc-fe-prep-guide.md`, `*-retest-guide.md`, `*-testing-ticket-guide.md`

## Docs

| Doc | Purpose |
|-----|---------|
| [docs/supported-agents.md](docs/supported-agents.md) | Paths, capabilities, limitations |
| [references/agent-entry.md](references/agent-entry.md) | Per-agent start prompts |
| [references/menu-text.md](references/menu-text.md) | `/helix` menu text (single source) |
| [docs/DOC-MAP.md](docs/DOC-MAP.md) | Where each topic lives |
| [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) | Version bump, hooks, releases |
| [docs/wiki/Home.md](docs/wiki/Home.md) | Wiki entry (mirror to GitHub Wiki) |
| [CONTEXT.md](CONTEXT.md) | Domain glossary |

## Scripts

| Script | Purpose |
|--------|---------|
| [install.sh](scripts/install.sh) | One-time setup: clone, symlinks, `helix@helix-dev`, hooks |
| [helix-auto-update.sh](scripts/helix-auto-update.sh) | `--check`: read release tags and print a notice (SessionStart). No arguments: fast-forward to the newest release, sync (you run it) |
| [claude-plugin-sync.sh](scripts/claude-plugin-sync.sh) | Update/enable `helix@helix-dev`, disable `helix@local` |
| [helix-doctor.sh](scripts/helix-doctor.sh) | Health check; `HELIX_DOCTOR_FIX=1` to repair |
| [link-skills.sh](scripts/link-skills.sh) | Refresh global + workspace skill symlinks |
| [export-markdown-table-to-csv.py](scripts/export-markdown-table-to-csv.py) | TC table → CSV (UTF-8 BOM) |
| [export-test-md.py](scripts/export-test-md.py) | TC table → Test.md (agent-native hand-off) |

Contributor: `bump-version.sh`, `sync-version.sh --check`, `list-skills.sh`, `helix-regression-check.sh` (pre-merge gate via `/helix-check`), `helix-setup-devenv.sh` (retired — `--uninstall` only)

## License

MIT — [LICENSE](LICENSE)
