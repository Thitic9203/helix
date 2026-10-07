---
type: grilling
status: open
assignee:
blocked_by: [01]
---

# Login reuse option

## Question

Which login strategy should the workflows use: A (fresh login every run), B (reuse per operator across runs), C (B plus a cross-session account lease), or D (cheap fresh login through the API)? The answer may be a mix per account type, for example D for accounts without OTP and B for accounts with OTP. Weigh it against the measured login and OTP time from the baseline and the 15-minute cap. The facts and trade-offs are in [research/02-login-reuse.md](../research/02-login-reuse.md).
