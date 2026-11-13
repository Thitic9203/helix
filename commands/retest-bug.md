---
description: |
  Retest a Jira bug or task after a dev fix — verify against the design (Figma), evidence, comment with its case list, transition.
  Use when a fix needs re-verifying (retest bug, verify fix, Ready to Retest).
  Do NOT use for filing new bugs (create-bug), drafting TC tables (tc-fe-prep / tc-api-prep), or first-time ticket testing (testing-ticket).
---

Read and follow [the retest-bug workflow](../skills/retest-bug-workflow/SKILL.md) end-to-end.

Pass arguments after `/retest-bug` as the Jira issue key or URL — a Bug, or a Task/Story whose fix is being re-verified. If none, ask which ticket to retest.

Every UI retest compares the screen against its Figma node; if a screen has no design reference, report that back to whoever asked for the retest and leave its visual points BLOCKED. The posted comment always carries the **test-case list**.

Follow [references/user-communication.md](../references/user-communication.md). Draft the Jira comment before posting and get the Step 6d approval; a general cue ("don't ask") never waives it — only an outward action the owner delegated by name (comment-and-post.md, *Delegated actions*).
