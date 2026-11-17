# Spec — taskfolio-log workflow

Status: owner-approved re-land (2026-11-12: "เขียน spec แล้วเปิด PR ใหม่") of fork PR #127 · offline tests · no env access

Sources: the diff of fork PR Thitic9203/ols-qa#127 at `3b0a983` ("#127") and its origin Thitic9203/helix#20
(open). Each rule cites the file in #127 that carries it. Live behaviour on Taskfolio is **not** verified
(#127 body: "Not done: a live run on Taskfolio").

## Rules — the skill (`skills/taskfolio-log-workflow/SKILL.md`)

- **R1** — เมื่อผู้ใช้พิมพ์ `/taskfolio-log` หรือ "ลง taskfolio", "ลง timesheet", "ลงเวลางาน", "fill taskfolio",
  "log timesheet" ระบบต้องโหลด `taskfolio-log-workflow` (SKILL.md frontmatter `description` + `proactive_triggers`;
  `commands/taskfolio-log.md`; `references/intent-shortcuts.md`).
- **R2** — เมื่อเงื่อนไขก่อนเริ่มไม่ครบ (macOS + Chrome "Allow JavaScript from Apple Events", Taskfolio week page
  เปิดและล็อกอิน, Taskfolio URL จาก `references/taskfolio-guide.md` ของ workspace, `scripts/vpn_check.sh` → `VPN_OFF`,
  connector Atlassian/Slack/Google Calendar) ระบบต้องหยุดและบอกสิ่งที่ต้องแก้ ต้องไม่เริ่ม step 2; source ที่ขาดต้องรายงาน
  ต้องไม่ตีความเป็น "ไม่มีงาน" (SKILL.md "Refusal-first").
- **R3** — Step 1 ต้องอ่านเฉพาะวันถึง **วันนี้** ตาม timezone ผู้ใช้ (default Asia/Bangkok) และต้องไม่แตะวันในอนาคต.
- **R4** — Step 2 ต้องเก็บหลักฐานต่อวันจาก Jira (`updatedBy` ด้วย accountId), bug ที่ผู้ใช้เปิด, Slack (sent + mentions),
  Calendar (ตัด event ที่ decline) แล้วเขียน evidence list ต่อวัน.
- **R5** — Step 3 ต้องเสนอตารางต่อวัน (Start–End, Entry, Action, Project, Subcategory, Evidence) เป้าอย่างน้อย 8 ชม./วัน
  (ขั้นต่ำ ไม่ใช่เพดาน), ทุก entry ต้องมี Project (Jira = `jira-<prefix>`; ไม่รู้ = ถามแล้วบันทึกลง guide) และต้องรอ
  ผู้ใช้ยืนยันก่อนบันทึก.
- **R6** — Step 4 (validation gate) ต้องรันบนตารางสุดท้ายก่อนขอยืนยันและอีกครั้งก่อนบันทึก แสดงทุกข้อ ✅/❌
  (Time / Project / Completeness) และต้องไม่บันทึกขณะยังมี ❌.
- **R7** — Step 5 ต้องบันทึกทีละ entry หลังผู้ใช้ยืนยัน, อ่าน Project/Start/End/Logged กลับจาก dialog ก่อน save
  (ไม่ตรง = แก้ ห้าม save) และต้องไม่ re-submit entry ที่ "ดูเหมือนหาย" ก่อน reload.
- **R8** — Step 6 ต้อง reload แล้วเทียบทุก entry ของทุกวันที่ยืนยันกับตารางทีละแถว; ไม่ตรง = แก้แล้วตรวจซ้ำ สูงสุด 2 รอบ
  แล้วรายงานสิ่งที่ยังผิด.
- **R9** — ระบบต้องไม่กด **Submit week** ไม่ว่ากรณีใด; close-out ต้องมี `Verified:` พร้อมจำนวน entry ที่ save/delete
  ต่อวัน ยอดต่อวัน และยอดสัปดาห์เทียบ 40 ชม.; ต้องไม่ทำงาน leave, timesheet ของคนอื่น, Jira worklog.

## Rules — helpers (`skills/taskfolio-log-workflow/scripts/`)

- **R10** — `tf.sh <file.js> [tab-url-substring]` ต้องรัน JS ในแท็บ Chrome แรกที่ URL มี substring (default
  `taskfolio`) ผ่าน `osascript -l JavaScript` แล้วพิมพ์ผล; ไม่มีไฟล์ = พิมพ์ usage และ exit 2; ไม่เจอแท็บ = พิมพ์ `NO TASKFOLIO TAB`.
- **R11** — `vpn_check.sh` ต้องพิมพ์ `VPN_ON` (พร้อมรายละเอียด) เมื่อ `scutil --nc list` มีบรรทัด `* (Connected)` หรือ
  `utun` มี `inet 10.` และพิมพ์ `VPN_OFF` เมื่อไม่ใช่.

## Rules — menu and routing

- **R12** — เมนู (`references/menu-text.md`) ต้องมีข้อ 13 **Taskfolio Log** และ **Other** ย้ายเป็น 14; "Reply with **1**–**14**".
  `references/skill-routing.md` ต้องมีแถว 13 → `taskfolio-log-workflow` / `/taskfolio-log` และแถว handoff "do not"
  (Submit week, leave, คนอื่น, Jira worklogs). `skills/helix/SKILL.md` ทุกช่วง/เลข Other ต้องเป็น 1–14 / 14.
- **R13** — README (ตาราง commands), `references/agent-entry.md` (รายการ command, จำนวน skill 12 / helix + 11 stubs, แถว
  intent), `references/codex-tools.md` (helix + 11 stubs), `references/copilot-tools.md` (12 skills) ต้องนับ skill ใหม่.
- **R14** — `tools/r7-helix-one-question/check.test.js` ต้องอ่านเลข Other จาก menu-text (ข้อสุดท้าย) แล้วตรวจว่าเลขข้อเรียง
  1..N ไม่มีช่องว่าง, "Reply with" บอก 1–N และทุกช่วง/เลข Other ใน `skills/helix/SKILL.md` = N (แทนการ pin ที่ 13).

## Out of scope

- The helix side: helix#20 stays as is; after merge, sync from main per CLAUDE.md helix-sync rule
  (`HELIX_SYNC_NEW=1 bash scripts/sync-skills-to-helix.sh <files>` then `bash scripts/helix-parity.sh`).
- `AGENTS.md` (lists only the five core workflows; unchanged in #127).
- A live Taskfolio run.

## Done when

- `node tools/r7-helix-one-question/check.test.js` and `node tools/skill-lint/lint.js` pass with the new skill.
- `bash scripts/run-test-suites.sh` and `node tools/sdd-gate/check.js --base origin/main` exit 0 on the code PR.
- Code PR body records the after-merge helix sync step.
