# Plan — update-notify-only

Line numbers were first taken at `origin/main` 5eb2bb9 and re-read at 7a56f60 (see Decisions in spec.md; the script cites below are shifted by the devenv removal: `:50-67` stays, `:196-221` is now `:195-221`; README/wiki/install/doctor cites are listed in spec R13). `docs/sdd/retire-devenv/` also edits
`scripts/helix-auto-update.sh:223-228` and `hooks/session-start:25-41, :56`; whichever PR lands
second rebases and re-reads the numbers. This plan never re-adds the devenv block or tip.

## Files

| File | Change | Rule |
|------|--------|------|
| `scripts/helix-auto-update.sh:2-11` | header: "session start runs `--check` (read-only); no args = the update command the user runs" | R13 |
| `scripts/helix-auto-update.sh` (new arg parse, before `:190`) | `--check` → `MODE=check`; no args → `MODE=update`; anything else → usage, exit 2 | R6, R7 |
| `scripts/helix-auto-update.sh:43-48, :191-193` | `auto_update_disabled` applies to `MODE=check` only | R8 |
| `scripts/helix-auto-update.sh:50-67` | `should_run_check` deleted; check mode always probes, update mode always fetches; `HELIX_FORCE_UPDATE` / `HELIX_AUTO_UPDATE_INTERVAL_SEC` no longer read (one comment line says they are ignored) | R9, R10 |
| `scripts/helix-auto-update.sh:73-84` | `newest_remote_release` takes the remote: `origin` when a clone exists, else `HELIX_REMOTE_URL` (default the repo's GitHub `.git` URL, derived from the URL already in `claude-plugin-sync.sh:46`) | R3, R4 |
| `scripts/helix-auto-update.sh:95-101` | `local_version`: clone `VERSION`, else `$(dirname "$0")/../VERSION` | R3, Roles |
| new `run_check` (replaces `:196-221` for `MODE=check`) | `ls-remote` once; on failure `log` only (no `note_error`); on success `mark_checked`; if newer → print one line to **stdout**: `Helix vNEW is available (installed vOLD). Update: bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh`; `exit 0` before any other function is reachable | R3–R5, R7, R11, R12 |
| `scripts/helix-auto-update.sh:23, :91-93, :214-220` | delete the `curl` VERSION path; no-clone update mode runs `claude-plugin-sync.sh` (`:172-188`) only in `MODE=update` | R4, R6 |
| `scripts/helix-auto-update.sh:124-170, :103-122, :231-238` | unchanged, reached only in `MODE=update` | R6, R12 |
| `hooks/session-start:9-15` (notice goes into the agent context only, owner Q3) | `_notice="$(HELIX_QUIET=1 bash "$AU" --check 2>/dev/null \| head -1 \| tr -cd 'A-Za-z0-9 ._:/()+=,~-' \| cut -c1-200 \|\| true)"`; `update_tip` gets `**Helix update available:** ${_notice}. Tell the user once, briefly.` | R5, R7 |
| `hooks/session-start:17-23` | keep the error tip; change text "auto-update problem" → "Helix update problem", manual command → `bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh` | R12 |
| `scripts/tests/update-notify.test.sh` (new) | the Done-when matrix (below) | R1–R5, R7–R12 |
| `scripts/tests/auto-update.test.sh:16-17, :45-46` | drop `HELIX_FORCE_UPDATE=1` (no longer needed; still passes with it) | R6, R9 |
| `scripts/tests/auto-update.test.sh:34-39` | grep "update problem" instead of "auto-update problem" | R12 |
| `scripts/tests/auto-update.test.sh:57-67` | `run_session` = `bash "$AU" --check`; assert no move + notice printed; then `run_au` moves | R1, R5, R6 |
| `README.md:145-178` | heading "Updates: notify, then you update"; trigger table → session = check only, terminal = update; steps = what the update command does; env table: `HELIX_AUTO_UPDATE=0` "turn off the session-start check", `HELIX_FORCE_UPDATE` and `…_INTERVAL_SEC` "ignored since vX"; manual block → the R6 command; note "offline → no notice" | R13 |
| `README.md:293` | "Session start: check only (`--check`). No args: update to the newest release (run by you)" | R13 |
| `docs/wiki/Home.md:110-137, :175` | mirror the README text | R13 |
| `docs/DOC-MAP.md:9, :32` | "Update notice on session · update command" | R13 |
| `scripts/install.sh:58, :82` | `:58` "Enabling git hooks (cache rename on pull)…"; `:82` → the R6 command (only that hint line; install-block text/checksum logic belongs to R1) | R13 |
| `scripts/helix-doctor.sh:145-146, :156, :200` | wording "update check" instead of "auto-update"; `:200` → "Update: you run `bash …/helix-auto-update.sh`; session start only checks" | R11, R13 |

## Options weighed

| # | Option | For | Against | Pick |
|---|--------|-----|---------|------|
| A | One script, `--check` mode for the hook, no args = update | the documented manual command keeps working (`README.md:173`); one copy of the version compare; no rename (CLAUDE.md rule 5 asks before renames) | a bug in arg parsing could reach update mode from the hook → R7 test covers it | **A** |
| B | New `helix-update-check.sh` for the hook, keep `helix-auto-update.sh` as the update command | the hook's script cannot fetch by construction | two copies of `version_gt` / tag parsing; old hooks still call `helix-auto-update.sh` with no args = update → fine, but adds a file to every footprint list (research 02) | no |
| C | Rename to `helix-update.sh` + shim | clearer name | rename + shim + every doc; Q1 draft says keep names | no |
| D | Keep the interval to throttle `ls-remote` | fewer network calls | today already probes every session (`:63-66`); a throttle hides releases (the 1.5.105 case) | no (R10) |

Notice channel: the hook already embeds text in `additionalContext` (`hooks/session-start:56-64`);
writing to stderr is dropped (`2>/dev/null`). Context-only (owner Q3, 2026-11-04). No `/helix-update` command (Q2); `SECURITY-NOTICE.md` untouched (Q4).

Tools: bash, git, python3 (JSON check, already used by `auto-update.test.sh:39`). All free; no new
dependency, no network in tests (bare repo on disk, `file://`-free local path).

## What might break

- **Teammates stop getting releases on their own** — accepted in SPEC "Accepted limits" and ticket 03.
- **The one migration run**: the last old-style session start fetches this release and runs its
  `link-skills.sh` / `claude-plugin-sync.sh` (R14). That is today's trust level, once.
- **Hook output**: the notice comes from a script's stdout into JSON; a quote or backslash would break
  it → `tr -cd` allowlist + `head -1` + JSON test.
- **Hook latency**: `ls-remote` on a slow network blocks session start (sync hook). Same as today's
  probe. macOS has no `timeout`; option: `GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=5`
  env on the `ls-remote` call (git built-in, free). Add it; test not feasible offline beyond "env set".
- **Cursor**: `hooks-cursor.json` runs the same hook → same behaviour; no Cursor-specific code.
- **`helix-doctor.sh` freshness**: stamp now means "check ran"; a machine with `HELIX_AUTO_UPDATE=0`
  gets a stale warning as today (unchanged behaviour).
- **Claude Code's own plugin auto-update** (research 01 D4) can still refresh the plugin copy; out of
  scope, documented as a limit, not fixed here.
- **retire-devenv ordering**: if this lands first, `:223-228` is still present but only reachable in
  update mode — not at session start — so R2 holds either way.
