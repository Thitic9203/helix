#!/usr/bin/env bash
# R5 (docs/sdd/token-budget-guard): CI runs a token-budget job on every PR. It measures the PR head against
# token-budget.json, runs the R8 rule-line diff against the base, fails on any increase and writes the
# per-skill before -> after table to the job summary.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
R="$(tb_repo)"; W="$(mktemp -d)"; trap 'rm -rf "$R" "$W"' EXIT
Y="$REPO_ROOT/.github/workflows/version.yml"
job() { awk -v j="  $1:" '$0==j{on=1;print;next} on&&/^  [a-z][a-z-]*:$/{exit} on' "$Y"; }
J="$(job token-budget)"
[ -n "$J" ] && ok "R5: version.yml has a token-budget job" || fail "R5: no token-budget job"
grep -q "github.event_name == 'pull_request'" <<<"$J" && grep -q "ci-token-budget.sh pr" <<<"$J" && ok "R5: the job runs the PR check on pull requests" || fail "R5: job does not run ci-token-budget.sh pr"
grep -q "fetch-depth: 0" <<<"$J" && ok "R5: the job fetches full history (self-test and base diff)" || fail "R5: shallow checkout"
! grep -qE "continue-on-error|always\(\)" <<<"$J" && ok "R5: no step can turn a failure into a pass" || fail "R5: continue-on-error/always() in the job"
git -C "$R" checkout -q -b feature
run_pr() { (cd "$R" && GITHUB_STEP_SUMMARY="$W/summary.md" bash scripts/ci-token-budget.sh pr main) >"$W/out" 2>&1; echo $?; }
grow_mandatory "$R"; git -C "$R" add -A; git -C "$R" commit -q --no-verify -m grow
: > "$W/summary.md"; rc="$(run_pr)"
[ "$rc" = 1 ] && ok "R5: a PR adding 1 token fails the job" || fail "R5: rc=$rc $(tail -2 "$W/out")"
grep -qE '^\| retest-bug-workflow.direct \| [0-9]+ \| [0-9]+ \| \+[0-9]+ UP \|' "$W/summary.md" && ok "R5: the job summary shows the before -> after row" || fail "R5: summary: $(head -8 "$W/summary.md")"
git -C "$R" reset -q --hard main; shrink_mandatory "$R"; git -C "$R" add -A; git -C "$R" commit -q --no-verify -m shrink
: > "$W/summary.md"; rc="$(run_pr)"
[ "$rc" = 0 ] && grep -q "down" "$W/summary.md" && ok "R5: a PR that lowers the cost passes" || fail "R5: decrease rc=$rc $(tail -2 "$W/out")"
git -C "$R" reset -q --hard main
python3 - "$R/skills/procedures/retest-bug-workflow/WORKFLOW.md" <<'PY'
import sys; p=sys.argv[1]; L=open(p,encoding="utf-8").read().split("\n"); i=next(i for i,l in enumerate(L) if "MUST refuse to start Step 2" in l)
open(p,"w",encoding="utf-8").write("\n".join(L[:i]+L[i+1:]))
PY
git -C "$R" add -A; git -C "$R" commit -q --no-verify -m cut-rule
rc="$(run_pr)"
[ "$rc" = 1 ] && grep -q "rule-lines: FAIL" "$W/out" && ok "R5/R8: a PR that cuts a MUST line fails even when tokens drop" || fail "R5/R8: rc=$rc $(tail -2 "$W/out")"
finish
