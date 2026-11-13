# Create bug — Phase C

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase C; every rule here is a full gate.

## 🔴 GATE: Phase C — Confirm before create (hard gate) [low freedom]

Show:

```text
━━━ Create bug — confirm before filing ━━━
Target:     {Jira PROJ / GitHub owner/repo}
Format:     {user template name or Helix default}
Board check: {N candidates searched — {a} dropped in B2, {b} dropped in B3, {c} blocked or Needs Review, K to file}{ · comment scope not stated — when a pasted search does not say}
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

Ask every open question (B2 comment scope, B3 reporter questions, A3 Priority choice) once, numbered, inside this block — on its Board check, Likely or Needs Review line; never repeat it in prose around the block. Write its prose, questions, the B3 record and notes in the user's language ([user-communication.md](../../../references/user-communication.md)); keep field names, `Confirmed` / `Likely` / `Needs Review`, keys and **confirm** as written.

**Do not call `gh issue create`, `createJiraIssue`, or browser create until the user confirms.** No waiver: a request to skip approval, or a shared waiver line (agent-rationalizations, helix-session-constraints, skill-invocation-discipline), never replaces this **confirm**.

**Go back:** If the user asks for edits instead of **confirm**, revise the drafts and return to the start of Phase C — show the confirm block again. Phase D waits for **confirm**. The user cancels → create nothing, list each draft as not filed, and close with `Verdict: CREATED 0/{K} — cancelled by user` and QA closing.
