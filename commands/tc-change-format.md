---
description: |
  Copy each ticket's test cases from a TC tab in a Google Sheet into a new Google Sheet made from the
  project's release TC template, placed in the release folder the user picks — one tab or several.
  Do NOT use for writing new test cases (tc-fe-prep / tc-api-prep), reviewing test cases (tc-review),
  or recording test results (testing-ticket).
---

Read and follow [the TC change format workflow](../skills/tc-change-format-workflow/SKILL.md) end-to-end.

Pass arguments after `/tc-change-format` as one or more TC sheet links (each with its tab) and the card
for each tab — a Jira key or URL. If any is missing, ask for it before starting.

All rules — the refusal-first gate, project config from the user's guide, column mapping, update mode,
copy-never-retype, verification with a negative control, and the tracking-sheet confirm — live only in
the workflow's SKILL.md. Follow it end-to-end; do not work from a summary here.

Follow [references/user-communication.md](../references/user-communication.md).
