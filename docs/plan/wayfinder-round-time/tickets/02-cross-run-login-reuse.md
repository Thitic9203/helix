---
type: research
status: open
assignee:
blocked_by: []
---

# Cross-run login reuse

## Question

Can saved Playwright logins (`storageState`) be reused across separate runs and sessions, not only across lanes in one run? If so, under what conditions: where they are stored on disk and how they are protected, how to detect expiry, how OTP and shared inboxes interact with reuse, and what Playwright documents. Today every lane logs in again each run (`references/parallel-test-lanes.md`).
