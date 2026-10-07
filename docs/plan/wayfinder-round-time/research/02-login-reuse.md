# Research: cross-run login reuse

Resolves [Cross-run login reuse](../tickets/02-cross-run-login-reuse.md). Sources were read 2026-10-07. Repo line numbers are as of `dc3c252`; the main thread spot-checked lines 24, 80-82 and 88 of `parallel-test-lanes.md`, line 14 of `portable-content.md` and line 8 of `playwright-preflight.md`.

## Answer

**Reuse across separate runs on one operator's machine: yes.** This is Playwright's documented pattern: save the login in a gitignored `playwright/.auth` folder and reuse it, and delete it when it expires. It is safe only when all four of these hold:

1. The file is named by environment + role + account alias.
2. It sits in a gitignored folder whose path comes from the user's guide.
3. Before any result counts, the run calls the app's session endpoint and confirms it returns the expected user id.
4. If that check fails, the run logs in fresh and overwrites the file.

**Reuse across concurrent sessions sharing one account: no.** Two browsers on one login break each other in the same way that `references/parallel-test-lanes.md:80-82` already forbids between lanes. Sharing across sessions is only safe with an account lease that spans sessions and has an owner and a time limit.

## Facts

**What the file holds:**
- Cookies (with Unix expiry times) and localStorage are always saved.
- IndexedDB, the browser's private file storage, and passkeys (including private keys) are saved only when explicitly enabled.
- sessionStorage is not saved.

**Security:**
- Playwright warns the file can be used to impersonate the account, and says never to commit it.
- OWASP: deleting a cookie locally does not cancel a stolen copy.
- Keep it gitignored, and do not enable the optional extra storage unless the login needs it.

**Expiry:**
- Playwright has no API to check whether a saved login is still valid.
- A cheap check: cookie expiry is only a hint, so call the session endpoint and expect a 200 response with the expected user id. Otherwise, log in fresh.
- Helix already has the session check, at `references/customer-escape-prevention.md:169-180` and testing `WORKFLOW.md:211-220`.

**OTP:**
- That a valid saved login skips the OTP prompt is an *inference*, not documented. Confirm it per project.
- A new login can rotate the session id, which invalidates other copies of that account's file.

**Current naming blocks reuse:**
- Files are named by lane id (`parallel-test-lanes.md:24`, `:88`, `:135`), and the account assigned to a lane can change between runs.
- Naming files by account fixes this.

**Portable content:**
- Skill text has to use a placeholder such as `{auth dir from guide}/{env}-{role}-{alias}.json` (`references/portable-content.md:9-14`, `:36-40`).
- The preflight checklist already has an "auth file path" slot (`references/playwright-preflight.md:8`).

## Options for the decision

No option has a measured time saving yet. Login and OTP time comes from [Baseline phase timing](../tickets/01-baseline-phase-timing.md).

| Option | Gain | Cost / risk |
|---|---|---|
| A. Fresh login every run (today) | Simplest; no login file outlives the run | Login and OTP every run; shared-inbox logins happen one at a time |
| B. Reuse per operator across runs (files named by account, session check, fresh-login fallback) | Skips login and OTP while the session stays valid; matches Playwright's guidance | Rename the lane files, add a guide slot and a preflight step; a credential file stays on disk between runs |
| C. B plus a cross-session account lease | Biggest saving when several sessions run at once | Lock design and recovery from stale locks; a lease bug looks like a product defect |
| D. Cheap fresh login through the API (`request.post` + `request.storageState()`) | No login file kept between runs | Only works for accounts with no OTP or captcha and an API login |

## Sources

- https://playwright.dev/docs/auth
- https://playwright.dev/docs/api/class-browsercontext
- https://playwright.dev/docs/api/class-testconfig
- https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
