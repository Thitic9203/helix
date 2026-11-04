# Spec — link-skills never deletes what Helix did not create

## Problem

`scripts/link-skills.sh` links every shipped Helix skill into each agent skill folder. When a
folder entry already has a Helix skill's name and is **not** a symlink, it runs `rm -rf` on it
(`scripts/link-skills.sh:43-45`) and then links the Helix skill in its place (`:53`). A user's own
skill of the same name is lost, with no backup and no message. This runs at install, at
`setup.sh`, at `helix-doctor.sh` fix (`scripts/helix-doctor.sh:166`), and after every update
(`scripts/helix-auto-update.sh:114-117`). The owner decided on 2026-11-04: **skip and warn**
(`docs/plan/wayfinder-supply-chain/SPEC.md` R4; ticket 07 "Resolution").

Evidence (worktree at `origin/main` 56def8b, read 2026-11-04):

| Place | What it does today |
|-------|--------------------|
| `scripts/link-skills.sh:18` | skips a destination whose parent folder (e.g. `~/.claude`) does not exist |
| `scripts/link-skills.sh:20-29` | skips a destination that is itself a symlink resolving into the repo |
| `scripts/link-skills.sh:31` | `mkdir -p` the skills folder |
| `scripts/link-skills.sh:33-36` | one entry per `SKILL.md`, excluding `in-progress/` and `procedures/` |
| `scripts/link-skills.sh:43-45` | `rm -rf` any existing non-symlink (folder **or file**) with the skill's name |
| `scripts/link-skills.sh:47-53` | `ln -sfn` to `$src` (absolute) or `../../skills/<name>` (workspace relative mode); `-f` replaces **any** existing symlink, including one the user made that points elsewhere |
| `scripts/link-skills.sh:43` | `[ -e ]` follows links, so a broken symlink is not caught by `:43` and is replaced by `:53` |
| `scripts/link-skills.sh:10` | `REPO` = `cd … && pwd` (logical path, not `pwd -P`) of the script's parent; the script can be run through the plugin-cache symlink (`helix-doctor.sh:166` runs `$REPO/scripts/link-skills.sh`) |
| `scripts/link-skills.sh:62-73` | 10 global folders: `~/.claude/skills`, `~/.cursor/skills`, `~/.codex/skills`, `~/.copilot/skills`, `~/.gemini/skills`, `~/.agents/skills`, `~/.codeium/windsurf/skills`, `~/.cline/skills`, `~/.config/opencode/skills`, `~/.pi/agent/skills` |
| `scripts/link-skills.sh:82-105` | opt-in `HELIX_LINK_WORKSPACE`: 5 project folders `.github/skills`, `.agents/skills`, `.windsurf/skills`, `.cline/skills`, `.gemini/skills`; relative links when the workspace has its own `skills/helix/SKILL.md` (`:88-91`) |
| `scripts/install.sh:45-49`, `scripts/setup.sh:21-25` | `rm -rf` every entry under `~/.claude/plugins/cache/helix-dev/helix/*/` (research 02 row 12) — see Q1 |
| `scripts/tests/link-skills.test.sh` | checks link count, exclusions, every link resolves; no clash case |

## Terms

- **Skill entry**: `<skills folder>/<name>` where `<name>` is a shipped Helix skill (`:33-41`).
- **Helix link**: a skill entry that is a symlink whose raw target (`readlink`, not resolved) is
  either `<clone>/skills/…/<name>` — `<clone>` being the logical or physical (`pwd -P`) repo path —
  or exactly `../../skills/<name>` in workspace relative mode. Only these are "created by Helix".
  Decided by the raw target text so a **broken** Helix link is still recognised.
- **Clash**: a skill entry that exists (`-e` or `-L`) and is not a Helix link.

## Scope

In: `scripts/link-skills.sh` `link_into()` (`:12-56`), all 15 folders it touches, and
`scripts/tests/link-skills.test.sh`.

Out: what `install.sh` / `setup.sh` delete in the plugin cache (Q1); the destination-is-a-symlink
branch `:20-29` (unchanged); `helix-doctor.sh` reporting (Q3); the team notice (SPEC R5);
`claude-plugin-sync.sh:72-76` cache delete (research 02 row 26, not named by R4).

## Rules

