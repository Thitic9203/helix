# Posting discipline — Create bug

## GitHub

- Labels: `bug`, `severity:<Severity>` (the draft's Severity: Low / Medium / High / Urgent) —
  only labels the [WORKFLOW Phase B tracker-fields pre-flight](../WORKFLOW.md#phase-b--parse-target-medium-freedom) found or the user approved.

## Jira

Which body markup each create path takes, and which gate runs on it, is one table in
[phase-d-create.md § Jira](../phase-d-create.md#jira). The format is locked once, at intake A2, for the session; Phase C only shows it.

## Jira MCP → JXA fallback

Used only when [phase-d-create.md](../phase-d-create.md) item 4 selects it.

1. Build body; `JSON.stringify` then escape non-ASCII to `\uXXXX` for ASCII-only `.js` file.
2. Dry-run decode before `osascript`.
3. Real emoji `✅` `❌` — not literal `\\u274c` in posted content.
4. In the logged-in Jira tab the script calls `fetch('/rest/api/2/issue', {method: 'POST', …})` (v3 lock: `/rest/api/3/issue`) and reads `key` from the response; a non-2xx or no response → phase-d-create item 4.

## Pre-post checklist

- [ ] User confirmed drafts
- [ ] Evidence attached where required (FE/UI screenshots on Jira)
- [ ] No bare `PROJ-123` in wiki — use `{{PROJ-123}}` when auto-link is unwanted

## Post-create verification

Re-fetch each issue and compare it to the approved draft per [phase-f-close.md](../phase-f-close.md).
