---
type: grilling
status: closed
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

## Resolution

Decided with the user on 2026-10-07, using [research/13-per-gate-timing.md](../research/13-per-gate-timing.md): of the comment edits, 34 of 74 changed media references and 41 of 74 changed table markers, and edits came a median 1.9 min after the post. **Before posting, check both rendering and media.** Render the ADF or wiki body locally and confirm the tables and formatting. Confirm every referenced image or clip resolves, meaning the attachment exists and the id matches. Both checks run on the final body inside the end-of-round approval bundle, so the user approves a body that has already been checked. The post-publish re-read stays as the evidence that the comment was posted.
