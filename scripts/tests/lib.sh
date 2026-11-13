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
# make_report <assets-dir> <tag> <commit> <verdict>: a token-report.json release asset (token-budget-guard R10)
make_report() {
  mkdir -p "$1/$2"
  printf '{"schema": 1, "tag": "%s", "release_tag": "%s", "release_commit": "%s", "verdict": "%s"}\n' "$2" "$2" "$3" "$4" > "$1/$2/token-report.json"
}
# pass_reports <bare-origin> <assets-dir>: a pass report for every release tag on the origin
pass_reports() {
  local t c
  git -C "$1" for-each-ref --format='%(refname:short) %(objectname)' 'refs/tags/v*' | while read -r t c; do
    c="$(git -C "$1" rev-parse "$t^{commit}")"; make_report "$2" "$t" "$c" pass
  done
}
