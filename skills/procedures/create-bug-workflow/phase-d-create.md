# Create bug — Phase D

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase D as its progress-checklist line names. Every rule here is a full gate of the workflow.

## Phase D — Create issues [low freedom]

Follow [posting-discipline.md](references/posting-discipline.md).

### GitHub

```bash
gh issue create --repo <owner/repo> \
  --title "<title>" \
  --label "bug,severity:<Severity>" \
  --body "<body>"
```

`<Severity>` is the Severity in the approved draft (Low / Medium / High / Urgent). Pass only labels the
Phase B pre-flight found in the repo, or that the user created/approved; when the user chose to file
without a missing label, leave it out and say so in the Phase F report. Capture the returned issue URL.

**🔴 GATE — `gh issue create` exits non-zero** (rejected label, validation error, auth, rate limit,
network) → treat that issue as not created until `gh issue list --repo <owner/repo> --state all
--search '"<title>" in:title'` shows otherwise (a timeout can still create it — never file twice). Show
the user the stderr **verbatim**, which bugs were and were not created, and the fix you propose; **retry
nothing until the user approves.** Rate limit → say when `gh api rate_limit` reports the reset and
wait for the user's go-ahead. Never strip a label, shorten the body or switch repo to make it pass.

### Jira

1. Lock **v2 wiki** (FE/UI) vs **v3 ADF** (API) per user format — do not switch mid-session.
2. Prefer Atlassian MCP `createJiraIssue`, with the field mapping shown in the Phase C `Fields:` line
   (Priority → `priority`, Severity → the guide's field id, every required field filled).
3. **Field-validation error** (HTTP 400 / an `errors` object naming a field — required, invalid option,
   unknown custom field) → nothing was created. Show the error **verbatim**, name the field and the fix
   you propose (from the create metadata), and **wait for the user's approval** before retrying on the
   same path. Never drop or blank the field to make the create pass, and never treat this as an MCP
   failure that switches path.
4. **MCP fails** (unreachable, auth, tool error, timeout — not a field error) → the create may still have gone through, so **check before you switch path**:
   - Search for the approved summary with no status filter (`searchJiraIssuesUsingJql`, or the REST search on the locked path).
   - **Found one** → it is this run's issue: record its key, do **not** create it again, and continue at Phase F. **Found two or more** → show the keys and ask which is this run's issue; create nothing.
   - **The search itself cannot run** → **STOP**: ask the user to check the board before any retry. Never create on another path blind.
   - **Found none** → pick the first path that applies, and say which one you used:
     - macOS with a logged-in browser session → JXA + Chrome fallback per posting-discipline (ASCII-only script, dry-run before post);
     - otherwise, Jira REST credentials configured (see [dependencies.md](../../../references/dependencies.md)) → REST on the locked path;
     - otherwise → **STOP**: hand the approved drafts to the user to file manually, report the run as BLOCKED (no create path), and skip to Phase F only for anything the user files and links back.

**Write the body in the markup of the path you post through**, from the first keystroke
([jira-wiki-vs-markdown.md](../../../references/jira-wiki-vs-markdown.md) § The rule). One table, one rule:

| Path | Body markup | Gates in jira-wiki-vs-markdown.md |
|------|-------------|-----------------------------------|
| MCP `createJiraIssue` | markdown (MCP converts it to ADF) | Post-post: re-fetch and confirm zero literal markup left in the rendered text |
| REST v2 (`/rest/api/2/…`) — FE/UI lock | Jira wiki markup (`*bold*`, `----`, `\|\|header\|\|` with no divider row) | Pre-post string scan **and** post-post counts — both |
| REST v3 (`/rest/api/3/…`) — API lock | ADF JSON | Post-post: re-fetch and confirm zero literal markup left in the rendered text |
| JXA + Chrome fallback | the markup of the endpoint the script calls (v2 → wiki, v3 → ADF) | the gates of that endpoint's row |

A markdown body on the v2 path returns HTTP 200 and renders as garbage — the gates are the only catch.

Embed screenshots **bare** — `!file.png!`, resized to ~600–640 px before upload. A width parameter puts
a pipe inside a table cell and splits the row. The attachments endpoint needs an issue key
(`issueIdOrKey`), so for a **new bug** create the issue first with a body that has no image embed, then
upload the attachments to the returned key, then update the body to embed them bare, then re-fetch the
issue and confirm every embed rendered (not a literal `!file.png!`). "Attach before embed" applies only
to an issue that already has a key. If an upload fails (rejected type, size limit, permission, any
non-2xx), show the error verbatim, do not post a body that embeds the missing file, and ask the user:
retry the upload, leave the image out (embed line removed from the draft, shown again for **confirm**),
or attach it by hand. When the issue is created but the attach failed, also tell the user the issue key
that now exists. Never continue on your own. When the workspace carries `tools/retest-guard/retest_rules.js`,
run its scanner (rule `img-width-param`); when it does not, check every embed by hand for a bare
`!file.png!` and say so.
