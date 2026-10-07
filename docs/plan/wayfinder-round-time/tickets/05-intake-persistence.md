---
type: grilling
status: open
assignee:
blocked_by: []
---

# Intake persistence

## Question

What intake and context should persist between rounds, so that round N does not ask again or re-read from scratch? Candidates: per-project config (env, accounts, Jira format) in the workspace guide, and per-ticket state (case list, AC/EC list, Figma node refs, Swagger version, last-round results). Where does it live, what invalidates it (ticket edited, new build, design changed), and how is staleness detected?

Also covers the pre-answerable items found in [Approvals vs decisions](04-approvals-vs-decisions.md): retest first-time config (1b), transition names (8a), notify recipient field (Step 9), and testing results destination (G1/G2).
