#!/usr/bin/env bash
# R6 (docs/sdd/token-budget-guard): main requires the token-budget, token-budget-raise and pr-check checks.
# The setting lives on GitHub (owner applies it); this test pins the documented command to the real job
# names, so a renamed job cannot leave the required check pointing at nothing.
. "$(dirname "$0")/lib.sh"
C="$REPO_ROOT/docs/CONTRIBUTING.md"; Y="$REPO_ROOT/.github/workflows/version.yml"
cmd="$(awk '/^gh api .*rulesets/{on=1} on{print} on&&/^EOF$/{exit}' "$C")"
[ -n "$cmd" ] && ok "R6: CONTRIBUTING.md carries the ruleset command" || fail "R6: no 'gh api ... rulesets' command in CONTRIBUTING.md"
json="$(sed -n '/<<.EOF./,/^EOF$/p' <<<"$cmd" | sed '1d;$d')"
ctx="$(python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); r=[x for x in d["rules"] if x["type"]=="required_status_checks"][0]; print(" ".join(sorted(c["context"] for c in r["parameters"]["required_status_checks"])))' <<<"$json" 2>/dev/null)"
[ "$ctx" = "pr-check token-budget token-budget-raise" ] && ok "R6: the ruleset requires pr-check, token-budget and token-budget-raise" || fail "R6: required contexts '$ctx'"
for j in pr-check token-budget token-budget-raise; do
  grep -qx "  $j:" "$Y" && ok "R6: required check '$j' is a job in version.yml" || fail "R6: no job '$j' in version.yml"
done
python3 -c 'import json,sys; d=json.loads(sys.stdin.read()); sys.exit(0 if d["conditions"]["ref_name"]["include"]==["~DEFAULT_BRANCH"] and d["enforcement"]=="active" else 1)' <<<"$json" 2>/dev/null \
  && ok "R6: the ruleset is active on the default branch" || fail "R6: ruleset target/enforcement wrong"
grep -q "rules/branches/main" "$C" && ok "R6: CONTRIBUTING.md says how to verify the setting" || fail "R6: no verification command"
finish
