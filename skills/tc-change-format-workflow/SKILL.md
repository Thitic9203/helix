---
name: tc-change-format-workflow
description: |
  Copy one ticket's test cases from a TC tab in a Google Sheet into a new Google Sheet made from the project's release TC template, placed directly in the release folder the user picks. Only mapped template columns are filled; the template's look (coloured dropdowns, borders, header) is kept, empty rows and columns are removed, rows and columns are sized so no line wraps, and owners become people tags.
  Use when the user sends a TC sheet link (with a tab) and asks to change the TC format, move the TC into the release template, or create the release TC file for a card, or says /tc-change-format, เปลี่ยนฟอร์แมต TC, ย้าย TC ลง template.
  Do NOT use for writing new test cases (tc-fe-prep-workflow / tc-api-prep-workflow), reviewing test cases (tc-review-workflow), or recording test results (testing-ticket-workflow).
proactive_triggers:
  - /tc-change-format
  - change tc format
  - move tc to template
  - เปลี่ยนฟอร์แมต TC
  - ย้าย TC ลง template
---

# TC change format

Announce once: `Using **tc-change-format-workflow** to copy the TC tab into the release template.`

Talk to the user in their language and ask every question in that language. Never write to Drive or Sheets before step 6 is confirmed.

## Contents

- [Refusal-first (precondition gate)](#refusal-first-precondition-gate) · [Project config](#project-config) · [Tools required](#tools-required) · [Column mapping](#column-mapping-template--source)
- Steps: [1 Intake](#1-intake) · [2 Resolve the tab](#2-resolve-the-tab) · [3 File name](#3-card-title--file-name) · [4 Read source](#4-read-the-source-tab) · [5 Release folder](#5-pick-the-release-folder) · [6 Confirm](#6-confirm-before-writing) · [7 Create](#7-create) · [8 Fill](#8-fill--copy-never-retype) · [9 Tidy](#9-tidy-the-sheet) · [10 Verify](#10-verify--in-the-sheet-with-a-control) · [11 Report](#11-report)
- [QA closing (mandatory before "done")](#qa-closing-mandatory-before-done)

## Refusal-first (precondition gate)

MUST NOT write anything without all of:

- the **TC sheet link** with a tab, readable this session;
- the **card** (Jira link, or the user's go-ahead to read the card whose key equals the tab name);
- the project config values below, and an e-mail for every owner name;
- the Google Sheets and Google Drive connectors, authenticated.

Missing any, stop in one message and ask for exactly what is missing.

## Project config

All project values come from the **user's** `references/*-guide.md` in the workspace (section "TC change format"), or are asked in the session and then saved there. Never read them from the Helix repo.

| Value | Meaning |
|---|---|
| `{TC_TEMPLATE_SHEET}` | The release TC template as a **Google Sheet** (one tab, header in row 1, row 2 a formatted sample row) |
| `{TC_RELEASE_ROOT_FOLDER}` | Drive folder whose sub-folders are the releases (default name pattern `Release <DD>_<Mon>`) |
| `{TC_OWNER_EMAIL_MAP}` | Owner name → Google account e-mail, for people tags — keep it outside any public repo |
| Column mapping / value rules | Optional override of the defaults below |

If a value is missing, ask the user. Never guess an ID or an e-mail.

Use a Google Sheet template, not an `.xlsx` uploaded by base64: retyping base64 is not reliable (a 14 KB file came back 30 bytes longer in testing) and an xlsx loses dropdown colours.

## Tools required

- Google Sheets connector (`get_spreadsheet`, `get_values`, `copy_sheet_to_another_spreadsheet`, `update_spreadsheet`, `update_values`, `update_formulas`)
- Google Drive connector (`search_files`, `copy_file`, `create_file`)
- Jira connector, read only — for the card title

If a connector is missing or not authenticated, stop and tell the user to run `/mcp` and connect it.

## Column mapping (template ← source)

Default mapping (from the first project that used this workflow). Headers are compared after trimming, collapsing inner spaces and ignoring case. The project guide may override it.

| Template column | Source column | Rule |
|---|---|---|
| Test Case ID | Test Case ID | copy |
| Module / Feature | Services Impacted | copy |
| Test Title | Test Title | copy |
| Test Type | Acceptance Criteria | `AC_…` → `Core` · `EC_…` → `Edge` · anything else → stop and ask |
| Precondition | Precondition | copy |
| Test Data | Test Data | copy |
| Test Steps | Test Steps | copy |
| Expected Result | Expected Result | copy |
| Test Status | Test Status | `NOT STARTED` → `NO RUN` · a value already in the dropdown → copy · anything else → stop and ask |
| Test Result Link | Capture Screen Link | copy; keep the URL if the cell has one (step 4) |
| Linked Bug (if any) | Linked Bug | copy; keep the URL if the cell has one |
| Owner | QA Owner | people tag (step 8) |
| Comments/Notes | Remark | copy |

A template column with a strict dropdown cannot take a value outside its list — map it by a rule or ask.
Source columns not in the table are not copied — list them in the final report.
Keep every template column, even when it has no data.

## Steps

### 1. Intake

Need both:
- **TC sheet link** with a tab (`…/spreadsheets/d/<id>/edit?gid=<gid>`)
- **Card** — a Jira link, or the user's go-ahead to read the card whose key equals the tab name

Ask for whichever is missing. If the sheet link has no `gid`, ask for the tab name.

### 2. Resolve the tab

- `get_spreadsheet` with `fields: ["sheets.properties.sheetId","sheets.properties.title"]`.
- Find the sheet whose `sheetId` equals the `gid`. Not found → stop and show the user the tab list.
- The card key must equal the tab title. If they differ, stop and ask.

### 3. Card title → file name

- Read the card (read only) and take `summary` verbatim.
- File name = `<KEY> <summary>` with one space, e.g. `{ISSUE_KEY} [SIT][ABC] Some feature`.

### 4. Read the source tab

- `get_values` on `'<tab>'!A1:ZZ`. Row 1 is the header. Every source column in the mapping must be present; a missing one → note it.
- Data rows = rows below the header with a non-empty `Test Case ID`. Count them (N).
- Check every value that a rule maps; collect anything that needs a question.
- Every distinct owner name must be in `{TC_OWNER_EMAIL_MAP}`. A missing name → ask the user for that person's e-mail and save it in the map.
- **Links travel with the cell.** For the link columns read `get_spreadsheet` with
  `fields: ["sheets.data.rowData.values.hyperlink","sheets.data.rowData.values.textFormatRuns","sheets.data.rowData.values.chipRuns"]`.
  A URL found → it must arrive in the new file. A label with no URL behind it → copy the text as it is.

### 5. Pick the release folder

- `search_files` with `parentId = '{TC_RELEASE_ROOT_FOLDER}'`; follow `next_page_token` until the response is empty. Keep folders only.
- Ask which release (a choice list when 4 or fewer, otherwise a numbered list).
- If the wanted release is not there, ask for the day and month, build the name with the project pattern
  (default `Release <DD>_<Mon>`, e.g. `Release 18_Nov`), confirm the exact name, and create it in step 7.
- Refuse any folder the project guide marks as frozen or read-only.
- **No folder per ticket** — the file goes directly into the release folder.

### 6. Confirm before writing

Show the user, then wait for an explicit yes:
- Release folder name, and the file name — plus whether a file with that name already exists in the release (exists → stop and ask)
- N, and the counts per rule value (e.g. Core/Edge, statuses)
- Owners and the e-mail each will be tagged with
- Source columns not copied

### 7. Create

Immediately before creating, search the release folder again for the file name — the check from step 6 is not enough.

1. Create the release folder only if the user asked for a new one (`create_file`, `contentMimeType: application/vnd.google-apps.folder`).
2. `copy_file` on `{TC_TEMPLATE_SHEET}` with `parentId` = release folder and `title` = file name. The copy keeps the coloured dropdowns, borders and header exactly.
3. `get_spreadsheet` on the copy: one tab; note its `sheetId`.

### 8. Fill — copy, never retype

Retyping non-ASCII text risks changing it. Copy inside Google Sheets instead. In one `update_spreadsheet` request where possible:

1. `copyPaste` (`PASTE_NORMAL`) template row 2 onto rows 3…N+1, so every data row has the sample row's format and dropdowns.
2. `copy_sheet_to_another_spreadsheet` — the source tab into the new file (arrives as `Copy of <tab>`).
3. One `copyPaste` (`PASTE_VALUES`) per mapped `copy` column, rows 2…N+1, from the copied tab into the template tab.
4. `update_values` for the rule columns with the rule values.
5. **Owner → people tag:** `updateCells` on the owner cells with
   `{"userEnteredValue":{"stringValue":"@"},"chipRuns":[{"startIndex":0,"chip":{"personProperties":{"email":"<e-mail>","displayFormat":"DEFAULT"}}}]}`
   (fields `userEnteredValue,chipRuns`). The chip then shows the person's name.
6. A URL (if any) → `=HYPERLINK("<url>","<visible text>")` with `update_formulas`.

### 9. Tidy the sheet

1. `deleteDimension` ROWS from N+1 to the end (keep header + N rows only).
2. `deleteDimension` COLUMNS after the last template column.
3. `updateBorders` on the whole table — `top`, `bottom`, `left`, `right`, `innerHorizontal`, `innerVertical` all `SOLID` width 1 — so every line is visible. Do not rely on the template's borders: a template can mix black and light-grey lines.
4. **No line may wrap:**
   - `repeatCell` `wrapStrategy: OVERFLOW_CELL` on the table, then `autoResizeDimensions` COLUMNS. Add 16 px to each resulting width.
   - Dropdown (chip) columns are wider than their text; auto-size leaves them too narrow. Set them by hand (measured: a `Core`/`Edge` column 110 px, a status column 140 px).
   - `repeatCell` `wrapStrategy: WRAP` back on the table.
5. **Row heights:** `autoResizeDimensions` on ROWS does not size multi-line cells (it set every row to 20 px in testing). Instead, in a temporary tab, put
   `=MAX(ARRAYFORMULA(LEN(T!A2:M2)-LEN(SUBSTITUTE(T!A2:M2,CHAR(10),""))+1))` (T = the template tab) and fill it down N rows (`copyPaste` `PASTE_FORMULA`);
   set each data row to `lines × 18 + 8` px and the header row to its template height. Check one known row first (a cell with 5 numbered steps must give 5).

### 10. Verify — in the sheet, with a control

1. Add a temporary tab `chk` with one formula per column comparing the template tab with the copied source tab,
   e.g. `=SUMPRODUCT(EXACT(T!A2:A16,'Copy of {ISSUE_KEY}'!C2:C16)*1)`; rule columns compare with the rule's value. Each must equal N.
2. `=ROWS(T!A:A)` must be N+1; `=COUNTA(T!A2:A)` must be N.
3. A **negative control** that must be 0 (compare a column with a different column). Not 0 → the check is broken; do not trust it.
4. Read `chk`, then delete `chk` and every copied tab. The file must end with the single template tab.
5. Read back with `get_spreadsheet`: every table cell has `SOLID` on all four sides; every owner cell has a `personProperties` chip with the expected e-mail; the dropdown cells keep `customUiMode: CHIP`.

Report as numbers: `rows N/N`, `cells X/Y`, `tags X/N`, `borders X/Y` — and say what each was measured from.
Borders and wrapping are what people **see**; API values are not proof of that. Ask the user to open the file and confirm before calling the job done.

### 11. Report

- Link to the new file
- The numbers from step 10
- Source columns not copied, and any value that needed a rule

## QA closing (mandatory before "done")

- [ ] The user confirmed the release folder, file name, counts and owner e-mails before anything was written.
- [ ] The file name was checked for a duplicate in the same turn as `copy_file`.
- [ ] No source text was retyped — every copied column came through `copyPaste` `PASTE_VALUES`.
- [ ] `chk` shows every column = N and the negative control = 0; `chk` and copied tabs are deleted.
- [ ] Only header + N rows and the template columns remain; every table cell has four solid borders.
- [ ] Every owner cell is a people chip with the mapped e-mail.
- [ ] The user opened the file and confirmed no line wraps and no missing borders.
