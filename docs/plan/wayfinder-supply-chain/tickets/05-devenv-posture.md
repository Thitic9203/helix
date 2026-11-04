---
type: grilling
status: open
assignee:
blocked_by: [02-helix-footprint-inventory]
---

# setup-devenv posture

## Question

Which allowlist entries stay, if any? `npx *`, `node *`, `python3 *`, `gh api *` and `bash scripts/*` each allow arbitrary code. Does `defaultMode: acceptEdits` stay? Should the "ask less" block move from the global `~/.claude/CLAUDE.md` to the project's own CLAUDE.md, or be dropped? Should auto-update stop re-syncing these after the opt-in?
