---
type: grilling
status: open
assignee: main-thread (session 2026-10-07 c)
blocked_by: [01]
---

# Login reuse option

## Question

Which login strategy should the workflows use: A (fresh login every run), B (reuse per operator across runs), C (B plus a cross-session account lease), or D (cheap fresh login through the API)? The answer may be a mix per account type, for example D for accounts without OTP and B for accounts with OTP. Weigh it against the measured login and OTP time from the baseline and the 15-minute cap. The facts and trade-offs are in [research/02-login-reuse.md](../research/02-login-reuse.md).

## Framing (pre-baseline, no recommendation yet)

The options and their facts are already in [research/02-login-reuse.md](../research/02-login-reuse.md) ("Options for the decision"). Three inputs are still missing before the question can be put with a measured basis:

- login and OTP wall-clock per role, median and max (from ticket 01);
- which staging accounts use OTP, whether they share an inbox, and whether the app is single-session. These are the account-pool facts that the project guide does not record yet. Until they are verified, a per-account-type mix (D for no-OTP, B for OTP) cannot be scoped;
- the lane interaction: lane-named `storageState-{Lx}.json` blocks reuse today (`references/parallel-test-lanes.md:24`, `:88`). Any choice B or C has to rename by env + role + account, as ticket 02 resolved.
