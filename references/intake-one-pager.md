# Intake one-pager (long workflows)

Show **once** at the start of intake (before detailed questions). Write it in the user's language. Adjust the checklist to the workflow.

## TC API prep

```text
━━━ What I need from you (TC API) ━━━
Required now:
  • API spec (link, file, or pasted scope)
  • Swagger/OpenAPI (URL or path)
After that I will ask:
  • Column changes (or "default")
  • Delivery: Jira/Confluence link and/or CSV/Excel/Test.md path
Optional: Jira story key for traceability only
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Testing ticket

```text
━━━ What I need from you (Testing ticket) ━━━
Required:
  • Ticket (Jira key or URL)
  • Application URL
  • Login account — username/email only, or "guest" (never a password)
  • VPN: required or not
Optional:
  • Confluence page
  • Swagger URL
I will post the intake summary and a test plan, and wait —
nothing runs in Playwright until you reply **confirm**.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Create bug

```text
━━━ What I need from you (Create bug) ━━━
Required:
  • Where to file (Jira project URL/key or GitHub repo)
  • Format (template link, Helix default, or v2/v3 rule)
  • Bug details (title, steps, entry points tried, expected + source link, severity, evidence)
A prior testing-ticket run in this chat counts as input; cite it.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Retest bug

```text
━━━ What I need from you (Retest) ━━━
Required:
  • Bug/Task/Story key or URL
  • Reachable environment (from *-retest-guide.md or your answers)
I will list what the dev claimed fixed vs what we will verify.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Do not ask for fields already provided in the user’s first message — mark them done on the one-pager.