| # | Rule | Source |
|---|------|--------|
| R1 | When a skill entry is a real folder or file (not a symlink), link-skills must leave it exactly as it was (no delete, move, rename or write inside it) and must not link that skill in that folder. | SPEC R4; ticket 07 Resolution; `link-skills.sh:43-45` |
| R2 | When R1 or R3 skips an entry, link-skills must print one line naming the skill, the full path, and how to resolve it (rename or remove your own entry, then re-run `bash <clone>/scripts/link-skills.sh`). | SPEC R4 "prints the clash"; ticket 07 "prints the clashing name, its path, and how to resolve" |
| R3 | When a skill entry is a symlink that is not a Helix link (working or broken), link-skills must leave the symlink unchanged and warn per R2. | SPEC R4 "never … anything Helix did not create"; `link-skills.sh:53` (`ln -sfn` replaces it today) |
| R4 | When a skill entry is a Helix link (working, stale or broken), link-skills must replace it with the current link, as today. | `link-skills.sh:53`; Terms "Helix link" |
| R5 | When no entry exists, link-skills must create the link, as today. | `link-skills.sh:53-54` |
| R6 | link-skills must never run `rm -rf` (or `rm -r`, `mv`, `ln -f` over an entry) on any path that is not a Helix link. | SPEC R4 |
| R7 | R1–R6 must hold in all 10 global folders (`:62-73`) and all 5 workspace folders (`:93-99`), in both absolute and relative link modes. | `link-skills.sh:62-105` |
| R8 | A clash must not stop the run: other skills and other folders must still be linked, and the script must exit 0 when clashes are its only problem. | SPEC R4 "skips that skill"; callers `install.sh:57` (`set -e`), `helix-auto-update.sh:115-116` (non-zero = error notice) |
| R9 | Re-running link-skills with the same clash must give the same result: entry intact, the same warning again, no new files or links for that skill. Re-running with no clash must change nothing (links already current). | ticket 07 (runs at install and every update) |
| R10 | Warnings must go to stderr and stay visible when callers silence stdout. | `helix-auto-update.sh:115` sends both streams to the log; see Q3 for doctor's `2>/dev/null` |

## Owner questions

- **Q1 — plugin cache delete.** `install.sh:45-49` / `setup.sh:21-25` `rm -rf` every entry under
  `~/.claude/plugins/cache/helix-dev/helix/`. Entries there can be Helix's own version symlinks
  (`install.sh:50`) **or** plugin copies written by the `claude` CLI through
  `claude-plugin-sync.sh` (research 02 rows 21–23; exact files not determined). Neither is a user
  file, but the second is not "created by Helix scripts". Should R4/R6 cover it (e.g. delete only
  symlinks there), or stay out of scope? Default in this spec: out of scope, unchanged.
- **Q2 — links into an older clone or plugin-cache path.** A link made when `REPO` was a
  cache-version path (`…/cache/helix-dev/helix/<old>/skills/<name>`) or a previous
  `HELIX_REPO_DIR` is not a Helix link under the Terms above, so it would be kept and warned about
  instead of refreshed. Should those prefixes also count as Helix links? Default: no (warn only);
  task T6 measures whether such links occur today.
- **Q3 — doctor.** `helix-doctor.sh:166` runs link-skills with `2>/dev/null`, so R10 warnings are
  hidden there. Should doctor show clashes? Default: out of scope here.

## Done when

- R1: a fake `$HOME` with a same-named user folder ends with the folder byte-identical (checksum) and no link for that skill there.
- R2: the run's stderr has exactly one line per clash with the skill name, its path, and the re-run command.
- R3: a user symlink to elsewhere and a broken user symlink both keep their `readlink` text and are warned about.
- R4: a broken Helix link and a link to an old path inside the clone are both replaced with the current target.
- R5: an empty skills folder gets every shipped skill linked (existing test stays green).
- R6: `grep -n 'rm -rf' scripts/link-skills.sh` returns nothing; the R1–R4 tests pass.
- R7: the clash test runs in one global and one workspace folder, absolute and relative mode.
- R8: with a clash, exit code is 0 and every other skill is linked.
- R9: two runs in a row give identical `ls -la` / checksums and the same warning lines.
- R10: warnings appear with stdout sent to `/dev/null`.
