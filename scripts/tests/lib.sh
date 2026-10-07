# Shared helpers for scripts/tests/*.test.sh. Each test runs against a throwaway copy of the
# repo (git archive of the working tree's HEAD plus local edits) and a throwaway HOME.
set -uo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAILS=0
RUNS=0
ok()   { RUNS=$((RUNS + 1)); echo "  ok   $*"; }
fail() { RUNS=$((RUNS + 1)); FAILS=$((FAILS + 1)); echo "  FAIL $*"; }
expect_exit() { # expect_exit <want> <label> -- cmd...
  local want="$1" label="$2"; shift 3
  "$@" >/dev/null 2>&1; local got=$?
  if [ "$got" -eq "$want" ]; then ok "$label"; else fail "$label (exit $got, want $want)"; fi
}
copy_repo() { # prints a temp dir holding the current working tree (tracked files, as edited)
  local d; d="$(mktemp -d)"
  (cd "$REPO_ROOT" && git ls-files -z | xargs -0 -I{} sh -c 'mkdir -p "$1/$(dirname "$2")" && cp -P "$2" "$1/$2"' _ "$d" {}) 
  echo "$d"
}
finish() {
  echo "  -- $RUNS checks, $FAILS failed"
  [ "$RUNS" -gt 0 ] || { echo "  no checks ran — refusing"; exit 2; }
  [ "$FAILS" -eq 0 ]
}
