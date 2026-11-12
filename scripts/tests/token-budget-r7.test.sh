#!/usr/bin/env bash
# R7 (docs/sdd/token-budget-guard): the publish job re-measures the exact commit it is about to tag and
# creates no tag or release when the cost is above the budget or the R8 rule-line check fails. R10's
# token-report.json is written by the same gate and attached to the release.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
R="$(tb_repo)"; W="$(mktemp -d)"; trap 'rm -rf "$R" "$W"' EXIT
Y="$REPO_ROOT/.github/workflows/version.yml"
P="$(awk '$0=="  publish:"{on=1;print;next} on&&/^  [a-z][a-z-]*:$/{exit} on' "$Y")"
ln() { grep -n -- "$1" <<<"$P" | head -1 | cut -d: -f1; }
g="$(ln 'ci-token-budget.sh release')"; push="$(ln 'git push origin HEAD:main')"; rel="$(ln 'gh release create')"
[ -n "$g" ] && [ -n "$push" ] && [ -n "$rel" ] && [ "$g" -lt "$push" ] && [ "$g" -lt "$rel" ] \
  && ok "R7: the gate runs before the bump push and before the release" || fail "R7: order gate=$g push=$push release=$rel"
! grep -qE "continue-on-error|always\(\)" <<<"$P" && ok "R7: a failed gate stops every later step" || fail "R7: continue-on-error/always() in publish"
grep -A6 'gh release create' <<<"$P" | grep -q 'token-report.json' && ok "R10: the release attaches token-report.json" || fail "R10: token-report.json not attached"
git -C "$R" tag v1.0.0
rel_gate() { (cd "$R" && bash scripts/ci-token-budget.sh release "$1" "$W/report.json") >"$W/out" 2>&1; echo $?; }
verdict() { python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["verdict"], d["release_commit"], d["tag"])' "$W/report.json" 2>/dev/null; }
rc="$(rel_gate v1.0.1)"
[ "$rc" = 0 ] && [ "$(verdict)" = "pass $(git -C "$R" rev-parse HEAD) v1.0.1" ] && ok "R7: a within-budget commit passes with a pass report for that exact commit" || fail "R7: rc=$rc verdict '$(verdict)' $(tail -2 "$W/out")"
grow_mandatory "$R"; git -C "$R" add -A; git -C "$R" commit -q --no-verify -m grow
rm -f "$W/report.json"; rc="$(rel_gate v1.0.2)"
[ "$rc" = 1 ] && [ "$(verdict | cut -d' ' -f1)" = fail ] && ok "R7: an over-budget commit fails the gate (verdict fail)" || fail "R7: rc=$rc verdict '$(verdict)'"
# dry run of the publish job's tail: the release step is reached only when the gate exits 0
dry() { if (cd "$R" && bash scripts/ci-token-budget.sh release "$1" "$W/report.json") >/dev/null 2>&1; then git -C "$R" tag "$1"; fi; }
dry v1.0.2
! git -C "$R" rev-parse -q --verify refs/tags/v1.0.2 >/dev/null && ok "R7: dry run — no tag and no release for the over-budget commit" || fail "R7: tag created"
git -C "$R" reset -q --hard v1.0.0
python3 - "$R/skills/procedures/retest-bug-workflow/WORKFLOW.md" <<'PY'
import sys; p=sys.argv[1]; L=open(p,encoding="utf-8").read().split("\n"); i=next(i for i,l in enumerate(L) if "MUST refuse to start Step 2" in l)
open(p,"w",encoding="utf-8").write("\n".join(L[:i]+L[i+1:]))
PY
git -C "$R" add -A; git -C "$R" commit -q --no-verify -m cut-rule
rc="$(rel_gate v1.0.3)"
[ "$rc" = 1 ] && [ "$(verdict | cut -d' ' -f1)" = fail ] && grep -q "rule-lines: FAIL" "$W/out" && ok "R7/R8: a release that cuts a rule line since the last release fails" || fail "R7/R8: rc=$rc verdict '$(verdict)'"
finish
