# Plan — retire-devenv

Line numbers are at `origin/main` e9955a9.

## Files

| File | Change | Rule |
|------|--------|------|
| `scripts/helix-setup-devenv.sh:1-17` | header: "retired — undo only"; drop the opt-in usage lines | R1 |
| `scripts/helix-setup-devenv.sh:29-43` | keep `ALLOW_RULES` as-is, renamed `SHIPPED_RULES` with a comment "every rule any version shipped (8894507, blob c925107)" — the undo needs it | R2 |
| `scripts/helix-setup-devenv.sh:45-62` | keep `RULES_BLOCK` only if a test needs it; the undo needs only the markers `:26-27` | R6 |
| `scripts/helix-setup-devenv.sh:81-94, :109-136` | delete `merge_settings` and `write_claude_md` | R1 |
| `scripts/helix-setup-devenv.sh:96-107` | rewrite `unmerge_settings`: find oldest backup, R2 removal with keep-list, R5 `defaultMode`, R4 byte restore or in-place edit, backup only if the result differs | R2–R5, R8, R9 |
| `scripts/helix-setup-devenv.sh:138-158` | rewrite `remove_claude_md`: remove block, R6 byte restore from oldest `CLAUDE.md.helix-bak.*` when equal after trim | R6, R8, R9 |
| `scripts/helix-setup-devenv.sh:160-177` | `--uninstall` → undo + `rm -f` marker and `.devenv-notice-count`; any other argument (incl. none) → if the marker exists run the same undo, otherwise touch nothing; print "retired" + undo command, exit 0 | R1, R7, R13 |
| `scripts/helix-auto-update.sh:223-228` | delete the block | R10 |
| `hooks/session-start:25-41` | delete the tip block | R11 |
| `hooks/session-start:56` | drop `${devenv_tip}` from `session_context` | R11 |
| `scripts/tests/devenv-undo.test.sh` (new) | all byte-equal / idempotence / no-op checks below | R1–R9 |
| `scripts/tests/fixtures/helix-setup-devenv.v1.sh` (new) | exact copy of the shipped opt-in script; the test asserts `git hash-object` = c925107 | R2, test setup |
| `scripts/tests/auto-update.test.sh` | add: marker present + update happens → no `helix-setup-devenv` line in the log, settings untouched | R10 |
| `scripts/tests/hook-exec.test.sh` or new check in `devenv-undo.test.sh` | run `hooks/session-start` with a fake `$HOME` (no marker, count 0) → output has no `helix-setup-devenv` | R11 |
| `scripts/helix-doctor.sh` | new section "Devenv leftovers": WARN per leftover (shipped rule in `settings.json`, block in `CLAUDE.md`, marker, Helix-set `defaultMode`), each naming the undo command; read-only, reuses the SHIPPED_RULES list via a sourced lib `scripts/lib/devenv-rules.sh` | R14 |
| `scripts/lib/devenv-rules.sh` (new) | the shipped-rules list, markers; sourced by the script and by doctor so there is one copy | R2, R14 |
| `README.md:235-243` | replace the opt-in paragraph with: "retired; if you ran it, undo with `bash scripts/helix-setup-devenv.sh --uninstall`" | R12 |
| `README.md:300` | contributor list: `helix-setup-devenv.sh` (retired — `--uninstall` only) | R12 |
| `docs/CONTRIBUTING.md:15-31` | Layer 2 section → retired notice + undo command; drop the auto-sync and SessionStart tip text | R12 |
| `docs/wiki/Home.md:182` | row text → "Retired — undo only (`--uninstall`)" | R12 |

Not touched: `.claude/settings.json` (project scope, out of SPEC R3); `SECURITY-NOTICE.md`
(wording is updated later with the fixed release — owner decision Q5);
`docs/plan/**` (history).

## Data

- **Oldest backup:** `ls "$f".helix-bak.* | sort | head -1`. Names are `YYYYmmddHHMMSS` (`:77`), so
  lexical order = time order. Only this script writes `*.helix-bak.*`: `git log --all -S'helix-bak'`
  → 4 commits (8894507 adds the script; 176b94f, 2191f85, e9955a9 touch only docs / `README.md` /
  `SECURITY-NOTICE.md`); `git grep -l helix-bak -- ':!docs/'` → this script and `SECURITY-NOTICE.md`.
- **Keep-list (R2):** `SHIPPED_RULES ∩ oldest_backup.permissions.allow`. Removed =
  `SHIPPED_RULES − keep-list`. With no backup, keep-list is empty.
- **Equality for R4:** `jq -S '.permissions.allow |= (. // [] | sort)'` on both sides, then compare.
  Equal → `cp` backup bytes over `settings.json`. Not equal → write the `jq` result.
- **R6 compare:** strip the block and the separator `:129-130` added, then compare with the oldest
  `CLAUDE.md.helix-bak.*` after `rstrip("\n")` on both. Equal → `cp` backup bytes. Not equal → keep
  today's `:149-151` logic.
- **No-write rule (R8/R9):** compute the result in a temp file; `cmp -s` with the current file;
  only when different: backup, then `mv`.

## How "Helix set defaultMode" can be known

Nothing records it today (marker holds only `date +%s`; `:90` logs nothing). Owner decision Q1 =
option A: the only on-disk signal is the backup taken just before the first merge (`:85`). Remove
`defaultMode` only when the current value is `acceptEdits` and the oldest settings backup has no
`defaultMode`; with no backup, leave it and print how to check by hand. Known limit: a user who set
`acceptEdits` themselves after opt-in, with none before, loses it.

## Libraries / cost

Bash, `jq`, `python3`, `cmp`, `sort` — `jq` and `python3` are already required by this script
(`:66-72`, `:118`). No new dependency, no paid service, no other repo touched. New cost: none.

## Options weighed

1. **Delete the script** — simplest, but leaves opted-in machines with no undo, and the old updater
   (`:225` checks `-x`) silently stops. Rejected: SPEC R3 needs an undo.
2. **Keep the script as undo-only (chosen)** — `--uninstall` is the same command users already know
   (`SECURITY-NOTICE.md:41`, README, CONTRIBUTING).
3. **Separate `helix-undo-devenv.sh`** — clearer name, but every doc and the notice already name
   `--uninstall`; two commands to explain. Rejected.

## What may break

- **Opted-in machines on an old updater:** at their next update, `:227` runs the new script with no
  arguments. With the marker present, R1 makes that run the full undo (owner decision Q2); the result is
  logged in `~/.helix/auto-update.log`.
- **Users who change settings after opt-in:** R4 falls back to an in-place edit; their own rule order
  is not restored. The script prints this.
- **Tests:** no existing test mentions devenv (`grep -rn -i devenv scripts/tests` → 0 lines), so
  none break. The new test needs `jq` and `python3`; CI runs on `ubuntu-latest`
  (`.github/workflows/*.yml:24, :72`). Whether `jq` is preinstalled there is not verified here —
  the first CI run shows it.
- **Doctor:** `scripts/helix-doctor.sh` has no devenv, `settings.json` or `helix-bak` reference
  (grep → 0 lines); nothing breaks. The residue warning is R14 (owner decision Q4).
- **README / wiki / CONTRIBUTING:** the CONTRIBUTING anchor `#dev-environment--fewer-agent-questions-two-layers`
  is linked from `docs/wiki/Home.md:182`; keep the heading or update the link in the same commit.
