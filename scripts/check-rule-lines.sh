#!/usr/bin/env bash
# Rule-line diff (docs/sdd/token-budget-guard R8): no gate is cut to save tokens.
# Usage: check-rule-lines.sh <base> <head>   (run inside the repo)
# Every line removed from skills/, references/, commands/ or hooks/ between <base> and <head> that carries
# MUST, NEVER, 🔴, STOP or GATE must still exist, identical apart from leading/trailing whitespace,
# somewhere in the <head> tree (moved, not cut). A reworded rule line counts as removed, unless
# rule-line-register.json in <head> lists it with an owner approval and replacement rule lines that all
# exist in <head> (R8 reword register; adding entries needs a [rule-reword] PR, check-rule-reword.sh).
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
if git cat-file -e "$HEAD:rule-line-register.json" 2>/dev/null; then
  git show "$HEAD:rule-line-register.json" > "$TMP/reg" || { echo "rule-lines: FAIL — cannot read rule-line-register.json"; exit 2; }
else
  echo '{"entries": []}' > "$TMP/reg"
fi
python3 - "$TMP/diff" "$TMP/head" "$TMP/reg" <<'PY'
import json, re, sys
RULE = re.compile(r"MUST|NEVER|STOP|GATE|\U0001F534")
diff, head = (open(p, encoding="utf-8", errors="replace").read().split("\n") for p in sys.argv[1:3])
present = {l.strip() for l in head}
try:
    entries = json.load(open(sys.argv[3], encoding="utf-8"))["entries"]
    reg = {}
    for e in entries:
        r, by, ok = e["removed"].strip(), [x.strip() for x in e["replaced_by"]], str(e["approval"]).strip()
        if not (r and by and ok and all(RULE.search(x) for x in by)):
            raise ValueError(f"entry needs removed, rule-line replaced_by and approval: {r[:80]}")
        reg[r] = by
except Exception as ex:
    print(f"rule-lines: FAIL — rule-line-register.json invalid ({ex}) (fail closed)"); sys.exit(2)
cut, path = [], "?"
for l in diff:
    if l.startswith("--- a/") or l.startswith("--- /dev/null"):
        path = l[6:] if l.startswith("--- a/") else "(new file)"
        continue
    if l.startswith("+++ ") or not l.startswith("-"):
        continue
    t = l[1:].strip()
    if t and RULE.search(t) and t not in present:
        by = reg.get(t)
        if by and all(x in present for x in by):
            print(f"rule-lines: reworded (registered, owner-approved) in {path}: {t[:120]}")
            continue
        cut.append((path, t))
for p, t in cut:
    print(f"rule-lines: removed from {p}: {t[:160]}")
if cut:
    print(f"rule-lines: FAIL — {len(cut)} rule line(s) cut. Keep them, or move them (identical text) instead of deleting.")
    sys.exit(1)
print("rule-lines: pass (no MUST/NEVER/🔴/STOP/GATE line cut)")
PY
