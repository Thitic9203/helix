# Tasks — update-notify-only

Tests run offline. Setup used by `scripts/tests/update-notify.test.sh` (new, sourced `lib.sh`):
`W=$(mktemp -d)`; bare `origin.git` with tags `v1.0.0`, `v1.0.1`; at `v1.0.1`,
`scripts/link-skills.sh` and `scripts/claude-plugin-sync.sh` are executable stubs that `touch
"$W/sentinel-<name>"`; `$W/bin/claude` and `$W/bin/curl` stubs touch `$W/sentinel-claude` /
`$W/sentinel-curl` and are first on `PATH`; clone at `v1.0.0` in `$W/clone`; fake `HOME=$W/home`
with `~/.claude/skills/` and `~/.claude/plugins/cache/helix-dev/helix/` holding one symlink each.
"Snapshot" = `git -C clone rev-parse HEAD`, `git -C clone for-each-ref`, `git -C clone status
--porcelain`, `ls -laR` of both `~/.claude` dirs. "Hook" = `HOME=… HELIX_REPO_DIR=$W/clone
HELIX_STATE_DIR=$W/state bash hooks/session-start` from the repo under test.

| # | Task | Rule | Failing test first | Done when |
|---|------|------|--------------------|-----------|
| T1 | Hook leaves state untouched | R1, R2 | snapshot; run hook; snapshot again → `diff` empty, no `sentinel-*` (fails today: `:163` moves HEAD, `:114-120` run stubs) | passes |
| T2 | One notice line | R3, R5 | T1 setup: hook output parses as JSON (`python3 -c json.load`), contains exactly 1 line matching `v1.0.1 is available` and the update command (fails today: no notice) | passes |
| T3 | FORCE / interval cannot unlock the hook | R7, R9, R10 | rerun T1 with `HELIX_FORCE_UPDATE=1 HELIX_AUTO_UPDATE_INTERVAL_SEC=0` → snapshot unchanged, no sentinel (fails today: `:51` forces the fetch) | passes |
| T4 | No notice when current or ahead | R5 | clone at `v1.0.1`, then at an untagged commit after it → hook output has 0 notice lines | passes |
| T5 | Off switch | R8 | `HELIX_AUTO_UPDATE=0` → 0 notice lines; `auto-update.log` has no `ls-remote`/check line; no stamp file. Then `HELIX_AUTO_UPDATE=0 bash helix-auto-update.sh` (update mode) still moves to `v1.0.1` (fails today: `:191` exits) | passes |
| T6 | Offline check is quiet | R12 | origin path set to a missing dir → hook output valid JSON, 0 notice lines, no `last-update-error` (fails today: `:136` writes it) | passes |
| T7 | Stamp written by the check | R11 | after T2, `$W/state/.last-auto-update-check` exists and is within 5 s of `date +%s`; `doctor-stale.test.sh` unchanged and green | passes |
| T8 | No-clone check via tags | R3, R4 | remove `$W/clone`; `HELIX_REMOTE_URL=$W/origin.git`; run `helix-auto-update.sh --check` from a copy at `v1.0.0` → prints the notice; `sentinel-curl`, `sentinel-claude` absent (fails today: `:215` curls) | passes |
| T9 | Update command unchanged | R6 | run `bash helix-auto-update.sh` (no args, no FORCE) in T1 setup → clone at `v1.0.1`, both stub sentinels present once, cache symlink `1.0.1` exists | passes |
| T10 | Bad argument | R7 | `helix-auto-update.sh --chek` → exit 2, snapshot unchanged | passes |
| T11 | Existing suite adapted | R1, R5, R6, R12 | edit `auto-update.test.sh:57-67` to the new expectation first (fails until T1–T2 code lands); `:34-39` grep "update problem" | `bash scripts/tests/run.sh` green |
| T12 | Error tip text | R12 | write a `last-update-error`; hook output contains "Helix update problem" and `bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh`, not `HELIX_FORCE_UPDATE` | passes |
| T13 | Docs | R13 | grep check in `update-notify.test.sh`: `README.md`, `docs/wiki/Home.md`, `docs/DOC-MAP.md`, `scripts/install.sh`, `scripts/helix-doctor.sh` contain no "updates the next session", "auto-update hooks", "Disable auto-update" (fails today: `README.md:168`, `install.sh:60`, `README.md:166`) | passes; wording reviewed against spec R8–R10 |
| T14 | Migration dry run | R14 | test: clone at `v1.0.0` whose `scripts/helix-auto-update.sh` is the **old** script (fixture copy of 5eb2bb9's file), `v1.0.1` = this change; run the old script as the old hook does → clone at `v1.0.1`; then run the new hook → no move on a seeded `v1.0.2`, notice names `1.0.2` | passes |

Order: T1–T3 and T10 first (the safety core), then T4–T9, T11–T12, T14, T13 last.
Each commit message ends `Spec: docs/sdd/update-notify-only R<n>`.
