# OLS (OLS-xxx) profile

Applies to every ticket with key `OLS-xxx`. Facts below are the confirmed OLS rules; anything not listed is unspecified — ask once rather than assume.

## TC format rules
- **Test Type values:** Core / Edge. Map by label prefix: `AC_…` → Core, `EC_…` → Edge, **`BR_…` → Edge (always, no question)**. A mixed label such as "AC_13, EC_02" starts with AC_ → Core. A label matching no rule (e.g. "Business Rule", "Key Feature" without prefix) needs a question. Always list Core/Edge counts in the confirmation table.
- **Glossary:** use the OLS Thai TC glossary (re-fetch it at the workflow's glossary step). Do not apply the PYR English-term-first rule to OLS.
- **Test Case ID:** follow the Helix tc-fe-prep default (simple sequential number). The `TC-01` format is PYR-only.

## Create / review
Follow the Helix workflow as written (`tc-fe-prep-workflow`, `tc-api-prep-workflow`, `tc-review-workflow`); there is no OLS-specific overlay beyond the rules above and the format-change rules below.

## Change TC format (move TCs into the release template)
- Workflow: `tc-change-format-workflow`. Intake asks only three things: source TC link, ticket link, release folder. The saved template (`OLS-CR-TC`) and release root folder carry over within a session.
- **Never resize columns.** Keep the template's original column widths. Keep wrap on, delete empty rows/columns, add solid borders. Set row heights from estimated wrapped line counts (lines × 18 + 8 px) and tell the user the heights are estimates.
- Owner tags come from the Jira "QA Owner" field.
- The normal confirmation table and one-yes gate apply before any write.

## Not yet specified (add here when the team decides)
- OLS Qase project / suite layout
- OLS result-recording location for manual execution
