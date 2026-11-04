# 02 — Helix footprint inventory (writes outside the clone)

Read at worktree commit `f82b359` (origin/main). Read-only review; nothing was run.
`$REPO_DIR` = `${HELIX_REPO_DIR:-$HOME/.helix/tc-fe-prep}` (scripts/install.sh:14).
`$CACHE_BASE` = `~/.claude/plugins/cache/helix-dev/helix` (scripts/install.sh:18, scripts/setup.sh:16).

## Writes table

| What is written | Where (~/ paths) | Written by path:line | When | Undo path:line or "none" |
|---|---|---|---|---|
| Git clone of the repo (or `git pull origin main` on an existing clone) — network fetch, no pin/checksum | `~/.helix/tc-fe-prep` (override `HELIX_REPO_DIR`) | scripts/install.sh:24-31 | At install (and every re-run of install.sh) | none |
| Delete every existing version dir under the plugin cache (`rm -rf`) | `~/.claude/plugins/cache/helix-dev/helix/*/` | scripts/install.sh:45-49; scripts/setup.sh:21-25 | At install / setup.sh | none |
| Symlink `<VERSION>` → clone | `~/.claude/plugins/cache/helix-dev/helix/<VERSION>` | scripts/install.sh:50; scripts/setup.sh:26 | At install / setup.sh | none |
| Runs `scripts/sync-version.sh` (writes not inventoried — script out of scope) | unclear: sync-version.sh not read (scope bound); assumed in-clone only, unverified | scripts/install.sh:42; scripts/setup.sh:18 | At install / setup.sh | unclear |
| Repo-local git config `core.hooksPath=scripts/hooks` (inside clone's `.git/config`, but makes `scripts/hooks/*` run on every commit/push/merge in that clone) | `$REPO_DIR/.git/config` | scripts/install.sh:61; scripts/setup.sh:28 | At install / setup.sh | none |
| Runs link-skills.sh (see its rows) | see link-skills.sh rows | scripts/install.sh:57; scripts/setup.sh:29 | At install / setup.sh | see below |
| Runs claude-plugin-sync.sh, failures ignored (`\|\| true`) (see its rows) | see claude-plugin-sync.sh rows | scripts/install.sh:65 | At install (not setup.sh) | see below |
| One symlink per shippable skill (`<name>` → clone `skills/.../<name>`; excludes `in-progress/` and `procedures/`) — only if the parent dir (e.g. `~/.claude`) already exists | `~/.claude/skills/<name>`, `~/.cursor/skills/<name>`, `~/.codex/skills/<name>`, `~/.copilot/skills/<name>`, `~/.gemini/skills/<name>`, `~/.agents/skills/<name>`, `~/.codeium/windsurf/skills/<name>`, `~/.cline/skills/<name>`, `~/.config/opencode/skills/<name>`, `~/.pi/agent/skills/<name>` | scripts/link-skills.sh:62-79 (list), :18 (parent-exists gate), :31 (`mkdir -p` skills dir), :53 (`ln -sfn`) | At install / setup.sh; also whenever link-skills.sh is re-run (see post-merge hook below) | none |
| **Deletes** any existing non-symlink file/dir that has the same name as a Helix skill (`rm -rf`) — can remove a user's own skill of that name | same skill dirs as above | scripts/link-skills.sh:43-45 | Same as above | none |
| Workspace symlinks (opt-in `HELIX_LINK_WORKSPACE=<project>`) — writes into the user's project, plus same `rm -rf` of same-name non-symlinks | `<project>/.github/skills/<name>`, `<project>/.agents/skills/<name>`, `<project>/.windsurf/skills/<name>`, `<project>/.cline/skills/<name>`, `<project>/.gemini/skills/<name>` | scripts/link-skills.sh:82-105 (+ :43-45, :53) | Only when `HELIX_LINK_WORKSPACE` is set (install.sh:54-56 passes it through) | none |
| Claude Code marketplace registration `helix-dev` from GitHub `<owner>/helix` (network fetch by `claude` CLI, no pin) | Claude Code plugin state under `~/.claude/plugins/` — unclear: exact files are written by the `claude` CLI, not by this script | scripts/claude-plugin-sync.sh:44-47 | At install (install.sh:65); also post-merge hook and doctor fix (header comment :5 — callers not verified beyond install.sh/post-merge in scope) | none (no `marketplace remove` anywhere in this script) |
| `claude plugin marketplace update helix-dev` (network fetch) | same as above | scripts/claude-plugin-sync.sh:50 | Same as above | none |
| `claude plugin install` / `claude plugin update helix@helix-dev` (network fetch) | same as above (plugin install + cache managed by CLI) | scripts/claude-plugin-sync.sh:52-60 | Same as above | none |
| `claude plugin enable helix@helix-dev` (enabled-plugins setting, written by CLI — unclear which settings file) | unclear: the `claude` CLI chooses the settings file; not determined from these scripts | scripts/claude-plugin-sync.sh:63 | Same as above | none |
| `claude plugin disable helix@local` if present | same | scripts/claude-plugin-sync.sh:67-70 | Same as above | none |
| **Deletes** stale cache (`rm -rf`) | `~/.claude/plugins/cache/local/helix` | scripts/claude-plugin-sync.sh:72-76 | Same as above | none |
| Auto-update state dir | `~/.helix/` (override `HELIX_STATE_DIR`) | scripts/helix-auto-update.sh:16, :195 | Every SessionStart (unless `HELIX_AUTO_UPDATE=0`) | none |
| Timestamp of last check | `~/.helix/.last-auto-update-check` | scripts/helix-auto-update.sh:17, :86-89, :199 | Every SessionStart that passes the interval/new-release gate (:196) | none |
| Update log (append) | `~/.helix/auto-update.log` | scripts/helix-auto-update.sh:18, :28-34, :115, :119, :135, :179, :227 | Every SessionStart that logs anything | none |
| Error notice (append; removed after a clean run) | `~/.helix/last-update-error` | scripts/helix-auto-update.sh:20, :36-41 (write), :231-233 (`rm -f`) | Every SessionStart with a failing step | self-clearing on next clean run (:231-233) |
| `git ls-remote --tags` of origin (network, read-only probe of the tag list) | no file write | scripts/helix-auto-update.sh:73-77, called from :66 | Every SessionStart inside the 4 h interval (`HELIX_AUTO_UPDATE_INTERVAL_SEC`, default 14400, :22) | n/a |
| `git fetch origin main` + force-update local tags `+refs/tags/v*:refs/tags/v*` (network) | clone `$REPO_DIR/.git` (refs, objects) | scripts/helix-auto-update.sh:135 | Every SessionStart once the interval passed or a newer release tag exists | none |
| Fast-forward the clone's checked-out branch to newest `vX.Y.Z` tag that is an ancestor of origin/main (new code from network becomes live; no signature/checksum check — only tag + ancestry) | `~/.helix/tc-fe-prep` working tree | scripts/helix-auto-update.sh:140-148 (tag pick), :163 (`merge --ff-only`) | Every SessionStart that finds a newer release | none (manual `git -C ~/.helix/tc-fe-prep reset` only) |
| Cache symlink `<VERSION>` → clone (old version dirs are NOT removed here, unlike install.sh) | `~/.claude/plugins/cache/helix-dev/helix/<VERSION>` | scripts/helix-auto-update.sh:103-109, called at :155 and :113 | Every SessionStart that reaches the clone-version check | none |
| Runs the **newly fetched** `link-skills.sh` from the clone (all link-skills rows above) | see link-skills.sh rows | scripts/helix-auto-update.sh:114-117 | Every SessionStart that fast-forwarded to a new release | none |
| Runs the **newly fetched** `claude-plugin-sync.sh` (all claude-plugin-sync rows above) | see claude-plugin-sync.sh rows | scripts/helix-auto-update.sh:118-121 | Same as above | none |
| No-clone path: `curl` raw `VERSION` from GitHub main (network), then runs `$REPO/scripts/claude-plugin-sync.sh` if it exists | see claude-plugin-sync.sh rows | scripts/helix-auto-update.sh:23, :91-93, :214-220, :172-188 | Every SessionStart without a clone (gate as above) | none |
| Re-runs the **newly fetched** `helix-setup-devenv.sh` (all devenv rows below) | see helix-setup-devenv.sh rows | scripts/helix-auto-update.sh:223-228 | Every SessionStart that updated AND marker `~/.helix/.devenv-opted-in` exists | see devenv `--uninstall` |
| Creates `settings.json` as `{}` if missing | `~/.claude/settings.json` (override `CLAUDE_CONFIG_DIR`) | scripts/helix-setup-devenv.sh:21-22, :83-84 | Only after devenv opt-in (manual run); re-run at SessionStart after an update while opted in (helix-auto-update.sh:225-227) | `--uninstall` does not delete the file (:96-107) |
| Merges 45 `permissions.allow` rules (incl. `Bash(npx *)`, `Bash(node *)`, `Bash(python3 *)`, `Bash(bash scripts/*)`, `Bash(gh api *)`, `Bash(git commit *)`, `Bash(find *)`) — union with existing, deduped | `~/.claude/settings.json` → `.permissions.allow` | scripts/helix-setup-devenv.sh:29-43 (list), :88-92 (jq merge) | Same as above | scripts/helix-setup-devenv.sh:96-107 via `--uninstall` (:161-163) — removes only the rules in the **current** script's list; rules added by an older/newer version that are no longer in the list stay; also removes a matching rule the user had added themselves before opt-in |
| Sets `permissions.defaultMode = "acceptEdits"` **only if no defaultMode is set** | `~/.claude/settings.json` → `.permissions.defaultMode` | scripts/helix-setup-devenv.sh:90 | Same as above | none — uninstall deliberately leaves it (:106, :166) |
| Timestamped backup copy of settings.json (accumulates, one per run) | `~/.claude/settings.json.helix-bak.<YYYYmmddHHMMSS>` | scripts/helix-setup-devenv.sh:74-79, called :85 (and :99 on uninstall) | Every devenv run incl. each SessionStart re-sync and uninstall | none (backups never deleted, :166) |
| Creates `CLAUDE.md` if missing; inserts/replaces marker block `HELIX-DEVENV:START…END` containing "Bias toward action — do, ask less" + "Memory discipline" rules | `~/.claude/CLAUDE.md` | scripts/helix-setup-devenv.sh:26-27 (markers), :45-62 (text), :109-136 (write) | Same as settings rows | scripts/helix-setup-devenv.sh:138-158 via `--uninstall` (:164) — removes the marker block; file left in place |
| Timestamped backup copy of CLAUDE.md (accumulates) | `~/.claude/CLAUDE.md.helix-bak.<YYYYmmddHHMMSS>` | scripts/helix-setup-devenv.sh:74-79, called :112 (and :141 on uninstall) | Every devenv run / uninstall | none |
| Opt-in marker (epoch timestamp) — this file is what makes every later SessionStart update re-run the devenv script | `~/.helix/.devenv-opted-in` (override `HELIX_STATE_DIR`) | scripts/helix-setup-devenv.sh:24-25, :172 | Only after devenv opt-in | scripts/helix-setup-devenv.sh:165 (`--uninstall`) |
| Registers a Claude Code `SessionStart` hook (matcher `startup\|clear\|compact`, synchronous `async:false`) that runs `${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd session-start` | Takes effect wherever the plugin is installed/enabled (plugin manifest, not a user settings write) | hooks/hooks.json:3-13 | Every SessionStart (startup, `/clear`, compaction) while plugin `helix@helix-dev` is enabled | `claude plugin disable helix@helix-dev` / uninstall (CLI; no Helix script does this) |
| `run-hook.cmd` — polyglot wrapper; on Unix `exec bash <hooks-dir>/session-start`; on Windows runs it via Git Bash or `bash` on PATH | no file write | hooks/run-hook.cmd:31-34 (Unix), :11-27 (Windows) | Every SessionStart | n/a |
| Runs `helix-auto-update.sh` (all auto-update rows above), errors suppressed (`2>/dev/null \|\| true`) | see auto-update rows | hooks/session-start:9-15 | Every SessionStart unless `HELIX_AUTO_UPDATE=0` (helix-auto-update.sh:43-48, :191-193) | none |
| Devenv notice counter | `~/.helix/.devenv-notice-count` | hooks/session-start:29-41 (write :38-39) | First 3 SessionStarts while not opted in (unless `HELIX_DEVENV_NOTICE=0`) | none |
| Injected model context (not a file): the slash-command table, plus — first 3 sessions — a "Helix tip" telling the agent to suggest running `helix-setup-devenv.sh` to the user, plus last auto-update error, plus a branch-name hint | Claude Code session context | hooks/session-start:17-23, :29-41 (tip text :37), :46-54, :56-64 | Every SessionStart | `HELIX_DEVENV_NOTICE=0`, `HELIX_PROACTIVE=0` env vars silence parts; none for the rest |
| Renames the dev cache symlink `<oldVER>` → `<VERSION>` (symlinks only) | `~/.claude/plugins/cache/helix-dev/helix/<VERSION>` | scripts/hooks/post-merge:7-9, :25-33 | After every `git merge`/`git pull` in the clone (enabled by `core.hooksPath`, install.sh:61). Git runs post-merge after a fast-forward `git merge` too, so the SessionStart ff at helix-auto-update.sh:163 also fires it (git hook semantics, not a line in these files) | none |
| Runs `scripts/claude-plugin-sync.sh` from the clone (all plugin-sync rows above) | see claude-plugin-sync.sh rows | scripts/hooks/post-merge:35-39 | Same as above | none |
| pre-commit: secret scan of staged blobs into a `mktemp -d` dir (removed on exit), version bump inside the clone | system temp dir only; no `~/` write | scripts/hooks/pre-commit:15-29 (temp, `trap rm`), :46-52 | On `git commit` in the clone (contributors only) | self-cleaning (:18) |
| pre-push: whole-repo secret scan | no write outside the clone found in this file | scripts/hooks/pre-push:6-7 | On `git push` in the clone (contributors only) | n/a |

### Undo paths — summary

- **Only one undo path exists in the scoped files:** `bash ~/.helix/tc-fe-prep/scripts/helix-setup-devenv.sh --uninstall` (scripts/helix-setup-devenv.sh:160-167). It removes the current allowlist rules, the CLAUDE.md marker block and the opt-in marker. It does **not** revert `defaultMode` (:106, :166), does not delete the `*.helix-bak.*` backups, and cannot remove rules that an older or newer version added but the current list no longer has.
- **No uninstall** exists in install.sh, setup.sh, link-skills.sh, claude-plugin-sync.sh or helix-auto-update.sh (no `remove`/`uninstall`/`unlink` path in any of them). Removing the clone, cache symlink, skill symlinks, plugin and marketplace is manual.
- Kill switch for the SessionStart network update: env `HELIX_AUTO_UPDATE=0` (helix-auto-update.sh:7, :43-48). It must be in the environment Claude Code launches the hook with; how a user sets that persistently is not defined in these files.

## What runs at every session start

1. Claude Code fires `SessionStart` (startup, `/clear`, compaction) → `${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd session-start`, synchronous (hooks/hooks.json:5-10).
2. `run-hook.cmd` execs `bash <plugin root>/hooks/session-start` (hooks/run-hook.cmd:31-34).
3. `session-start` runs `helix-auto-update.sh` **from the plugin root** (`${PLUGIN_ROOT}/scripts/…`, hooks/session-start:7, :10-12), with `HELIX_REPO_DIR` defaulting to `~/.helix/tc-fe-prep`; falls back to the script inside `~/.helix/tc-fe-prep` only if the plugin root has none (:13-14). Which checkout `CLAUDE_PLUGIN_ROOT` is: unclear from these files — for an install.sh user the cache entry is a symlink to the clone (install.sh:50), so it is the clone; for a marketplace-only install it is whatever copy the `claude` CLI manages.
4. `helix-auto-update.sh` (exits early if `HELIX_AUTO_UPDATE=0`):
   - **Network every session** when inside the 4 h interval: `git ls-remote --tags origin 'v*'` (helix-auto-update.sh:63-66, :73-77).
   - **Network + code change** when the interval passed or a newer tag exists: `git fetch origin main` + forced tag update (:135), then `git merge --ff-only <newest vX.Y.Z on origin/main>` (:140-163). Only gate is "tag exists and is an ancestor of origin/main" (:145) — no signature or checksum.
   - After a successful fast-forward it runs the **just-fetched** `link-skills.sh` and `claude-plugin-sync.sh` from the clone (:111-122) — the latter makes more network calls through the `claude` CLI (marketplace update, plugin update). The post-merge git hook (also just-fetched) fires as well and runs `claude-plugin-sync.sh` again (scripts/hooks/post-merge:35-39).
   - If `~/.helix/.devenv-opted-in` exists, it then runs the **just-fetched** `helix-setup-devenv.sh`, which rewrites `~/.claude/settings.json` permissions and `~/.claude/CLAUDE.md` (:223-228). So new allowlist content reaches opted-in users with no prompt.
   - No-clone installs: `curl` of `VERSION` from GitHub `main` (not a release tag) (:23, :91-93, :215), then `claude-plugin-sync.sh` (:172-181).
   - All stderr is discarded by the caller (hooks/session-start:12, :14); failures only surface via `~/.helix/last-update-error`.
5. `session-start` writes `~/.helix/.devenv-notice-count` (first 3 sessions) and prints the injected context JSON (hooks/session-start:29-64).
6. Out of scope but present: `hooks/hooks-cursor.json` (Cursor hook config) — not read.

## How a user can check their machine (read-only)

```bash
# 1. Clone and its current release
ls -la ~/.helix/ 2>/dev/null
git -C ~/.helix/tc-fe-prep describe --tags 2>/dev/null; git -C ~/.helix/tc-fe-prep config --get core.hooksPath
cat ~/.helix/tc-fe-prep/VERSION 2>/dev/null

# 2. Auto-update activity and state
ls -la ~/.helix/.last-auto-update-check ~/.helix/auto-update.log ~/.helix/last-update-error ~/.helix/.devenv-notice-count 2>/dev/null
tail -n 40 ~/.helix/auto-update.log 2>/dev/null
echo "HELIX_AUTO_UPDATE=${HELIX_AUTO_UPDATE:-<unset = ON>}"

# 3. Devenv opt-in (the global-settings change)
ls -la ~/.helix/.devenv-opted-in 2>/dev/null && echo "DEVENV OPTED IN"
jq '.permissions.defaultMode, .permissions.allow' ~/.claude/settings.json 2>/dev/null
grep -n 'HELIX-DEVENV' ~/.claude/CLAUDE.md 2>/dev/null
ls -la ~/.claude/settings.json.helix-bak.* ~/.claude/CLAUDE.md.helix-bak.* 2>/dev/null

# 4. Plugin cache and Claude Code plugin/marketplace
ls -la ~/.claude/plugins/cache/helix-dev/helix/ 2>/dev/null
claude plugin marketplace list 2>/dev/null | grep -n helix
claude plugin list 2>/dev/null | grep -n -A3 helix

# 5. Skill symlinks pointing into the clone (all agent dirs link-skills.sh touches)
for d in ~/.claude/skills ~/.cursor/skills ~/.codex/skills ~/.copilot/skills ~/.gemini/skills \
         ~/.agents/skills ~/.codeium/windsurf/skills ~/.cline/skills ~/.config/opencode/skills ~/.pi/agent/skills; do
  [ -d "$d" ] && find "$d" -maxdepth 1 -type l -lname '*.helix*' -exec ls -l {} \;
done

# 6. Optional workspace links (run inside a project)
for d in .github/skills .agents/skills .windsurf/skills .cline/skills .gemini/skills; do
  [ -d "$d" ] && find "$d" -maxdepth 1 -type l -exec ls -l {} \;
done
```

Note: step 5's `-lname '*.helix*'` matches links into `~/.helix/…`; a custom `HELIX_REPO_DIR` needs its own pattern. Workspace links made with `WS_RELATIVE=1` point to `../../skills/<name>` (link-skills.sh:47-48) and are listed by step 6 without a filter.
