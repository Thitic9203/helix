# Create bug — Phase C

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase C as its progress-checklist line names. Every rule here is a full gate of the workflow.

## 🔴 GATE: Phase C — Confirm before create (hard gate) [low freedom]

Show:

```text
━━━ Create bug — confirm before filing ━━━
Target:     {Jira PROJ / GitHub owner/repo}
Format:     {user template name or Helix default}
Board check: {N candidates searched — M dropped as already-settled/duplicate, K to file}{ · comment scope not stated — when a pasted search does not say}
Fields:     {GitHub: labels that exist / labels missing + the user's choice · Jira: Priority → field, Severity → field id from the workspace guide, required fields with their values}
Bug count:  {K}
Needs Review: {none · or per item: title — open question (draft shown below, labelled Needs Review — not filed; not counted in Bug count)}

Draft summaries:
  1. [{Severity}] {Module} — {title one line} · Priority {Priority} · {Confirmed | Likely — open question: {reporter question, if any}}
  2. ...

(Full drafts below — review each body)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Reply **confirm** to create all listed bugs (a Likely item is approved as Likely by this confirm), or specify edits.
```

Then post **full drafts** (one block per bug) per [bug-draft-template.md](references/bug-draft-template.md).

**Do not call `gh issue create`, `createJiraIssue`, or browser create until the user confirms.**

**Go back:** If the user asks for edits instead of **confirm**, revise the drafts and return to the start of Phase C — show the confirm block again. Phase D waits for **confirm**.
