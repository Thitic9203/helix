#!/usr/bin/env bash
# ci-check-hook-exec.sh: hook command targets must be 100755 in the git index (or run via an
# interpreter). Must-fail and must-pass fixtures, then the real repo.
. "$(dirname "$0")/lib.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
CHK="$REPO_ROOT/scripts/ci-check-hook-exec.sh"

fixture() { # fixture <dir> <hooks.json command> ; creates a repo with hooks/run-hook.cmd at 100644
  local d="$1"; mkdir -p "$d/hooks"
  git init -q "$d"
  printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":%s}]}]}}\n' "$2" > "$d/hooks/hooks.json"
  printf '#!/usr/bin/env bash\necho hi\n' > "$d/hooks/run-hook.cmd"
  git -C "$d" add hooks
  git -C "$d" update-index --chmod=-x hooks/run-hook.cmd
}

fixture "$W/bad" '"\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start"'
chmod +x "$W/bad/hooks/run-hook.cmd"   # working copy executable, index 100644: the real-world trap
expect_exit 1 "must-fail: direct target 100644 in the index is refused (even if the file on disk is +x)" -- bash "$CHK" "$W/bad"

fixture "$W/good" '"\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start"'
git -C "$W/good" update-index --chmod=+x hooks/run-hook.cmd
expect_exit 0 "must-pass: direct target 100755 in the index is accepted" -- bash "$CHK" "$W/good"

fixture "$W/interp" '"bash \"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start"'
expect_exit 0 "must-pass: a 100644 target invoked via bash is accepted" -- bash "$CHK" "$W/interp"

fixture "$W/untracked" '"./hooks/not-there"'
expect_exit 1 "must-fail: an untracked target is refused" -- bash "$CHK" "$W/untracked"

expect_exit 0 "this repo: every hook command target is executable in the index" -- bash "$CHK" "$REPO_ROOT"
finish
