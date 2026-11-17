# Plan — taskfolio-log workflow

## Files touched
- `skills/taskfolio-log-workflow/SKILL.md` (new; R1–R9)
- `skills/taskfolio-log-workflow/scripts/tf.sh` (new; R10), `skills/taskfolio-log-workflow/scripts/vpn_check.sh` (new; R11)
- `commands/taskfolio-log.md` (new; R1)
- `references/menu-text.md`, `references/skill-routing.md`, `skills/helix/SKILL.md` (R12)
- `references/intent-shortcuts.md` (R1)
- `README.md`, `references/agent-entry.md`, `references/codex-tools.md`, `references/copilot-tools.md` (R13)
- `tools/r7-helix-one-question/check.test.js` (R14)

## Data / library
None added. Helpers use macOS `osascript`, `python3` (JSON-quote the JS), `scutil`, `ifconfig` — all built in.
Taskfolio URL and project mappings live in the user's workspace `references/taskfolio-guide.md` (not committed here).

## Options weighed
- Menu test (R14): (a) bump the pinned number 13 → 14 — rejected, breaks again on the next menu item;
  (b) derive N from menu-text and check SKILL.md against it — chosen (#127), checked against three wrong states.

## What could break
- Any test or doc that pins menu number 13 for Other — covered by R12/R14 and the full suite run.
- `references/copilot-tools.md` keeps "helix + ten `*-workflow` stubs" next to "12 skills" as in #127 (wording
  carried over from the source; not changed by this re-land).
- SKILL.md here differs from helix#20 (Contents + Must-read sections) until the after-merge helix sync.
- Skill line budgets / skill-lint must-read depth — checked by `tools/skill-lint`.
