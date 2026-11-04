---
type: grilling
status: closed
assignee: main-thread (session 2026-11-04)
blocked_by: [01-claude-plugin-pinning]
---

# Auto-update policy

## Question

What should happen at session start? Options include: notify only (print "a new release exists"; update by hand); auto-update only to a signed tag that verifies; stay pinned to an installed version until the user runs an update command; or keep today's behaviour as an opt-in. Each option is weighed by what it blocks if upstream is compromised, what it costs the team, and what users do today.

## Resolution

Decided with the owner on 2026-11-04: **notify only.** At session start, Helix only reports that a newer release exists, and nothing new runs on its own. The user updates with an explicit command. No new code is fetched or run inside the session-start hook.

The owner chose the recommended option. It closes risk 2 from the lead's feedback, which [research 02](../research/02-helix-footprint-inventory.md) confirmed: the only gate today is "the tag is on origin/main". Accepted trade-off: teammates no longer get a new version on their next session automatically. The owner asked for that on 2026-10-20; this decision replaces it.
