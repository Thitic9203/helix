---
description: |
  Audit finished work — your own prior output, a document or report, a test artifact, or a feature — tracing every claim to the source that governs it, separating confirmed defects from open questions, and closing each defect with a sourced fix and a prevention layer.
  Use when the user says CatchAI, /catch-ai, "check yourself", ตรวจงานตัวเองอีกรอบ, or a result rests on a guess (น่าจะ).
  Do NOT use for retesting a bug after a fix (retest-bug), drafting TC tables (tc-fe-prep, tc-api-prep), reviewing a TC document (tc-review), running a ticket's Playwright pass (testing-ticket) or filing a bug (create-bug).
---

Read and follow [the catch-ai workflow](../skills/catch-ai-workflow/SKILL.md) end-to-end.

Pass arguments after `/catch-ai` as the audit target — a file path, a document, a ticket key, a report, or "your last answer". If none is given, ask what to audit before reading any audit material.

A defect is only "actual differs from a **confirmed** expected". Anything whose expected side cannot be sourced is a **Question**, never a bug — and the count follows the [Iron Law](../skills/catch-ai-workflow/SKILL.md#the-iron-law).

Every recommended fix cites a document opened in this session, quoted, with version and date; anything else is labelled **Judgment**. Every defect closes with a prevention layer.

Follow [references/user-communication.md](../references/user-communication.md). This command reports only — it never files a Jira bug (hand off to `/create-bug`) and never rewrites the audited work beyond the corrections it reports.
