#!/usr/bin/env bash
# CI side of the token budget guard (docs/sdd/token-budget-guard). Run from the repo root.
#   ci-token-budget.sh pr <base-ref>          R5 + R8: PR head vs token-budget.json, rule lines vs base;
#                                             appends the per-skill table to $GITHUB_STEP_SUMMARY
#   ci-token-budget.sh release <tag> <report> R7 + R8 + R10: re-measure HEAD (the commit to be tagged),
#                                             rule lines since the previous release, write <report>
#   ci-token-budget.sh ratchet <tag>          R9: lower token-budget.json to HEAD's cost (never raise)
# Every mode measures `git archive HEAD`, i.e. the exact commit, not the work tree. Non-zero = refuse.
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel)" || exit 2
cd "$ROOT" || exit 2
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
HEAD_SHA="$(git rev-parse HEAD)" || exit 2
mkdir -p "$TMP/tree"
git archive --format=tar HEAD | tar -x -C "$TMP/tree" || { echo "token-budget: FAIL — cannot read HEAD"; exit 2; }
TM="$TMP/tree/scripts/token-measure.py"
[ -f "$TM" ] || { echo "token-budget: FAIL — scripts/token-measure.py missing at HEAD (fail closed)"; exit 2; }
BUDGET="$TMP/tree/token-budget.json"

rule_lines() { # rule_lines <base>: prints the check, echoes pass|fail on fd 3
  if bash "$ROOT/scripts/check-rule-lines.sh" "$1" HEAD; then echo pass >&3; else echo fail >&3; fi
}

case "${1:-}" in
  pr)
    BASE="${2:?usage: ci-token-budget.sh pr <base-ref>}"
    MB="$(git merge-base "$BASE" HEAD)" || { echo "token-budget: FAIL — no merge base with $BASE"; exit 2; }
    rl="$(rule_lines "$MB" 3>&1 1>&2)"
    python3 "$TM" check --root "$TMP/tree" --budget "$BUDGET" --selftest-repo "$ROOT" \
      --rule-lines "$rl" ${GITHUB_STEP_SUMMARY:+--summary "$GITHUB_STEP_SUMMARY"}
    ;;
  release)
    TAG="${2:?usage: ci-token-budget.sh release <tag> <report>}"; REPORT="${3:?usage: ci-token-budget.sh release <tag> <report>}"
    PREV="$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --merged HEAD --sort=-v:refname | grep -vx "$TAG" | head -1)"
    if [ -z "$PREV" ]; then
      PREV="$(git rev-list --max-parents=0 HEAD | tail -1)"; echo "rule-lines: no earlier release; diffing from the root commit"
    fi
    rl="$(rule_lines "$PREV" 3>&1 1>&2)"
    python3 "$TM" check --root "$TMP/tree" --budget "$BUDGET" --selftest-repo "$ROOT" --rule-lines "$rl" \
      --report "$REPORT" --tag "$TAG" --commit "$HEAD_SHA" ${GITHUB_STEP_SUMMARY:+--summary "$GITHUB_STEP_SUMMARY"}
    ;;
  ratchet)
    TAG="${2:?usage: ci-token-budget.sh ratchet <tag>}"
    python3 "$TM" ratchet --root "$TMP/tree" --budget "$BUDGET" --tag "$TAG" --commit "$HEAD_SHA" --selftest-repo "$ROOT" || exit $?
    cmp -s "$BUDGET" "$ROOT/token-budget.json" || cp "$BUDGET" "$ROOT/token-budget.json"
    ;;
  *) echo "usage: ci-token-budget.sh pr <base-ref> | release <tag> <report> | ratchet <tag>" >&2; exit 2 ;;
esac
