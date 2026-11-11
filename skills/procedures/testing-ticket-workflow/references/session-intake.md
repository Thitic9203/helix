# Session intake — Testing ticket

Collect these before any Playwright run.

## Ticket

- Jira key (`PROJ-123`) or full browse URL.
- This issue is the **scope anchor** — test what the ticket describes; do not expand to unrelated modules unless the user asks.

## URL

- Full base URL for the environment under test (e.g. `https://portal.example.com`).
- Not the Jira URL — the **application** URL.

## User (account only — no password)

- The test account (username/email). Use `guest` when the ticket is explicitly unauthenticated.
- Login by command, never a login window or a password — stated once at [WORKFLOW.md](../WORKFLOW.md) Phase D *Fresh login*.
- Record the account names, the env, the URLs and the relink/mint command templates (`<project-dir>`, `<env>`, `<account>`) when the project guide does not name them. Never record a password.

## VPN

- **Required** — User must connect before tests; note any profile or split-tunnel quirks.
- **Not required** — Public or office network only.
- If tests fail with network errors after VPN was marked required, re-check VPN first.

## Confluence

- A page with AC tables, API notes, or test data, when the user has one.
- `none` if all context is on the Jira ticket.

## Swagger

- An OpenAPI/Swagger URL for API scenarios tied to the ticket, when the user has one.
- `none` if UI-only.

## Confirmation gate

🔴 GATE: the agent must show all six fields (or explicit `none`) plus a derived test plan and receive the user's **confirm** before the first Playwright run ([WORKFLOW.md](../WORKFLOW.md) Phase C; the testing-ticket exception in round-time-contract §2).
