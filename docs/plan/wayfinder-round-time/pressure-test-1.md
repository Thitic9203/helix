# Pressure test 1: a testing-ticket round under the round-time contract

This file records one real round of `testing-ticket-workflow` on a story, run on 2026-10-07. The round followed the workflow on branch `feat/round-time-spec`. The story, the product, and the hosts are deliberately left out because this repo is public.

## The round

- **Scope:** 1 story with 14 AC and 1 EC. The QA sheet lists 29 test cases for it: System, Unit and Integration.
- **Result:** all 29 were run. 24 PASSED and 5 FAILED. Each failure has a confirmed root cause with a `path:line` in the product source.
- **Lanes:**
  - **L1:** CMS cases on the one privileged account.
  - **L2:** media prep. It created the rejected and pending items that the integration cases need.
  - **L3:** toggle, rename and integration cases.
  - L1 and L2 ran in parallel. L3 ran after both.

## Measured round time

Taken from the session's own timestamps.

| | Minutes |
|---|---|
| Total | 44.1 |
| Human wait | 0.7 (one intake popup) |
| AGENT + EXEC | 43.4 |
| Overrun past the 15-minute cap | 28.4 |
| Of AGENT + EXEC: main thread idle while the lanes ran | 32.8 |

Human touchpoints this round: 1 intake popup during the run. The baseline median for testing rounds was 4, with a median human wait of 17–18 min. The plan ran without waiting, and no question was asked mid-run.

**Verdict on the cap:** a story with 29 cases did not fit in 15 minutes. The lanes alone took about 33 min, because the privileged-account chain was serial. This matches the "Honest outlook" in SPEC §1.

## Findings → proposed follow-ups

| # | Finding | Evidence | Follow-up |
|---|---|---|---|
| 1 | The testing-ticket discovery stub still required the user to confirm the plan, which contradicts contract §2 | `skills/testing-ticket-workflow/SKILL.md` | **Fixed** in `10a9147` |
| 2 | Fan-out was capped by **accounts**. Only one account had the privileged role, so 29 cases ran as one serial chain plus one prep lane | lane timings: L1 10.6 min, L3 19.5 min | Contract §4: on intake, report how many accounts each role has and the serial chain this forces, so the user can add accounts before the run |
| 3 | **Cross-lane data dependency.** The prep lane had to poll until the CMS lane created the records it needed. Barrier units (lanes §2) do not model this "lane B waits for lane A's output" case | L2 poll log, 13 polls | Contract §4: add a "producer → consumer" unit rule that runs the consumer after the producer, or makes it poll with a timeout, as L2 did |
| 4 | **The Figma compare was blocked while on VPN.** The design site returned 403 through the VPN egress, and the in-app browser needed a login the agent may not perform | `403 Request blocked` | Contract §7: capture design exports **before** connecting the VPN (or cache them by `lastModified` from a previous round), then run the app on the VPN |
| 5 | The login-reuse file name in contract §5 differs from the project's existing e2e harness (`state/{env}_{account}.json`, minted by its setup project) | harness `accounts.ts` `stateFileFor` | Contract §5: "use the project harness's own saved-state files when it has them"; the naming rule applies only when no harness exists |
| 6 | Intake had to look up the privileged role in product source, because the ticket says "Admin" and names no role. The guide had no role → permission map | reject-reason controller `@Roles(SYSTEM_ADMIN)` | Save the role found to the guide (contract §2) so the next round does not repeat the lookup |
| 7 | An early status line claimed the round had passed 15 min before anything was measured. It was corrected | session transcript | Already covered: contract §1 says the numbers are measured, never estimated. Reinforce it in the soft-cap line |

## Not exercised this round

- **End decisions popup and approval popup.** The user ran this round under a "do not ask, do not wait" goal, so the queued decisions and outward writes (Jira comment, sheet update) were left pending, not asked.
- **Retest round N and smoke.**
