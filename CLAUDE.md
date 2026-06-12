# Helix — runtime context

## Auto-loaded docs (ไม่ต้องอ่านเอง AI จะได้ context อัตโนมัติ)

@docs/CONTRIBUTING.md
@docs/DOC-MAP.md
@CONTEXT.md

## Layout

| Skill | Path |
|-------|------|
| Helix (unified router) | `skills/helix/` |
| Workflow discovery stubs | `skills/{name}-workflow/SKILL.md` |
| Workflow procedures (canonical) | `skills/deprecated/{name}-workflow/WORKFLOW.md` |

Commands: `commands/helix.md` (canonical menu), plus one file per workflow.

## Contributor docs

Version, CI, ship checklist, quality bar, new skill template → [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

## Helix-specific overrides for Rule #5

ใน Helix project — ทำได้เลยไม่ต้องถาม:
- แก้ไข .md ไฟล์ใน skills/, references/, commands/, docs/
- เพิ่ม/ลบ menu item ใน commands/helix.md
- แก้ SKILL.md / WORKFLOW.md content (ไม่ใช่ rename/delete ไฟล์)
- แก้ scripts/ ที่ไม่ใช่ install.sh (install กระทบ user ทุกคน)
- อัปเดต VERSION, README.md, CONTEXT.md
- เพิ่ม reference ใหม่ใน references/

ต้องถามก่อน (ยังคง Rule #5):
- ลบ/rename skill directory ทั้ง folder
- แก้ install.sh, helix-auto-update.sh (กระทบ user ทุกคน)
- แก้ CI workflow (.github/workflows/)
- แก้ hooks/ config (กระทบ SessionStart)
- แก้ .claude-plugin/ (กระทบ marketplace)

## Default decisions (ไม่ต้องถาม ทำเลย)

### Naming & Structure
- Skill directory: skills/{name}/ + SKILL.md (discovery stub for workflows)
- Workflow procedure: skills/deprecated/{name}-workflow/ + WORKFLOW.md
- Command file: commands/{name}.md (thin entry, frontmatter + read SKILL.md)
- Reference file: references/{descriptive-name}.md (kebab-case)
- Branch: feat/{name}, fix/{name}, chore/{name}

### Content
- Skill content: portable (no hardcoded paths/IDs) — ตาม portable-content.md
- Language ใน skill files: English only
- Language ใน chat กับ user: Thai ได้
- Version bump: อัตโนมัติโดย CI, ไม่ต้อง manual bump
- Commit: conventional commits (feat:, fix:, chore:, docs:)

### Workflow
- ถ้าแก้ skill/command/reference → CI จะ auto-bump VERSION
- ถ้าเพิ่ม skill ใหม่ → สร้าง command file ด้วยเสมอ
- ถ้าเพิ่ม reference ใหม่ → ไม่ต้องแก้ DOC-MAP.md (ยกเว้นเป็น "single source of truth" document)
- ถ้า lint/format issue → แก้เลย

## Postmortem — lessons from past sessions

### Jira comment edit via Control Chrome JS (2026-06-12)

**Task:** PUT large ADF JSON (~33 KB) to edit existing Jira comment via browser JS.

**What failed:**

| Approach | Root cause |
|----------|-----------|
| Base64 chunk append (`window.__b += "..."`, 3000-char chunks) | LLM transcription error — ~4 chars corrupted per chunk when embedding base64 string in tool call parameter; corrupts JSON decode |
| `fetch('http://localhost:PORT/...')` from HTTPS Jira page | Chrome Private Network Access (PNA) silently drops HTTPS→HTTP localhost requests; Promise hangs, server receives nothing |
| Atlassian MCP `addCommentToJiraIssue` | MCP OAuth only grants access to the workspace it was authenticated against; will fail with "Cloud id isn't explicitly granted" for other workspaces |

**What worked:**

Embed full ADF JSON directly as a JS object literal inside a single `execute_javascript` `code` parameter:

```javascript
(function(){
  var body = {body: { /* entire ADF object literal, ~33 KB */ }};
  fetch('/rest/api/3/issue/OLS-22/comment/75215', {
    method: 'PUT',
    headers: {'Content-Type':'application/json','X-Atlassian-Token':'no-check'},
    body: JSON.stringify(body)
  }).then(function(r){return r.text();}).then(function(t){window.__editResult=t;});
})();
```

Then read result: `window.__editResult || "pending"`

**Why this works:** The MCP framework JSON-encodes the `code` string parameter automatically — no manual transcription of large strings, no LLM copying errors. The browser's existing auth session handles Jira authentication.

**Rules for future large-payload Jira edits:**
- Always use `execute_javascript` with full JSON embedded as object literal — never base64 chunking
- Never try to serve files from localhost to an HTTPS Jira page (PNA blocks it)
- Check `getAccessibleAtlassianResources` first — if the target workspace isn't listed, use Control Chrome instead of Atlassian MCP

---

## Workspace Guide Pattern (ใช้กับทุก workflow)

เมื่อ AI ต้องถามคำถามเกี่ยวกับ project-specific config:
1. ตรวจก่อนว่ามี .guide.md ที่ตอบคำถามนี้แล้วหรือยัง
2. ถ้ามี → ใช้คำตอบจาก .guide.md ไม่ต้องถาม
3. ถ้ายังไม่มี → ถาม user แล้วบันทึกลง .guide.md ทันที
4. Pattern นี้ใช้ได้กับทุก config: Jira domain, test env URL, preferred CSV format, default assignee ฯลฯ
