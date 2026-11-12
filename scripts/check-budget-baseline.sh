#!/usr/bin/env bash
# R1 baseline provenance (docs/sdd/token-budget-guard R1, R9).
# Usage: check-budget-baseline.sh [repo]   (default: this repo)
# 1. token-budget.json names a release tag vX.Y.Z and a full commit; the tag is that commit or its
#    token-budget.json-only ratchet child.
# 2. The release copy (the first commit whose budget names this tag + commit) equals a fresh
#    token-measure.py measurement of that commit.
# 3. Every later non-merge commit that changes the file only lowers or keeps the numbers, unless its
#    message contains [token-budget-raise] (the R9 path). The work tree may not raise over HEAD.
# Exit: 0 = pass, 1 = fail, 2 = could not check (fail closed).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TM="$HERE/token-measure.py"
REPO="$(cd "${1:-$HERE/..}" && git rev-parse --show-toplevel)" || { echo "budget-baseline: FAIL — not a git repo"; exit 2; }
B="$REPO/token-budget.json"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
g() { git -C "$REPO" "$@"; }
[ -f "$B" ] || { echo "budget-baseline: FAIL — token-budget.json missing (fail closed)"; exit 2; }
field() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2" 2>/dev/null; }
tag="$(field "$B" tag)"; commit="$(field "$B" commit)"
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ "$commit" =~ ^[0-9a-f]{40}$ ]] \
  || { echo "budget-baseline: FAIL — budget tag '$tag' / commit '$commit' is not a release tag + full SHA"; exit 1; }
g cat-file -e "$commit^{commit}" 2>/dev/null || { echo "budget-baseline: FAIL — commit $commit not in the repo (fail closed)"; exit 2; }
if g rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  # the publish ratchet measures $commit, then tags a child commit that changes only token-budget.json
  tc="$(g rev-list -n1 "$tag")"
  if [ "$tc" != "$commit" ] && ! { [ "$(g rev-parse "$tc^" 2>/dev/null)" = "$commit" ] && [ "$(g diff --name-only "$commit" "$tc")" = "token-budget.json" ]; }; then
    echo "budget-baseline: FAIL — $tag is $tc, budget says $commit, and $tc is not a token-budget.json-only child of it"; exit 1
  fi
fi

# 2. the release copy: oldest commit on HEAD whose token-budget.json names this tag + commit
base=""
for c in $(g log --reverse --format=%H HEAD -- token-budget.json); do
  g show "$c:token-budget.json" > "$W/c.json" 2>/dev/null || continue
  if [ "$(field "$W/c.json" tag)" = "$tag" ] && [ "$(field "$W/c.json" commit)" = "$commit" ]; then base="$c"; break; fi
done
[ -n "$base" ] || { echo "budget-baseline: FAIL — no commit wrote a budget for $tag $commit (hand-written baseline)"; exit 1; }
g show "$base:token-budget.json" > "$W/release.json"
mkdir -p "$W/rel"; g archive "$commit" | tar -x -C "$W/rel" || { echo "budget-baseline: FAIL — cannot read $commit"; exit 2; }
python3 "$TM" budget --root "$W/rel" --tag "$tag" --commit "$commit" --out "$W/regen.json" --selftest-repo "$REPO" >/dev/null 2>&1 \
  || { echo "budget-baseline: FAIL — cannot measure $commit (fail closed)"; exit 2; }
python3 - "$W/release.json" "$W/regen.json" <<'PY' || { echo "budget-baseline: FAIL — the $tag budget written in ${base:0:7} differs from a fresh measurement of $commit"; exit 1; }
import json,sys; a,b=(json.load(open(p)) for p in sys.argv[1:]); sys.exit(0 if (a["skills"],a["always_on"])==(b["skills"],b["always_on"]) else 1)
PY

# 3. later changes: a raise only in a [token-budget-raise] commit; never an uncommitted raise
raises=0
for c in $(g rev-list --reverse --no-merges "$base..HEAD" -- token-budget.json); do
  g show "$c^:token-budget.json" > "$W/p.json" 2>/dev/null && g show "$c:token-budget.json" > "$W/h.json" 2>/dev/null \
    || { echo "budget-baseline: FAIL — ${c:0:7} deletes or adds token-budget.json"; exit 1; }
  out="$(python3 "$TM" compare-budgets "$W/p.json" "$W/h.json" 2>&1)"; rc=$?
  case "$rc" in
    0) ;;
    3) if g log -1 --format=%B "$c" | grep -qF '[token-budget-raise]'; then raises=$((raises + 1))
       else echo "budget-baseline: FAIL — ${c:0:7} raises the budget without [token-budget-raise] (R9): $out"; exit 1; fi ;;
    *) echo "budget-baseline: FAIL — ${c:0:7}: $out"; exit 2 ;;
  esac
done
if g show "HEAD:token-budget.json" > "$W/head.json" 2>/dev/null; then
  out="$(python3 "$TM" compare-budgets "$W/head.json" "$B" 2>&1)"; rc=$?
  case "$rc" in
    0) ;;
    3) echo "budget-baseline: FAIL — uncommitted raise in the work tree: $out"; exit 1 ;;
    *) echo "budget-baseline: FAIL — work tree budget: $out"; exit 2 ;;
  esac
fi
echo "budget-baseline: pass ($tag release copy ${base:0:7} equals its measurement; $raises approved raise commit(s) since)"
