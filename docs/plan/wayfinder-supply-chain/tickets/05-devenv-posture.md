---
type: grilling
status: closed
assignee: main-thread (session 2026-11-04)
blocked_by: [02-helix-footprint-inventory]
---

# setup-devenv posture

## Question

Which allowlist entries stay, if any? `npx *`, `node *`, `python3 *`, `gh api *` and `bash scripts/*` each allow arbitrary code. Does `defaultMode: acceptEdits` stay? Should the "ask less" block move from the global `~/.claude/CLAUDE.md` to the project's own CLAUDE.md, or be dropped? Should auto-update stop re-syncing these after the opt-in?

## Resolution

Decided with the owner on 2026-11-04: **retire `scripts/helix-setup-devenv.sh`, and give machines that already opted in a full undo.** The undo must:

- remove every allowlist rule Helix ever added, not only those in the current list;
- remove the managed block from the global `~/.claude/CLAUDE.md`;
- restore `defaultMode` if Helix set it;
- remove `~/.helix/.devenv-opted-in`.

`helix-auto-update.sh` stops re-running devenv (today at `:223-228`). The gaps in today's `--uninstall` are listed in [research 02](../research/02-helix-footprint-inventory.md).
