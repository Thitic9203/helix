# Create bug — Phase F

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase F; every rule here is a full gate.

## Phase F — Fix-verify and close (mandatory) [low freedom]

After Phase D create calls:

1. List each issue with **URL or key** from tool output (not guessed).
2. **Fix-verify round 1:** Fetch each link (`gh issue view <url> --json title,body,labels`; Jira `getJiraIssue`) — confirm title/summary and body match approved draft.
3. **🔴 GATE — mismatch** (wrong project, truncated body, wrong priority/severity): show the user the
   draft-vs-destination difference and the proposed fix (edit in place, or recreate), and **wait for
   approval**. Then fix via the edit API, or recreate — when recreating, also close or link the wrong
   issue as a duplicate (with the same approval) so no stray issue stays behind → **re-fetch** each link.
4. **Maximum 2 fix-verify rounds** — then report partial success honestly.
5. If any create failed → report which succeeded, which failed and which are outcome unknown.
6. **Fetch fails** (permission, 404, MCP down) → report that key/URL from the tool output as **created-unverified** with the error verbatim, retry the fetch once by another read path (REST, browser or `gh issue view`); still failing → `Verdict: CREATED {N}/{N} — {m} unverified`. Never call it verified.

**Go back:** If fix-verify round 1 finds a mismatch, fix it (item 3) and return to item 2 of this phase — re-fetch every link. After round 2, stop and report partial success.

The `Verdict: CREATED` line below is create-bug's form of the `Verdict:` line in [session-closing.md](../../../references/session-closing.md) §5.

MUST NOT say “all bugs created” until at least one full fix-verify round passes — because create APIs can return success with wrong content.

```text
━━━ Create bug — complete ━━━
Verdict: CREATED {N}/{N} — verified at destination
| # | Target  | Issue              | Priority |
|---|---------|--------------------|----------|
| 1 | Jira    | PROJ-456 (link)    | High     |
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## QA closing (mandatory before "done") [low freedom]

Follow [qa-closing-shared.md](../../../references/qa-closing-shared.md) + skill-specific:

- [ ] Board-conflict search (Phase B2) ran for every candidate; any dropped as already-settled/duplicate reported to the user with the reference link.
- [ ] Every created issue has URL/key from tool output (not guessed).
- [ ] Each URL opened or fetched — title visible.
- [ ] Close-out includes `Verdict: CREATED x/y`.
- [ ] [verify-closing-checklist.md](../../../references/verify-closing-checklist.md) (Create bug section).
- [ ] Offer **retest** after the fix; handoff if blocked.

**Go back:** If any item above is unchecked, return to the phase it names (B2, D or F) and redo from there; do not report done.
