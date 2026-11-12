#!/usr/bin/env bash
# Budget raise gate (docs/sdd/token-budget-guard R9).
# Usage: PR_TITLE=... PR_BODY=... check-budget-raise.sh <base token-budget.json or ""> <head token-budget.json>
# A PR may lower token-budget.json or keep it. Raising any number, or adding a skill entry, needs a PR
# title that starts with "[token-budget-raise]" AND a body with a quoted ("> ...") owner approval.
# Exit: 0 = allowed, 1 = raise without approval, 2 = could not check (fail closed).
set -uo pipefail
BASE="${1:-}"; HEAD="${2:-}"
TM="$(cd "$(dirname "$0")" && pwd)/token-measure.py"
[ -n "$HEAD" ] && [ -f "$HEAD" ] || { echo "budget-raise: FAIL — head token-budget.json missing (fail closed)"; exit 2; }
if [ -z "$BASE" ] || [ ! -f "$BASE" ]; then
  python3 "$TM" compare-budgets "$HEAD" "$HEAD" >/dev/null || { echo "budget-raise: FAIL — head budget unreadable"; exit 2; }
  echo "budget-raise: pass (this PR introduces token-budget.json)"; exit 0
fi
out="$(python3 "$TM" compare-budgets "$BASE" "$HEAD" 2>&1)"; rc=$?
case "$rc" in
  0) echo "budget-raise: pass ($out)"; exit 0 ;;
  3) ;;
  *) echo "budget-raise: FAIL — $out"; exit 2 ;;
esac
title_ok=false; quote_ok=false
case "${PR_TITLE:-}" in "[token-budget-raise]"*) title_ok=true ;; esac
printf '%s\n' "${PR_BODY:-}" | tr -d '\r' | grep -qE '^[[:space:]]*>[[:space:]]*[^[:space:]>].{2,}' && quote_ok=true
if $title_ok && $quote_ok; then
  echo "budget-raise: pass — approved raise: $out"; exit 0
fi
echo "budget-raise: FAIL — $out"
$title_ok || echo "  The PR title must start with [token-budget-raise]."
$quote_ok || echo "  The PR body must quote the owner's approval as a '> ...' line."
exit 1
