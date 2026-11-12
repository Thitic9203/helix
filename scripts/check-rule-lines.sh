#!/usr/bin/env bash
# Rule-line diff (docs/sdd/token-budget-guard R8): no gate is cut to save tokens.
# Usage: check-rule-lines.sh <base> <head>   (run inside the repo)
# Every line removed from skills/, references/, commands/ or hooks/ between <base> and <head> that carries
# MUST, NEVER, 🔴, STOP or GATE must still exist, identical apart from leading/trailing whitespace,
# somewhere in the <head> tree (moved, not cut). A reworded rule line counts as removed.
# Exit: 0 = no rule line cut, 1 = at least one cut, 2 = could not check (fail closed).
set -uo pipefail
BASE="${1:-}"; HEAD="${2:-}"
[ -n "$BASE" ] && [ -n "$HEAD" ] || { echo "usage: check-rule-lines.sh <base> <head>" >&2; exit 2; }
for r in "$BASE" "$HEAD"; do
  git rev-parse -q --verify "$r^{commit}" >/dev/null || { echo "rule-lines: FAIL — cannot read $r (fail closed)"; exit 2; }
done
command -v python3 >/dev/null 2>&1 || { echo "rule-lines: FAIL — python3 required"; exit 2; }
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
git diff -U0 --no-color --no-ext-diff "$BASE" "$HEAD" -- skills references commands hooks > "$TMP/diff" || { echo "rule-lines: FAIL — git diff failed"; exit 2; }
git grep -h -I -e '' "$HEAD" -- . > "$TMP/head" 2>/dev/null || { echo "rule-lines: FAIL — cannot read the $HEAD tree"; exit 2; }
python3 - "$TMP/diff" "$TMP/head" <<'PY'
import re, sys
RULE = re.compile(r"MUST|NEVER|STOP|GATE|\U0001F534")
diff, head = (open(p, encoding="utf-8", errors="replace").read().split("\n") for p in sys.argv[1:])
present = {l.strip() for l in head}
cut, path = [], "?"
for l in diff:
    if l.startswith("--- a/") or l.startswith("--- /dev/null"):
        path = l[6:] if l.startswith("--- a/") else "(new file)"
        continue
    if l.startswith("+++ ") or not l.startswith("-"):
        continue
    t = l[1:].strip()
    if t and RULE.search(t) and t not in present:
        cut.append((path, t))
for p, t in cut:
    print(f"rule-lines: removed from {p}: {t[:160]}")
if cut:
    print(f"rule-lines: FAIL — {len(cut)} rule line(s) cut. Keep them, or move them (identical text) instead of deleting.")
    sys.exit(1)
print("rule-lines: pass (no MUST/NEVER/🔴/STOP/GATE line cut)")
PY
