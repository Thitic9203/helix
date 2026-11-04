---
type: research
status: closed
assignee: main-thread (session 2026-11-04)
blocked_by: []
---

# Everything Helix writes outside its clone

## Question

List every file, setting, hook and permission that `install.sh`, `setup.sh`, `helix-auto-update.sh`, `claude-plugin-sync.sh`, `link-skills.sh` and `helix-setup-devenv.sh` create or change outside the clone, with `path:line` for each write. Do the same for the uninstall or undo path, if one exists. For each write, note whether it runs at install, at every SessionStart, or only after the devenv opt-in. This becomes the "what to check / how to undo" part of the team notice.

## Resolution

Full table and the read-only check commands: [research/02-helix-footprint-inventory.md](../research/02-helix-footprint-inventory.md). The main thread re-checked the key lines on 2026-11-04.

- **Install:**
  - clones to `~/.helix/tc-fe-prep`;
  - deletes older plugin cache versions under `~/.claude/plugins/cache/helix-dev/helix/`;
  - symlinks skills into 10 global agent folders. `scripts/link-skills.sh:43-45` runs `rm -rf` on any non-symlink with the same name as a Helix skill, which can delete a user's own skill;
  - registers the plugin through `claude plugin marketplace add/update/install/enable`.
- **Every SessionStart (startup, /clear, compact; synchronous):** runs `git ls-remote` against the remote. When a newer tag exists, or 4 hours have passed, it fetches and then runs `merge --ff-only` to that tag. The only gate is "the tag is an ancestor of origin/main". After that it runs the newly fetched `link-skills.sh`, `claude-plugin-sync.sh` and the git `post-merge` hook in the same session.
- **devenv opt-in:**
  - merges 45 allowlist rules into `~/.claude/settings.json`;
  - sets `defaultMode=acceptEdits` when it is unset;
  - writes a marked block into `~/.claude/CLAUDE.md`;
  - leaves `*.helix-bak.*` backups behind.

  While `~/.helix/.devenv-opted-in` exists, every successful update re-runs the new devenv script without asking (`scripts/helix-auto-update.sh:223-228`).
- **Undo:**
  - The only undo path is `helix-setup-devenv.sh --uninstall` (`:160-167`). It leaves `defaultMode` as it is, keeps the backups, and removes only the rules in the current list.
  - install, setup, link, plugin-sync and auto-update have no undo.
  - Auto-update can be turned off with `HELIX_AUTO_UPDATE=0` (`helix-auto-update.sh:7`).
- **Not checked:** what `claude plugin enable` writes, and where `CLAUDE_PLUGIN_ROOT` points on a marketplace-only install.
