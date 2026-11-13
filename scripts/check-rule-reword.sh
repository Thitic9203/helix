#!/usr/bin/env bash
# Rule reword gate (docs/sdd/token-budget-guard R8 register).
# Usage: PR_TITLE=... PR_BODY=... check-rule-reword.sh <base rule-line-register.json or ""> <head rule-line-register.json>
# rule-line-register.json lets a reworded MUST / NEVER / 🔴 / STOP / GATE line pass check-rule-lines.sh.
# Adding or changing an entry needs a PR title that starts with "[rule-reword]" AND a body with a quoted
# ("> ...") owner approval. Removing entries, or no change, passes.
# Exit: 0 = allowed, 1 = new entries without approval, 2 = could not check (fail closed).
set -uo pipefail
BASE="${1:-}"; HEAD="${2:-}"
command -v python3 >/dev/null 2>&1 || { echo "rule-reword: FAIL — python3 required"; exit 2; }
if [ -z "$HEAD" ] || [ ! -f "$HEAD" ]; then
  echo "rule-reword: pass (no rule-line-register.json at head)"; exit 0
fi
[ -n "$BASE" ] && [ -f "$BASE" ] || BASE=""
out="$(python3 - "$HEAD" "$BASE" <<'PY'
import json, sys
def load(p):
    if not p: return set()
    return {json.dumps(e, sort_keys=True, ensure_ascii=False) for e in json.load(open(p, encoding="utf-8"))["entries"]}
try:
    new = load(sys.argv[1]) - load(sys.argv[2] if len(sys.argv) > 2 else "")
except Exception as ex:
    print(f"unreadable register ({ex})"); sys.exit(2)
print(len(new)); sys.exit(3 if new else 0)
PY
)"; rc=$?
case "$rc" in
  0) echo "rule-reword: pass (no new register entries)"; exit 0 ;;
  3) ;;
  *) echo "rule-reword: FAIL — $out (fail closed)"; exit 2 ;;
esac
title_ok=false; quote_ok=false
case "${PR_TITLE:-}" in "[rule-reword]"*) title_ok=true ;; esac
printf '%s\n' "${PR_BODY:-}" | tr -d '\r' | grep -qE '^[[:space:]]*>[[:space:]]*[^[:space:]>].{2,}' && quote_ok=true
if $title_ok && $quote_ok; then
  echo "rule-reword: pass — $out approved register entr(y/ies)"; exit 0
fi
echo "rule-reword: FAIL — $out new register entr(y/ies) without approval"
$title_ok || echo "  The PR title must start with [rule-reword]."
$quote_ok || echo "  The PR body must quote the owner's approval as a '> ...' line."
exit 1
