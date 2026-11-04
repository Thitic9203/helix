---
type: grilling
status: open
assignee:
blocked_by: [01-claude-plugin-pinning]
---

# Auto-update policy

## Question

What should happen at session start? Options include: notify only (print "a new release exists"; update by hand); auto-update only to a signed tag that verifies; stay pinned to an installed version until the user runs an update command; or keep today's behaviour as an opt-in. Each option is weighed by what it blocks if upstream is compromised, what it costs the team, and what users do today.
