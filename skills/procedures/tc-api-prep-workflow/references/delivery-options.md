# Delivery options — TC API Prep

## CSV

Follow [csv-export-rules.md](../../../../references/csv-export-rules.md) — CSV export section. Key points:

- Apply **Cell text cleaning**: `<br>` variants → `\n`, strip ALL HTML tags, strip `**`
- UTF-8 with BOM (`encoding='utf-8-sig'`) — mandatory for Thai and non-ASCII to render correctly
- Use `csv.writer` (not string concatenation) — handles multiline cell quoting automatically
- Header row: plain text column names (no bold — CSV format does not support formatting)
- Do NOT alter Thai or non-ASCII characters

## Excel (.xlsx)

Follow [csv-export-rules.md](../../../../references/csv-export-rules.md) — Excel/xlsx section. Key points:

- Use Python + openpyxl inline script (see csv-export-rules.md for full script template)
- Apply **Cell text cleaning** same as CSV
- Header row 1: `Font(bold=True)` on every cell
- Cells with `\n`: set `Alignment(wrap_text=True)`
- openpyxl missing or failing: [phase-g-deliver.md](../phase-g-deliver.md) G1 step 3

## Test.md (agent-native, additive)

For hand-off to a Playwright/CLI agent or PR reading. Offer **alongside** CSV/Excel — never as a replacement.

- Format spec: [test-md-format.md](../../../../references/test-md-format.md) (single source of truth)
- Same reviewed table feeds it; emit exactly the approved rows (no fabricated cases)
- File: `references/{SCOPE}_API_TC.test.md` (same `{SCOPE}` as phase-g-deliver.md G1)

## Jira comment / chat draft

- **Bold every header cell**: `| **Test Case ID** | **Module / Feature** | **Test Title** | ... |` — ALL columns, not just one
- **Chat draft**: use `<br>` between numbered items (readable in markdown)
- **Jira comment body**: MUST convert `<br>` to Jira-native line breaks **before posting** (ADF `hardBreak`, G2 step 1) — never copy the chat draft directly. Full rules: [jira-linebreak-conversion.md](../../../../references/jira-linebreak-conversion.md)
- Issue keys that must not auto-link: in ADF (the G2 publish path) give the text node a `code` mark; `{{PROJ-123}}` is wiki markup and renders literally in ADF
- Large tables (> 50 rows): offer the user a CSV/xlsx attachment + table summary instead of the full inline table (phase-g-deliver.md G2 step 1); verify row count on Jira UI after post
- After post: confirm **no literal `<br>` in any cell** on Jira UI

## Confluence

- Match existing table on the page if updating
- Read page first; do not overwrite unrelated sections

## Verification

After any delivery:

- [ ] Row count matches approved draft
- [ ] Column order matches user-confirmed format
- [ ] No draft marked “not published” still missing at destination
