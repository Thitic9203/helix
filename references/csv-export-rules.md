# CSV / Excel export from markdown tables

Use when `tc-fe-prep-workflow` or `tc-api-prep-workflow` writes an export file next to `.md` in the **user’s workspace**.

> **TC FE CSV types:** Three template formats exist (Unit Test / Integration Test / System Test), each with different columns and row structure. See [csv-template-types.md](csv-template-types.md) before generating a TC FE CSV.

## Contents

- [Format detection (decide before exporting)](#format-detection-decide-before-exporting)
- [Cell text cleaning (apply to EVERY cell, both formats)](#cell-text-cleaning-apply-to-every-cell-both-formats)
- [CSV export (default)](#csv-export-default)
- [Excel / xlsx export (when user explicitly requests Excel)](#excel--xlsx-export-when-user-explicitly-requests-excel)
- [Typed TC FE export (Unit / Integration / System)](#typed-tc-fe-export-unit--integration--system)
- [Sibling format — Test.md (agent-native)](#sibling-format--testmd-agent-native)

## Format detection (decide before exporting)

| User’s request contains… | Output format | File extension |
|--------------------------|---------------|----------------|
| `Excel`, `xlsx`, `.xlsx`, `ไฟล์ Excel`, `excel file` | Excel | `.xlsx` |
| anything else (or no mention) | CSV (default) | `.csv` |

Check the user’s **original request** for this session — not just the latest message.

---

## Cell text cleaning (apply to EVERY cell, both formats)

Run these steps on every cell value **before** writing to any file:

1. Convert all `<br>` variants to a newline character — use a case-insensitive regex:
   ```
   pattern: <br\s*/?>   (matches <br>, <br/>, <BR>, <BR/>, <br >, <BR />, etc.)
   replace with: \n
   ```
2. Strip the remaining **real HTML tags only** — a whitelist of tag names, case-insensitive, with or without a closing slash and attributes:
   ```
   pattern: </?(?:a|b|br|code|div|em|h[1-6]|hr|i|li|ol|p|pre|span|strong|sub|sup|table|tbody|td|th|thead|tr|u|ul)(?=[\s/>])[^>]*>
   replace with: (empty string)
   ```
   This removes `<b>`, `<strong>`, `<em>`, `<p>`, `<li>`, `<ul>`, `<a href="...">`, etc. A bare `<[^>]+>` must not be used: it also deletes placeholders such as `<SUITE_PATH>` or `<ORG>`, which are not HTML and must survive into the cell.

   Example (steps 1–3 together):
   ```
   input:  Run <b>suite</b> at <SUITE_PATH><br>then **check**
   output: Run suite at <SUITE_PATH>
           then check
   ```
3. Strip `**` markdown bold markers (replace `**` with empty string).
4. **Do NOT alter, escape, or transliterate any Thai or non-ASCII characters** — preserve them exactly.

After cleaning, a cell that contained `ตรวจสอบ<br>ผลลัพธ์` must read `ตรวจสอบ\nผลลัพธ์` (literal newline, Thai intact).

---

## CSV export (default)

MUST use this path unless the user explicitly requested Excel **or** gave an explicit Helix install directory:

1. Apply **Cell text cleaning** (above) to every cell.
2. Header row = plain text column names (no `**` bold — CSV does not support formatting).
3. Write **UTF-8 with BOM** (`encoding='utf-8-sig'` in Python) — mandatory so Excel opens the file with UTF-8 encoding; without it, Thai and other non-ASCII characters render as garbled symbols.
4. **Multiline cells** (containing `\n`) MUST be double-quoted in the CSV — use Python's `csv.writer` which handles this automatically; do NOT build CSV by string concatenation.
5. Row count must match the approved markdown table (excluding header).

### In-agent CSV export (inline script)

Generate and run this Python script inline. `{OUT}` is the file the calling workflow names (tc-fe Step 6: `references/Draft_Jira_{ISSUE_KEY}` and `references/Import_Qase_{ISSUE_KEY}`, one run each; tc-api G1: `references/{SCOPE}_API_TC`):

```python
import csv
import re

def clean_cell(text):
    text = str(text) if text is not None else ""
    text = re.sub(r"<br\s*/?>", "\n", text, flags=re.IGNORECASE)  # <br> variants → newline
    text = re.sub(r"</?(?:a|b|br|code|div|em|h[1-6]|hr|i|li|ol|p|pre|span|strong|sub|sup|table|tbody|td|th|thead|tr|u|ul)(?=[\s/>])[^>]*>", "", text, flags=re.IGNORECASE)  # strip real HTML tags only; keeps <PLACEHOLDER>
    text = text.replace("**", "")                                  # strip markdown bold
    return text.strip()

headers = ["{col1}", "{col2}", ...]  # plain text — no ** wrapping
rows = [
    ["{val}", ...],  # one list per TC row — Thai strings passed as-is
]

with open("{OUT}.csv", "w", newline="", encoding="utf-8-sig") as f:
    writer = csv.writer(f)
    writer.writerow([clean_cell(h) for h in headers])
    for row in rows:
        writer.writerow([clean_cell(v) for v in row])

print(f"Saved {len(rows)} rows to {OUT}.csv")
```

### Optional CSV script (user-provided install root only)

If and only if the user states where Helix is installed (e.g. they paste a directory path), run:

```bash
python3 "{HELIX_INSTALL_ROOT}/scripts/export-markdown-table-to-csv.py" \
  "{workspace-relative-input}.md" \
  -o "{workspace-relative-output}.csv"
```

- `{HELIX_INSTALL_ROOT}` = path **the user provided** in this session.
- NEVER assume the Helix install directory, the agent home directory, or `scripts/` relative to the project under test.

If the script is missing or fails, fall back to in-agent CSV export — do not block delivery.

---

## Excel / xlsx export (when user explicitly requests Excel)

Use this path when format detection resolves to `.xlsx`.

### In-agent xlsx export

1. Apply **Cell text cleaning** (see above) to every cell — `<br>` variants → `\n`, strip HTML tags, strip `**`.
2. Check `openpyxl` per [dependencies.md](dependencies.md). Missing → never install it yourself; the calling
   workflow's gate decides (tc-fe-prep: WORKFLOW Step 6 🔴 GATE).
3. Generate and run a Python script inline — paste `clean_cell` (and `import re`) from the CSV script above:

```python
import openpyxl
from openpyxl.styles import Alignment, Font

wb = openpyxl.Workbook()
ws = wb.active
ws.title = "Test Cases"

headers = ["{col1}", "{col2}", ...]   # replace with actual column names
ws.append([clean_cell(h) for h in headers])

# bold every header cell
for cell in ws[1]:
    cell.font = Font(bold=True)

rows = [
    ["{val}", ...],  # one list per TC row — Thai strings passed as-is
]
for row in rows:
    cleaned = [clean_cell(v) for v in row]
    ws.append(cleaned)
    # enable wrap_text for any cell that contains a newline
    row_idx = ws.max_row
    for col_idx, val in enumerate(cleaned, 1):
        if "\n" in val:
            ws.cell(row=row_idx, column=col_idx).alignment = Alignment(wrap_text=True)

wb.save("{OUT}.xlsx")
print(f"Saved {len(rows)} rows to {OUT}.xlsx")
```

4. Row count printed must match the approved markdown table (excluding header).
5. `{OUT}` is the calling workflow's name, as in the CSV script, inside the user’s workspace.

### Fallback

If xlsx generation fails (missing Python, permission error, etc.) → warn the user and offer to fall back to UTF-8 BOM CSV instead. **Do not silently produce a CSV when the user asked for xlsx.**

---

## Typed TC FE export (Unit / Integration / System)

Generate one typed CSV per Type that has TCs (Unit / Integration / System), after `Draft_Jira` and `Import_Qase`. Each file holds only that Type's TCs, with content mapped per the Step 6 column-mapping tables in `tc-fe-prep-workflow` `WORKFLOW.md`; only execution-result columns stay blank. Skip the file for a Type with no TCs. Full column/row specs: [csv-template-types.md](csv-template-types.md).

| Type | File | Template spec |
|------|------|---------------|
| Unit Test | `Unit_Test_{ISSUE_KEY}.csv` | 13 English columns, Function/Sub Function header rows, no footer, UTF-8 BOM |
| Integration Test | `Integration_Test_{ISSUE_KEY}.csv` | 9 Thai columns, one row per TC, no footer, UTF-8 BOM |
| System Test | `System_Test_{ISSUE_KEY}.csv` | 9 Thai columns, one row per TC, no footer, UTF-8 BOM |

Header columns, Function / Sub Function rows and row layout: [csv-template-types.md](csv-template-types.md) (single source).

**Upload + link:** typed CSVs upload in the same [jira-fast-publish.md](jira-fast-publish.md) Pattern B call, after `Import_Qase`; each link is the ADF `__ATT{n}_ID__` node that call fills, never a markdown link.

---

## Sibling format — Test.md (agent-native)

For hand-off to a Playwright/CLI agent, offer **Test.md** alongside CSV — see also [test-md-format.md](test-md-format.md). Test.md is **additive**, never a replacement for CSV/Excel; both read the same reviewed chat table. Generator: [scripts/export-test-md.py](../scripts/export-test-md.py).
