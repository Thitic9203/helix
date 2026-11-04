---
type: grilling
status: open
assignee:
blocked_by: []
---

# link-skills must not delete a user's own skill

## Question

`scripts/link-skills.sh:43-45` runs `rm -rf` on any non-symlink in a global skill folder whose name matches a Helix skill, at install and at every update. The owner put this in scope on 2026-11-04. What should happen on a name clash: skip and warn, move the user's folder to a backup and say where, or stop the install? Does the team notice tell users to check whether something was already deleted?
