# Worked example (anonymized) — Testing ticket

**Ticket:** `PROJ-501` — Login form validation  
**Outcome:** 3 scenarios run; summary in chat; guide sets no results destination

## Inputs

- Ticket: `PROJ-501`
- URL: `https://app.staging.example.com`
- User: test role account (saved session; no password collected)
- VPN: Not required
- Confluence / Swagger: none

## Repro — agent steps (abbreviated)

1. **Phase A:** Recited [helix-session-constraints.md](../../../../references/helix-session-constraints.md) testing-ticket block.
2. **Phase B (coverage gate layers 1–2; design ref node `12-34` opened):** Enumerated the ticket's AC/EC char-exact → `AC1` valid login lands on dashboard, `AC2` empty password shows a validation message, `AC3` locked account is blocked with a message. Built the coverage matrix `AC1→TC1 · AC2→TC2 · AC3→TC3` — every AC has a scenario. Widths: 1440 in scope; 390 out of scope (desktop-only admin page, stated with the reason).
3. **Phase C:** User replied `confirm` on the 3-scenario plan (coverage matrix, `Design ref`, `Build`, `Widths` shown).
4. **Phase D:** Preflight YES — the session endpoint returned the test account's user id; build `2.4.0 / abc1234`.
5. **Phase E:** TC1 login happy PASSED; TC2 empty password FAILED 3 of 3 (toast shown, no validation message); TC3 had no locked account, so one was created through the admin lock flow (QA-owned, ledgered by id — no data is never a verdict) and PASSED — each AC id gets its own row.
6. **Phase F:** Posted F1–F3 in chat with `Design ref:`, `Build:` and `Round time: AGENT+EXEC 13 min · human wait 2 min · overrun 0 min` lines; **reconciled coverage (layers 6–7):** 3 enumerated ids == 3 rowed-and-verdicted rows, none parked in a remark → complete. Listed defect in F3 without filing Jira issue.
7. **Phase G:** G1 — the guide says results destination None, so the F5 approval popup holds no write → session complete.

## Output snippet (F2 table)

Every AC/EC id is its **own row** with its own verdict — never a remark below the table.

```text
| # | Scenario | AC/EC id | Width | Result | Evidence |
| 1 | Valid login | AC1 | 1440 | PASSED | tc1-1440.mp4 + TC1-ER_1_w1440.png |
| 2 | Empty password | AC2 | 1440 | FAILED | tc2-1440.mp4 + TC2-ER_1_w1440.png |
| 3 | Locked account | AC3 | 1440 | PASSED | tc3-1440.mp4 + TC3-ER_1_w1440.png |
```

**Coverage:** 3 / 3 enumerated AC/EC ids rowed-and-verdicted (gate layer 6 green).

## Lessons

- **Every AC/EC is a row, never a remark.** A card once passed on partial coverage with the gap noted below the table — the [AC/EC coverage gate](../../../../references/qa-evidence-coverage.md#acec--bug-detail-coverage--7-layer-completeness-defense-gate-mandatory-fail-closed) forbids it: enumerate every AC/EC in Phase B, map 1:1 to rows, reconcile `enumerated == rowed` before "done".
- An AC **observed to differ** is a FAILED/PWMI **row** (severity per the matrix); an AC **not reached** is a BLOCKED row (a coverage gap, not a product FAILED). Either way it is a **row for that point**, never a PASS with a caveat.
- F3 defects → user must choose **Create bug** separately; this workflow does not file tickets.
- NEVER mark PASSED without screenshot or network evidence.
