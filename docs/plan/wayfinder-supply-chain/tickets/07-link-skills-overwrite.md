---
type: grilling
status: closed
assignee: main-thread (session 2026-11-04)
blocked_by: []
---

# link-skills must not delete a user's own skill

## Question

`scripts/link-skills.sh:43-45` runs `rm -rf` on any non-symlink in a global skill folder whose name matches a Helix skill, at install and at every update. The owner put this in scope on 2026-11-04. What should happen on a name clash: skip and warn, move the user's folder to a backup and say where, or stop the install? Does the team notice tell users to check whether something was already deleted?

## Resolution

Decided with the owner on 2026-11-04: **skip and warn.** On a name clash with a real (non-symlink) folder, `link-skills.sh` leaves the user's folder alone and does not link that Helix skill. It prints the clashing name, its path, and how to resolve the clash. It never runs `rm -rf` on anything it did not create. The team notice asks users to check whether a same-named skill of theirs was already replaced.
