#!/usr/bin/env bash
# Token budget check for the git hooks (docs/sdd/token-budget-guard R3/R4).
#   token-budget-check.sh staged        measure the STAGED tree (pre-commit)
#   token-budget-check.sh ref <commit>  measure the tree of <commit> (pre-push)
#   token-budget-check.sh watched       read file names on stdin; exit 0 if any is watched, 1 if none
# The budget is the token-budget.json inside the measured tree. Exit 0 = no increase; anything else
# (increase, missing python3, missing script, unreadable tree) refuses: the check fails closed.
set -uo pipefail
WATCH='^(skills/|references/|commands/|hooks/|token-budget\.json$|scripts/token-measure\.py$)'
ROOT="$(git rev-parse --show-toplevel)" || { echo "token-budget: FAIL — not in a git repo"; exit 2; }

case "${1:-}" in
  watched) grep -qE "$WATCH"; exit $? ;;
  staged|ref) ;;
  *) echo "usage: token-budget-check.sh staged | ref <commit> | watched" >&2; exit 2 ;;
esac

command -v python3 >/dev/null 2>&1 || { echo "token-budget: FAIL — python3 is required for the token budget check"; exit 2; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
if [ "$1" = staged ]; then
  git -C "$ROOT" checkout-index -a --prefix="$TMP/tree/" || { echo "token-budget: FAIL — cannot materialize the index"; exit 2; }
  label="staged tree"
else
  [ -n "${2:-}" ] || { echo "usage: token-budget-check.sh ref <commit>" >&2; exit 2; }
  mkdir -p "$TMP/tree"
  git -C "$ROOT" archive --format=tar "$2" | tar -x -C "$TMP/tree" || { echo "token-budget: FAIL — cannot read $2"; exit 2; }
  label="$(git -C "$ROOT" rev-parse --short "$2")"
fi
# The measuring script comes from the measured tree: a commit that deletes or breaks it refuses itself.
M="$TMP/tree/scripts/token-measure.py"
[ -f "$M" ] || { echo "token-budget: FAIL — scripts/token-measure.py missing in the $label (fail closed)"; exit 2; }
echo "token-budget: measuring the $label against its token-budget.json"
python3 "$M" check --root "$TMP/tree" --budget "$TMP/tree/token-budget.json" --selftest-repo "$ROOT"
