---
type: grilling
status: open
assignee:
blocked_by: []
---

# Comment render check

## Question

81 comment edits follow a pattern: the agent posts, notices broken rendering, media or tables within about 2 min, and re-PUTs the whole body. 11 retest runs had 3 or more edits each. What check before posting removes this loop? Candidates:

- render the ADF or wiki body locally first;
- verify every media reference resolves before the post;
- move the post-publish re-read into a pre-publish check;
- fold this into the end-of-round approval bundle from [Approvals vs decisions](04-approvals-vs-decisions.md).

The evidence is in [research/13-per-gate-timing.md](../research/13-per-gate-timing.md).
