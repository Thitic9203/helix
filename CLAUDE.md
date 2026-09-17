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

<!-- rule:token-context-budget v1 · ข้อความชุดเดียวกันทุก repo (มีฉบับไทยและอังกฤษ) · แก้ที่ใดต้องแก้ทุก repo -->
## Token & context budget (กฎเหล็ก)

**ความถูกต้องและความครบมาก่อนการประหยัดเสมอ** ห้ามข้ามการอ่านสเปก การรันเทสต์ การ verify หรือการเก็บหลักฐานเพื่อลด token
ถ้าทางที่ถูกแพงกว่า ให้เลือกทางที่ถูกแล้วหาวิธีเดินทางนั้นให้ถูกลง · context ที่ใกล้เต็มทำให้โมเดลลืมคำสั่งช่วงต้นและพลาดง่ายขึ้น
เพดาน 70% จึงเป็นเรื่องคุณภาพพอๆ กับเรื่องค่าใช้จ่าย

**อ่านเท่าที่งานต้องใช้ ด้วยสกิลจัดการ context ที่ตรงงาน — เรียกเมื่อจำเป็น ไม่โหลดเผื่อ**
- output ที่อาจใหญ่ (log · ผลเทสต์ · JSON · API · หน้าเว็บ · ไฟล์ข้อมูล) → สกิล `context-mode` (`ctx_execute` · `ctx_batch_execute` · `ctx_fetch_and_index` แล้ว `ctx_search`) ให้เข้า context เฉพาะคำตอบที่สรุปแล้ว · ไม่มีสกิลนี้ให้กรองก่อนอ่าน (`rtk` · `grep` · `jq` · `tail`)
- โค้ด → หาตำแหน่งก่อนอ่าน (Grep/Glob หรือสกิล `smart-explore` ระดับ symbol) แล้ว Read เฉพาะช่วงด้วย offset/limit · ห้ามเปิดไฟล์ยาวทั้งไฟล์เมื่ออ่านแค่ช่วงก็พอ
- สำรวจกว้างหลายไฟล์หรือหลายแหล่ง → ส่ง subagent อ่านแทน รับกลับเฉพาะข้อสรุปพร้อม `path:line` · ของที่รู้ตำแหน่งแล้วทำเองตรงๆ ถูกกว่า
- หน้าเว็บใช้ข้อความหรือ accessibility tree ก่อน screenshot · ไม่อ่านไฟล์ที่เพิ่งเขียนเองซ้ำ · ไม่แปะเนื้อไฟล์ยาวในแชท ให้อ้าง path
- สกิลที่โหลดแล้วใน session ไม่ต้องเรียกซ้ำ · tool call ที่ไม่ขึ้นต่อกันให้ส่งพร้อมกันในรอบเดียว

**วัด context จริงทุกครั้งที่จบขั้นงานใหญ่ — ห้ามเดาเลข**
- รวม `input_tokens + cache_creation_input_tokens + cache_read_input_tokens` ของ assistant message ล่าสุดใน transcript `~/.claude/projects/*/<session-id>.jsonl` (session-id อยู่ใน `$CLAUDE_SESSION_ID` หรือ `$CLAUDE_CODE_SESSION_ID`) แล้วหารด้วยขนาด context window ของโมเดล หรือให้ user รัน `/context` · วัดไม่ได้หรือไม่รู้ขนาด window ให้ถาม user
- ถึง 60% → เขียน checkpoint ลงไฟล์: เสร็จอะไรแล้ว · หลักฐาน · ขั้นต่อไป · ไฟล์ที่ต้องอ่านต่อ
- ถึง 70% → หยุดดึงข้อมูลดิบเข้า context งานอ่านที่เหลือส่ง subagent แล้วแจ้ง user พร้อมเสนอ `/compact <สิ่งที่ต้องเก็บ>` หรือเปิด session ใหม่ต่อจาก checkpoint

**CLAUDE.md โหลดทุก session** → ใส่เฉพาะกฎที่ต้องใช้ทุกครั้งและเขียนให้สั้น · รายละเอียด ขั้นตอนยาว และประวัติเหตุการณ์ ย้ายไปสกิลหรือเอกสารที่อ่านเมื่อต้องใช้ พร้อมระบุว่าต้องอ่านเมื่อไร (เอกสารทางการแนะนำไม่เกิน 200 บรรทัด และไฟล์ที่ `@import` ยังโหลดตอนเริ่ม session)

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
