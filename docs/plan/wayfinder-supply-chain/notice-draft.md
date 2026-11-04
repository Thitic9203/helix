# ประกาศความเสี่ยงด้านความปลอดภัยของ Helix (ร่าง — ยังไม่เผยแพร่)

> ร่างสำหรับ ticket [Team notice](tickets/06-team-notice.md) · ปลายทางตามมติเจ้าของงาน 2026-11-04 คือไฟล์ในรีโป helix · เผยแพร่เมื่อเจ้าของงานอนุมัติข้อความ

## สรุปสั้น

ถ้าคุณติดตั้ง Helix ไว้ในเครื่อง ตอนนี้ Helix มีความเสี่ยง 4 ข้อ ทีมกำลังแก้ ระหว่างรอขอให้ทำตาม "สิ่งที่ทำได้ตอนนี้" ด้านล่าง

## ความเสี่ยง

1. **คำสั่งติดตั้งไม่ได้ล็อกเวอร์ชันและไม่ได้ตรวจไฟล์** — README ให้รัน `curl … | bash` จาก branch `main` โดยตรง ไม่มีการตรวจ checksum
2. **อัปเดตตัวเองแล้วรันโค้ดใหม่ทันทีทุกครั้งที่เปิด session** — hook ตอนเปิด session จะดึง release ล่าสุดแล้วรันสคริปต์ชุดใหม่ใน session นั้นเลย ไม่มีการตรวจลายเซ็น ถ้าต้นทางถูกเจาะ โค้ดอันตรายจะรันในเครื่องทุกคน
3. **สคริปต์ `helix-setup-devenv.sh` (เฉพาะคนที่เคยรัน)** — ใส่สิทธิ์กว้าง 45 กฎ เช่น `npx *`, `node *`, `python3 *`, `gh api *`, `bash scripts/*` ลงใน `~/.claude/settings.json` ตั้ง `defaultMode: acceptEdits` และใส่กฎ "ทำเลย ถามน้อยลง" ลงใน `~/.claude/CLAUDE.md` ระดับ global จากนั้นทุกครั้งที่อัปเดตจะใส่กลับเข้าไปเองโดยไม่ถาม
4. **อาจลบ skill ของคุณ** — ถ้าคุณมีโฟลเดอร์ skill ชื่อซ้ำกับ skill ของ Helix ตัวติดตั้งหรือตัวอัปเดตจะลบโฟลเดอร์นั้นทิ้ง แล้วแทนด้วยของ Helix

## เช็คเครื่องตัวเอง (อ่านอย่างเดียว ไม่เปลี่ยนอะไร)

```bash
# ติดตั้ง Helix ไว้ไหม และเวอร์ชันอะไร
git -C ~/.helix/tc-fe-prep describe --tags 2>/dev/null

# auto-update เปิดอยู่ไหม และเคยอัปเดตเมื่อไหร่
echo "HELIX_AUTO_UPDATE=${HELIX_AUTO_UPDATE:-<ไม่ได้ตั้ง = เปิดอยู่>}"
tail -n 20 ~/.helix/auto-update.log 2>/dev/null

# เคยรัน devenv ไหม (ถ้าขึ้น DEVENV OPTED IN = เคยรัน)
ls ~/.helix/.devenv-opted-in 2>/dev/null && echo "DEVENV OPTED IN"
grep -n 'HELIX-DEVENV' ~/.claude/CLAUDE.md 2>/dev/null
jq '.permissions.defaultMode' ~/.claude/settings.json 2>/dev/null
```

## สิ่งที่ทำได้ตอนนี้

1. **ปิด auto-update ไว้ก่อน** — ตั้ง `HELIX_AUTO_UPDATE=0` (`scripts/helix-auto-update.sh:7`) แล้วเปิด session ใหม่
   <!-- ยังไม่ verify (ต้องปิดก่อนเผยแพร่): ตั้งที่ไหนแล้ว hook ตอน SessionStart เห็นค่าจริง — shell profile (กรณีเปิด claude จาก terminal) หรือ `env` ใน ~/.claude/settings.json (กรณีแอป desktop) · ทดสอบด้วยการเปิด session แล้วดูว่า ~/.helix/auto-update.log ไม่มีบรรทัดใหม่ -->

2. **ถ้าเคยรัน devenv** — รัน `bash ~/.helix/tc-fe-prep/scripts/helix-setup-devenv.sh --uninstall` ขั้นตอนนี้จะลบกฎใน allowlist และบล็อกใน CLAUDE.md ออก แต่**จะไม่คืนค่า `defaultMode`** ให้เปิด `~/.claude/settings.json` แล้วลบหรือแก้ `"defaultMode": "acceptEdits"` เองถ้าคุณไม่ได้ตั้งไว้เอง และไฟล์สำรอง `*.helix-bak.*` จะยังอยู่
3. **อย่าติดตั้งใหม่ด้วย `curl … | bash`** จนกว่าจะมีเวอร์ชันที่แก้แล้ว
4. **เช็ค skill ของคุณ** — ถ้าเคยมี skill ชื่อเดียวกับ skill ของ Helix ในโฟลเดอร์ skill ของ agent (เช่น `~/.claude/skills/`) ให้ตรวจว่ายังอยู่ไหม

## สิ่งที่จะเปลี่ยนในเวอร์ชันที่แก้แล้ว

- ตอนเปิด session จะแค่แจ้งว่ามีเวอร์ชันใหม่ ไม่อัปเดตหรือรันโค้ดใหม่เอง คุณอัปเดตเองด้วยคำสั่ง
- วิธีติดตั้งจะล็อก release ที่ระบุ และตรวจ SHA-256 ก่อนรัน
- เลิกใช้ `helix-setup-devenv.sh` และมีคำสั่งถอนที่คืนค่าให้ครบ
- ตัวติดตั้งจะไม่ลบโฟลเดอร์ของคุณ ถ้าชื่อซ้ำจะข้ามแล้วแจ้งเตือนแทน

จะแจ้งอีกครั้งเมื่อเวอร์ชันที่แก้แล้วออก
