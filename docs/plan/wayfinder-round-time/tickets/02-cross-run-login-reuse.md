---
type: research
status: closed
assignee: research-agent (session 2026-10-07)
blocked_by: []
---

# Cross-run login reuse

## Question

Can saved Playwright logins (`storageState`) be reused across separate runs and sessions, not only across lanes in one run? If so, under what conditions: where they are stored on disk and how they are protected, how to detect expiry, how OTP and shared inboxes interact with reuse, and what Playwright documents. Today every lane logs in again each run (`references/parallel-test-lanes.md`).

## Resolution

Reuse across separate runs on one operator's machine is safe when four conditions hold: the file is named by env + role + account, it is gitignored at a path from the user's guide, the session endpoint confirms the expected user before any result counts, and a failed check falls back to a fresh login. Reuse across concurrent sessions on one account is unsafe without an account lease that spans sessions. Lane-named files (`parallel-test-lanes.md:24`) block reuse today. Four options (A–D) are weighed in [research/02-login-reuse.md](../research/02-login-reuse.md). The choice between them moves to [Login reuse option](11-login-reuse-option.md), which waits for measured login and OTP time.
