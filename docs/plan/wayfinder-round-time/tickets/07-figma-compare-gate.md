---
type: grilling
status: open
assignee:
blocked_by: [01, 10]
---

# Figma compare gate

## Question

Given the measured cost from the baseline, what is the minimal Figma comparison that still meets the evidence standard? Today the workflow compares every UI case, including passing ones, every round (retest :308, testing :249). Options to weigh include changed screens only, cached reference exports, and one compare per screen rather than per case. The answer must fit the allocation set by [15-minute budget](10-fifteen-minute-budget.md). Any part the user chooses to skip is recorded as an accepted risk.
