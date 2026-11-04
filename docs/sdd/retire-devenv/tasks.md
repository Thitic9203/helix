# Tasks — retire-devenv

Every test runs in `scripts/tests/devenv-undo.test.sh` unless named otherwise, on a throwaway
`HOME` (`mktemp -d`), with `CLAUDE_CONFIG_DIR=$HOME/.claude` and `HELIX_STATE_DIR=$HOME/.helix`.
"Old opt-in" = run `scripts/tests/fixtures/helix-setup-devenv.v1.sh` (blob c925107) with no
arguments on that `HOME`. "Pre" = copies of `settings.json` / `CLAUDE.md` taken before that run.

| # | Task | Rule | Failing test first | Done when |
|---|------|------|--------------------|-----------|
| T0 | Add the v1 fixture | — | test: `git hash-object fixtures/helix-setup-devenv.v1.sh` = c925107… → fails until the file exists | hash matches; old opt-in on a fake `HOME` writes the 45 rules, the block and the marker |
| T1 | No-arg run is a no-op | R1 | test: clean fake `HOME`, run new script with no args → `find $HOME -type f` is empty (fails today: `:170-172` write 3 files) | exit 0, prints "retired" + undo command, no file created |
| T2 | Byte-equal undo, plain case | R2, R4, R6, R7 | test: Pre = settings with a user rule + other key, CLAUDE.md with user text; old opt-in; `--uninstall` → `cmp` Pre vs both files, marker absent (fails today: `:91` sorted rules, `:151` newlines) | `cmp` passes for both files |
| T3 | Missing files before opt-in | R4, R6 | test: no `settings.json` / `CLAUDE.md` before; old opt-in; undo → `settings.json` bytes = `{}\n`, `CLAUDE.md` is empty (fails today: `defaultMode` left, CLAUDE.md = `\n`) | both byte-equal to the oldest backups |
| T4 | Pre-existing listed rule kept | R2 | test: Pre allow has `Bash(git status)`; old opt-in; undo → still present, printed as kept (fails today: `:104` removes it) | rule present; output names it |
| T5 | `defaultMode` | R5 | test a: Pre has `defaultMode: "plan"` → kept. test b: Pre has none → removed after undo (fails today: `:106` keeps it). test c: delete all backups → kept, one hint line printed | all three pass |
| T6 | Later user edit | R3, R4 | test: after old opt-in, add rule `Bash(make *)` and key `"x":1`; undo → both present, 45 rules gone, message about order printed | passes |
| T7 | Partly undone + idempotent | R8, R9 | test: old opt-in, then fixture `--uninstall` (today's undo), then new `--uninstall` → byte-equal to Pre. Then run new `--uninstall` again → `find $HOME -newer <stamp>` empty, file list unchanged | passes |
| T8 | Backups kept, written only on change | R9 | test: count `*.helix-bak.*` before/after T2's undo → grows by one per changed file; T7's second run → no growth | passes |
| T9 | Overrides + no `jq` | R2, R8 | test: `CLAUDE_CONFIG_DIR` elsewhere → undo edits that dir only; `PATH` without `jq` → exit 1, no file changed | passes |
| T10 | Updater stops re-running devenv | R10 | `auto-update.test.sh`: seed tags carry an executable stub `scripts/helix-setup-devenv.sh` that writes `$W/sentinel`; create `$W/state/.devenv-opted-in`; run an update that moves → `$W/sentinel` absent (fails today: `:225-227` runs the stub) | passes; `grep -n devenv scripts/helix-auto-update.sh` empty |
| T11 | SessionStart tip gone | R11 | test: run `hooks/session-start` with fake `HOME`, no marker, no count file → output has no `helix-setup-devenv` (fails today: `:37`) | passes; `.devenv-notice-count` not created |
| T12 | Docs | R12 | test: `grep -n 'helix-setup-devenv.sh *#.*opt-in\|helix-setup-devenv.sh *# install' README.md docs/CONTRIBUTING.md` → 0 lines (fails today: `README.md:241`, `CONTRIBUTING.md:21`) | grep empty; `--uninstall` still shown; wiki link anchor resolves |
| T13 | Full suite | all | — | `bash scripts/tests/run.sh` exits 0 locally and in CI |

Order: T0 → T1 → T2–T9 (script) → T10 → T11 → T12 → T13. T5 waits on owner answer Q1;
T1's no-arg behaviour waits on Q2 (if Option B, T1 becomes "no-arg run = undo").

Commits reference `Spec: docs/sdd/retire-devenv R<n>`. Branch: `fix/retire-devenv`.
