---
type: research
status: open
assignee:
blocked_by: []
---

# Everything Helix writes outside its clone

## Question

List every file, setting, hook and permission that `install.sh`, `setup.sh`, `helix-auto-update.sh`, `claude-plugin-sync.sh`, `link-skills.sh` and `helix-setup-devenv.sh` create or change outside the clone, with `path:line` for each write. Do the same for the uninstall or undo path, if one exists. For each write, note whether it runs at install, at every SessionStart, or only after the devenv opt-in. This becomes the "what to check / how to undo" part of the team notice.
