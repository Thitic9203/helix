# Session closing (all workflows)

Apply at the **end of every workflow** (success, partial, blocked), in the user's language.

## 1 — Unified verification

Complete [verify-closing-checklist.md](verify-closing-checklist.md) for this workflow type before saying the session is done. **TC review** (no test run) closes with its own § QA closing, not verify-closing-checklist.md.

## 2 — Artifact index (mandatory)

Post the paths and links the user needs:

```text
━━━ Artifacts ━━━
| Item | Location |
|------|----------|
| Draft / table | chat above |
| Markdown | references/{file}.md |
| CSV | references/{file}.csv |
| Screenshots | screenshots/{KEY}/ |
| Jira comment | {URL} |
━━━━━━━━━━━━━━━
```

List only what was created, with workspace-relative paths.

## 3 — Next workflow (mandatory one line)

Offer **exactly one** next step, the row for the finished workflow ([skill-routing.md](skill-routing.md)); when no row matches, write `Next: none`.

| Finished | Next step (one line) |
|----------|-------------------|
| TC FE prep | “Run **/testing-ticket** on the same story?” |
| TC API prep | “Run **/testing-ticket** or export-only — your call.” |
| Testing ticket (failures) | “Next: **/create-bug** for {scenario ids}” |
| TC review | “Fix the TCs, then **/testing-ticket**?” |
| Retest PASSED | “Close or notify PM — no Helix step required.” |
| Retest FAILED | “**Create bug** or reassign per your process?” |
| Create bug | “**Retest** after the fix is deployed?” |
| Catch AI (defects) | “File with **/create-bug** after you approve?” |

Do not auto-start the next workflow without user consent.

## 4 — Handoff file (every retest / testing round; long or interrupted sessions otherwise)

**Retest and testing ticket (and smoke): write it at the close of every round** with the per-round state and source fingerprints the next round compares against
([round-time-contract.md §10](round-time-contract.md#10-per-ticket-state-and-fingerprints)).

Others: write when **any** applies:

- User can continue in a **new chat**
- Workflow ran **> 30 minutes** or **> 15 TC rows**
- Session ended **blocked** (VPN, auth, partial Jira post)

**Path:** `references/helix-handoff-{ISSUE_KEY or slug}.md` in the **user’s workspace**

Use [handoff-file-template.md](handoff-file-template.md). Tell the user the path.

## 5 — Verdict block (mandatory)

Close with:

```text
Verdict: {COMPLETE | PARTIAL | BLOCKED}
Verified: {what was re-read on destination}
Blocked: {none | list}
```

Never use “done” without `Verified:` when Jira/files were written.
