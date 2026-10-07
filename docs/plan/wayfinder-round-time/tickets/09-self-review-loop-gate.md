---
type: grilling
status: open
assignee:
blocked_by: [01, 10]
---

# Self-review loop gate

## Question

Given the measured cost from the baseline, what is the minimal self-review structure that still catches what it is meant to catch? Today the reviewer subagent repeats rounds with no cap (retest 6c), the guard runs twice (draft and posted), and the pre-delivery gate opens every evidence file. Which runs are redundant with each other, and which need to stay? The answer must fit the allocation set by [15-minute budget](10-fifteen-minute-budget.md). Any part the user chooses to skip is recorded as an accepted risk.
