---
type: grilling
status: open
assignee:
blocked_by: [01]
---

# 15-minute budget

## Question

The user set a hard cap: every round finishes within 15 minutes. Given the measured baseline, how is those 15 minutes divided across phases, per flow (retest, test task, test story, smoke)?

Four points need deciding:

1. Whether human wait time counts against the cap.
2. Which steps are must-keep, and which are skip candidates. Each candidate is shown with its measured cost and what it would stop catching, and the user decides.
3. What happens when a round's scope cannot fit, for example a story with many screens: split it into several rounds, cut scope with approval, or stop and report.
4. How the workflow tracks the remaining budget while it runs.
