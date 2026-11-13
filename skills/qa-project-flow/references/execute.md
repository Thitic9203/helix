# Execute tests (both projects)

Current mode: **manual execution against the TC sheet.** Automation (Playwright) is planned but not started — do not run or write Playwright for this job unless the user asks. A move to Qase test runs is possible later; Qase cases already exist for PYR, so keep sheet and Qase identical.

## Flow
1. **Intake (one item at a time):** ticket key, TC sheet link (reuse the existing sheet for the ticket), environment URL, test account (never ask for or store the password in chat/sheets — the user logs in).
2. **Plan:** read the TC sheet, list the TCs to run in sheet order (PYR: already Happy Path → Failure → Edge → Exceptional). Confirm scope once: all TCs or a subset.
3. **Run each TC step by step** through the real UI steps; do not shortcut the action under test through an API. Compare against Expected Result per step (and Figma when the ticket has a link; for PYR no link = no design check).
4. **Record per TC:** `Passed` / `Failed` / `Blocked` / `Not run`, tester, date, environment/build, and a short note. Use the result columns that exist in the sheet; if the sheet has none, ask once where to record rather than adding columns.
5. **Evidence:** screenshot or clip for every Failed and Blocked TC, and for key Passed TCs when the sheet has an evidence column.
6. **Non-pass:** before recording Failed, re-run once to confirm it reproduces and rule out test-data/environment causes. Then hand off to `create-bug-workflow` (ask first — never file automatically).
7. **Close:** report counts (passed / failed / blocked / not run), list failures with TC IDs, and state what was not run and why.

## Rules
- Update the sheet and, if the TCs exist in Qase, keep the Qase status consistent; do not leave them different.
- Never mark a TC Passed without having executed its steps.
- Do not post to Jira from this flow unless the user asks (PYR definition of done excludes it).
