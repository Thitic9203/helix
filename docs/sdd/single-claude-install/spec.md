# Spec — single Claude Code install (plugin only)

Source: owner decision G2, 11/Nov/2026 — "keep the plugin, drop the symlinks" for Claude Code; owner approved changing `install.sh` for this.
Evidence: helix-quality wayfinder token-diet FINDINGS 2026-11-11, cause 4 — every Claude Code session lists the Helix skills twice (+2,268 tokens): once from `~/.claude/skills` symlinks made by `scripts/link-skills.sh`, once from the plugin `helix@helix-dev` that `scripts/install.sh` enables.

## Scope
`scripts/link-skills.sh`, `scripts/helix-doctor.sh`, `scripts/claude-plugin-sync.sh` (one message), README.md, docs/wiki/Home.md, docs/supported-agents.md, `scripts/tests/`. Not in scope: other agents' folders, workspace links, the plugin itself.

## Rules
- **R1** When `link-skills.sh` runs, the system must not create links under `~/.claude/skills`. Claude Code gets Helix only from the plugin.
- **R2** When `link-skills.sh` runs, the system must keep linking every other global folder (Cursor, Codex, Copilot, Gemini, Agents, Windsurf, Cline, OpenCode, Pi) and the optional workspace folders exactly as before.
- **R3** When `~/.claude/skills/<name>` is a Helix skill link (same `helix_is_skill_link` test, raw target in this clone's `skills/`, broken links included), `link-skills.sh` must remove that symlink (unlink only).
- **R4** The system must not remove or change a real folder, a file, or a symlink pointing anywhere else under `~/.claude/skills` (edge: a link into an older clone stays — same ownership rule as docs/sdd/link-skills-no-delete Q2).
- **R5** When R3 removed at least one link, the system must print exactly one line saying how many and why; when none were removed it prints nothing about it.
- **R6** Install and update reach R3 with no extra step: both already run `link-skills.sh` (install.sh step 3, helix-auto-update.sh, post-merge hook).
- **R7** `helix-doctor.sh` must not expect `~/.claude/skills` links, and must warn (with the fix command) when old Helix links are still there.
- **R8** README and wiki install sections must say Claude Code uses the plugin only.
- **R9** (reviewer finding on PR 23) When `helix@helix-dev` is not confirmed installed (`claude` not on PATH, or `claude plugin list` does not show it), `link-skills.sh` must not remove any `~/.claude/skills` link; it prints exactly one line saying how many Helix links were kept and how to finish (`claude-plugin-sync.sh`, then `link-skills.sh`). Install and update run link-skills before plugin sync, so on a first run the links go on the next run, once the plugin is there.

## Done when
- A test shows `~/.claude/skills` gets 0 Helix links after link-skills (fails on old code with N links).
- A test shows old Helix links are removed, foreign entries kept, one notice line.
- A test shows that with the plugin not confirmed, 0 links are removed and one "kept" line is printed (fails on code that removes unconditionally).
- Doctor test shows no "Claude Code: all … linked" expectation and a WARN for leftovers.
- `bash scripts/tests/run.sh` and the three ci-check scripts pass.
