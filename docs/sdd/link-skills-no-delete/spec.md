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
  or exactly `../../skills/<name>` in workspace relative mode. The absolute form counts in both
  modes, so a workspace that switches to relative mode gets its old absolute links refreshed.
  Only these are "created by Helix". Decided by the raw target text so a **broken** Helix link is
  still recognised. A link into an older clone or an old plugin-cache path is **not** a Helix link
  (owner decision Q2, 2026-11-04): it is kept and warned about.
- **Helix cache link**: an entry directly under `~/.claude/plugins/cache/helix-dev/helix/` that is
  a symlink whose raw target names the clone: its logical or physical path as text, or a directory
  whose `pwd -P` is the clone (`setup.sh` uses the physical git top level, `install.sh` the logical
  `$REPO_DIR`). A link to any other place, or a broken one, is kept. Only these are deleted by
  `install.sh` / `setup.sh`.
- **Clash**: a skill entry that exists (`-e` or `-L`) and is not a Helix link.

## Scope

In: `scripts/link-skills.sh` `link_into()` (`:12-56`), all 15 folders it touches, the plugin-cache
cleanup in `scripts/install.sh:45-50` and `scripts/setup.sh:21-26` (owner decision Q1), clash
warnings in `scripts/helix-doctor.sh` `check_dest` (owner decision Q3), and their tests.

Out: the destination-is-a-symlink branch `:20-29` (unchanged); devenv leftovers in doctor (SDD
`retire-devenv`); the team notice (SPEC R5); `claude-plugin-sync.sh:72-76` cache delete (research
02 row 26, not named by R4).

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
| R10 | Warnings must go to stderr and stay visible when callers silence stdout. | `helix-auto-update.sh:115` sends both streams to the log; doctor shows clashes itself (R13) |
| R11 | When `install.sh` or `setup.sh` cleans `~/.claude/plugins/cache/helix-dev/helix/`, it must delete only Helix cache links (unlink the symlink, never `rm -r` through it) and must leave every other entry (real folder, file, symlink elsewhere) unchanged, printing one stderr line per kept entry. | owner decision Q1; `install.sh:45-49`, `setup.sh:21-25` |
| R12 | When `<cache>/<VERSION>` is still occupied after R11 by an entry that is not a Helix cache link, install/setup must not write into or over it, must warn, and must continue (exit 0 from that step). | owner decision Q1; `install.sh:50` `ln -sfn` writes inside a real folder |
| R13 | `helix-doctor.sh` must print one `WARN` per skill entry that clashes (exists, not a Helix link) in every folder it checks, naming the skill, the path and the fix, and must not count it as linked. | owner decision Q3 |

## Owner decisions (2026-11-04)

Recorded in `docs/plan/wayfinder-supply-chain/owner-decisions-2026-11-04.md`:

- **Q1 — plugin cache delete: in scope** → R11, R12.
- **Q2 — links into an old clone or old cache path: not Helix-owned; leave and warn** → Terms, R3.
  Measured for T6: every in-repo caller runs link-skills from the clone path (`install.sh:57`
  `$REPO_DIR`, `setup.sh:29` git top level, `helix-doctor.sh:166` `$REPO`,
  `helix-auto-update.sh:115` `$REPO`), so Helix itself never makes cache-path links; only a manual
  run through the cache path would.
- **Q3 — doctor shows skill-name clashes** → R13.

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
- R11: a fake cache holding a Helix cache link, a real folder, and a symlink elsewhere ends with only the Helix link removed; the clone's files are untouched; stderr names the 2 kept entries.
- R12: a real folder at `<cache>/<VERSION>` stays byte-identical, gets no link inside it, and the step exits 0 with a warning.
- R13: doctor on a fake home with a same-named user folder prints a `WARN` naming the skill and path, and does not report "all skills linked".
