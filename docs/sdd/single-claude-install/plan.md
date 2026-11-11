# Plan — single Claude Code install

## Files
- `scripts/link-skills.sh`: drop `~/.claude/skills|claude` from `GLOBAL_DESTS`; add `remove_old_claude_links` that loops `~/.claude/skills/*`, unlinks entries where `helix_is_skill_link <entry> <basename> 0 $REPO $REPO_P` is true (R3, R4), prints one line with the count (R5).
- `scripts/helix-doctor.sh`: drop Claude Code from `GLOBAL_DESTS`; new check counts leftover Helix links in `~/.claude/skills` → WARN naming `link-skills.sh` (R7).
- `scripts/claude-plugin-sync.sh`: no-CLI message no longer claims `~/.claude/skills` fallback.
- Tests: new `scripts/tests/single-claude-install.test.sh`; move tests that used `~/.claude/skills` as the sample global folder to `~/.cursor/skills` (link-skills, doctor-clash, doc-skill-lists) — same assertions, different folder.
- Docs: README.md, docs/wiki/Home.md, docs/supported-agents.md.

## Options weighed
- Keep symlinks, drop plugin: rejected by owner (G2); plugin carries hooks + slash commands.
- Remove links in install.sh only: misses users who update via auto-update/post-merge. Doing it inside link-skills.sh covers all paths (R6).

## Risk
- A user with Claude Code but no `claude` CLI on PATH would get no plugin sync; the plugin cache link (install step 2) and enablement are unchanged, so only first-time enablement depends on the CLI — same as today. No new cost, no other repo touched.
