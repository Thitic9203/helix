#!/usr/bin/env bash
# R9 (docs/sdd/token-budget-guard): token-budget.json may only go up in a PR titled [token-budget-raise]
# whose body quotes the owner's approval; CODEOWNERS assigns the file to the owner; after a release the
# budget is ratcheted down automatically and never up.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
CB="$REPO_ROOT/scripts/check-budget-raise.sh"
B="$REPO_ROOT/token-budget.json"
edit() { python3 - "$B" "$W/$1" "$2" <<'PY'
import json,sys; d=json.load(open(sys.argv[1])); exec(sys.argv[3]); json.dump(d,open(sys.argv[2],"w"))
PY
}
edit up.json 'd["skills"]["helix"]["direct"]+=1'
edit down.json 'd["skills"]["helix"]["direct"]-=50'
edit new.json 'd["skills"]["brand-new-workflow"]={"direct":10,"routed":20}'
edit aon.json 'd["always_on"]["description_bytes"]+=4'
QUOTE=$'Raise for the new skill.\n\n> อนุมัติให้เพิ่ม budget ได้ — owner, 12/Nov/2026'
run() { PR_TITLE="$1" PR_BODY="$2" bash "$CB" "$3" "$4" >/dev/null 2>&1; echo $?; }
[ "$(run 'feat: x' '' "$B" "$B")" = 0 ] && ok "R9: an unchanged budget passes" || fail "R9: unchanged budget failed"
[ "$(run 'feat: x' '' "$B" "$W/down.json")" = 0 ] && ok "R9: a lowered budget passes without the raise title" || fail "R9: lowered budget failed"
[ "$(run 'feat: x' "$QUOTE" "$B" "$W/up.json")" = 1 ] && ok "R9: a raise without the [token-budget-raise] title fails" || fail "R9: raise without title passed"
[ "$(run '[token-budget-raise] helix' 'please approve' "$B" "$W/up.json")" = 1 ] && ok "R9: a raise whose body quotes no approval fails" || fail "R9: raise without quote passed"
[ "$(run '[token-budget-raise] helix' "$QUOTE" "$B" "$W/up.json")" = 0 ] && ok "R9: a raise with the title and a quoted approval passes" || fail "R9: proper raise failed"
[ "$(run 'feat: new skill' "$QUOTE" "$B" "$W/new.json")" = 1 ] && ok "R9: a new skill entry is a raise (needs the title)" || fail "R9: new skill passed silently"
[ "$(run 'feat: x' '' "$B" "$W/aon.json")" = 1 ] && ok "R9: raising the always-on bytes needs the title" || fail "R9: always-on raise passed"
[ "$(run 'feat: x' '' '' "$B")" = 0 ] && ok "R9: the PR that introduces the budget passes" || fail "R9: introduction failed"
[ "$(run 'feat: x' '' "$B" "$W/none.json")" = 2 ] && ok "R9: deleting the budget fails closed" || fail "R9: missing head budget not refused"
grep -qE '^/?token-budget\.json[[:space:]]+@Thitic9203' "$REPO_ROOT/.github/CODEOWNERS" 2>/dev/null && ok "R9: CODEOWNERS assigns token-budget.json to the owner" || fail "R9: no CODEOWNERS entry for token-budget.json"
# ratchet: lower after a release, never raise
R="$(tb_repo)"; trap 'rm -rf "$W" "$R"' EXIT
cp "$R/token-budget.json" "$W/orig.json"
python3 "$TM" ratchet --root "$R" --budget "$R/token-budget.json" --tag v9.9.9 --commit "$(printf 'a%.0s' {1..40})" --selftest-repo "$R" >/dev/null 2>&1
cmp -s "$R/token-budget.json" "$W/orig.json" && ok "R9: ratchet leaves an unchanged cost alone" || fail "R9: ratchet rewrote an unchanged budget"
grow_mandatory "$R"; cp "$R/token-budget.json" "$W/before.json"
python3 "$TM" ratchet --root "$R" --budget "$R/token-budget.json" --tag v9.9.9 --commit "$(printf 'a%.0s' {1..40})" --selftest-repo "$R" >/dev/null 2>&1; rc=$?
[ "$rc" = 1 ] && cmp -s "$R/token-budget.json" "$W/before.json" && ok "R9: ratchet refuses to raise the budget" || fail "R9: ratchet rc=$rc or file changed"
git -C "$R" checkout -q -- skills; shrink_mandatory "$R"
python3 "$TM" ratchet --root "$R" --budget "$R/token-budget.json" --tag v9.9.9 --commit "$(printf 'a%.0s' {1..40})" --selftest-repo "$R" >/dev/null 2>&1
python3 - "$W/orig.json" "$R/token-budget.json" <<'PY' && ok "R9: ratchet lowers the budget and records the new release" || fail "R9: ratchet did not lower"
import json,sys; a,b=(json.load(open(p)) for p in sys.argv[1:])
k="retest-bug-workflow"; sys.exit(0 if b["skills"][k]["direct"]<a["skills"][k]["direct"] and b["tag"]=="v9.9.9" else 1)
PY
finish
