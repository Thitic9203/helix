# Pyrite (PYR-xxx) profile

Applies to every ticket with key `PYR-xxx`.

## Targets
- Qase project: https://app.qase.io/project/Pyrite — API project code is `Pyrite` (not `PYR` / `PYRITE`).
- Qase API token: read from the environment variable `QASE_API_TOKEN` (each person creates their own; setup in the repo README, section "qa-project-flow: Qase token"). Send it as header `Token: $QASE_API_TOKEN`. Never print, copy or store the value anywhere (chat, sheet, Qase, Jira, repo). If the variable is empty or the API returns 401, tell the user to follow the README setup; do not ask them to paste the token.
- Tracking sheet ("Pyrite QA"): the one entry point. Its link is team-private and is NOT stored in this public repo. Each person gives it once; keep it in your own memory or local notes. If it is missing, ask once and remember it.
- Drive output folder and TC sheet template: read them from the `Config` tab of the Tracking sheet (columns: Key, Value; keys `DRIVE_FOLDER` and `TC_TEMPLATE`). If the tab or a key is missing, ask once; never guess a link.

## Create-TC flow
1. Create the TCs in Qase project Pyrite (suite chosen per feature; e.g. Authentication › Register).
2. In the Drive folder, create subfolder `PYR-xxx` and put the TC sheet inside, copied from the template format.
3. Update the tracking sheet row for the ticket.
4. Keep Qase, sheet and any CSV identical.

**Reuse rule:** before creating anything, check for an existing Drive subfolder `PYR-xxx` + sheet and Qase cases/suite for that ticket. If found, update in place (same ids/links). Create only what is missing.

**`updateTCSheet`:** after a review or change, apply the updated TCs to every place (Qase, TC sheet, other artifacts of that ticket) so all match. Confirm the ticket if ambiguous.

**Definition of done:** Qase + Drive TC sheet + tracking sheet updated. Then report done and stop. Do NOT post a Jira comment or attach CSVs to Jira unless asked.

## TC format rules
- **Test Case ID:** `TC-01`, `TC-02`, … (prefix `TC-`, 2-digit padding; ask only if a ticket passes 99 TCs). Qase has no ID field (auto ids).
- **Test Case Type** (sheet column and Qase custom field id 4): `Happy Path`, `Failure Scenario`, `Edge Case`, `Exceptional Case` — never OLS Core/Edge.
  - Qase option ids: 1 Happy Path, 2 Failure Scenario, 3 Edge Case, 4 Exceptional Case.
  - Positive flow → Happy Path; rejected/invalid input or error → Failure Scenario; boundary/limit/unusual condition → Edge Case; unexpected state / system exception → Exceptional Case.
- **Ordering:** Happy Path → Failure Scenario → Edge Case → Exceptional Case; inside a type keep AC/EC order; renumber IDs 1..N after sorting. The Qase API cannot set case position, so reorder by overwriting existing case slots in place, not delete/recreate.
- **Test Data / Test Step / Expected Result:** equal item count, numbered 1, 2, 3 with no gaps, and **no `-` placeholder lines**. Merge or split steps so every step has its own data and expected result; if a count truly cannot match, flag it instead of padding.
- **Test Title:** start with "ตรวจสอบ". Describe what is being checked only; never put the expected result in the title.
- **Precondition and Test Data:** short sentences, one idea per line, no long explanations.
- **Writing style (every TC field):** natural Thai, semi-formal. No special symbols or unusual characters (no emoji, arrows, decorative bullets, odd quotes or brackets used as decoration). Plain numbers and normal punctuation only.
- **Glossary:** English-term-first. Use the ticket's own wording (keep English where the ticket writes English: checkbox, badge, dropdown, permission, scope, role, account, login, tab, filter, status). Do not raise glossary-vs-ticket collisions as questions; still show the term table for information.
- **No Figma / PRD link in the ticket = absent.** Do not ask for them. Use ticket text only and record "no Figma / no PRD" in the pre-draft review and Remark.

## Review-TC overlay
Judge TCs against the rules above (ID format, Type values and order, equal counts, no `-`, English terms, Title starts with "ตรวจสอบ" with no expected result in it, short Precondition and Test Data, plain semi-formal wording with no special characters) in addition to AC/EC coverage.
