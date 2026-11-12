#!/usr/bin/env bash
# R8 (docs/sdd/token-budget-guard): scripts/check-rule-lines.sh fails when a MUST / NEVER / 🔴 / STOP / GATE
# line is removed between base and head and no identical line exists anywhere in the head tree.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
R="$(tb_repo)"; trap 'rm -rf "$R"' EXIT
CR="$REPO_ROOT/scripts/check-rule-lines.sh"
F=skills/procedures/retest-bug-workflow/WORKFLOW.md
G=skills/procedures/tc-fe-prep-workflow/WORKFLOW.md
base="$(git -C "$R" rev-parse HEAD)"
c() { git -C "$R" add -A; git -C "$R" commit -q --no-verify -m "$1"; }
cut_line() { python3 - "$R/$1" "$2" <<'PY'
import sys; p,pat=sys.argv[1:]; L=open(p,encoding="utf-8").read().split("\n"); i=next(i for i,l in enumerate(L) if pat in l)
open(p,"w",encoding="utf-8").write("\n".join(L[:i]+L[i+1:])); print(L[i])
PY
}
line="$(cut_line "$F" "MUST refuse to start Step 2")"; c cut-must
out="$(cd "$R" && bash "$CR" "$base" HEAD 2>&1)"; rc=$?
[ "$rc" = 1 ] && grep -q "MUST refuse to start Step 2" <<<"$out" && ok "R8: deleting a MUST line fails and names it" || fail "R8: rc=$rc out: $out"
printf '%s\n' "$line" >> "$R/references/qa-evidence-gates.md"; c move-must
out="$(cd "$R" && bash "$CR" "$base" HEAD 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "R8: moving the MUST line to another file passes" || fail "R8: moved line failed rc=$rc: $out"
git -C "$R" reset -q --hard "$base"
cut_line "$G" "GATE — STOP: Step 6 starts only" >/dev/null; c cut-gate
expect_exit 1 "R8: deleting a 🔴 GATE / STOP line fails" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
git -C "$R" reset -q --hard "$base"
python3 - "$R/$F" <<'PY'
import sys; p=sys.argv[1]; s=open(p,encoding="utf-8").read(); open(p,"w",encoding="utf-8").write(s.replace("MUST refuse to start Step 2","MUST refuse to begin Step 2",1))
PY
c reword
expect_exit 1 "R8: rewording a rule line counts as removing it" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
git -C "$R" reset -q --hard "$base"
cut_line "$F" "Retest" >/dev/null; c cut-plain
expect_exit 0 "R8: deleting a line with no rule keyword passes" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
expect_exit 2 "R8: an unreadable base fails closed" -- bash -c "cd '$R' && bash '$CR' no-such-ref HEAD"
# Reword register: an owner-approved reword passes; a missing or non-rule replacement fails; bad JSON fails closed.
reg() { python3 - "$R/rule-line-register.json" "$@" <<'PY2'
import json,sys; p,rem,by,ap=sys.argv[1:5]; json.dump({"entries":[{"removed":rem,"replaced_by":[by],"approval":ap}]},open(p,"w"))
PY2
}
git -C "$R" reset -q --hard "$base"
old="$(grep -m1 'MUST refuse to start Step 2' "$R/$F" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
new="${old/MUST refuse to start Step 2/MUST refuse to begin Step 2}"
python3 - "$R/$F" <<'PY2'
import sys; p=sys.argv[1]; s=open(p,encoding="utf-8").read(); open(p,"w",encoding="utf-8").write(s.replace("MUST refuse to start Step 2","MUST refuse to begin Step 2",1))
PY2
reg "$old" "$new" "owner 12/Nov/2026: approved"; c reword-registered
expect_exit 0 "R8: a registered, owner-approved reword passes" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
reg "$old" "MUST something that is not in the tree" "owner"; c reword-missing
expect_exit 1 "R8: a register entry whose replacement is not in the tree fails" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
reg "$old" "a replacement with no rule keyword" "owner"; c reword-norule
expect_exit 2 "R8: a register entry whose replacement is not a rule line fails closed" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
reg "$old" "$new" ""; c reword-noapproval
expect_exit 2 "R8: a register entry without an approval fails closed" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
echo '{' > "$R/rule-line-register.json"; c reword-badjson
expect_exit 2 "R8: an unreadable register fails closed" -- bash -c "cd '$R' && bash '$CR' '$base' HEAD"
# Register growth gate (check-rule-reword.sh)
RW="$REPO_ROOT/scripts/check-rule-reword.sh"; W="$(mktemp -d)"
echo '{"entries": []}' > "$W/base.json"
echo '{"entries": [{"removed": "MUST a", "replaced_by": ["MUST b"], "approval": "owner"}]}' > "$W/head.json"
Q=$'Reword.\n\n> approved — owner, 12/Nov/2026'
rw() { PR_TITLE="$1" PR_BODY="$2" bash "$RW" "$3" "$4" >/dev/null 2>&1; echo $?; }
[ "$(rw 'feat: x' '' "$W/base.json" "$W/base.json")" = 0 ] && ok "R8: an unchanged register passes" || fail "R8: unchanged register failed"
[ "$(rw 'feat: x' "$Q" "$W/base.json" "$W/head.json")" = 1 ] && ok "R8: a new register entry without the [rule-reword] title fails" || fail "R8: entry without title passed"
[ "$(rw '[rule-reword] x' 'please' "$W/base.json" "$W/head.json")" = 1 ] && ok "R8: a new register entry without a quoted approval fails" || fail "R8: entry without quote passed"
[ "$(rw '[rule-reword] x' "$Q" "$W/base.json" "$W/head.json")" = 0 ] && ok "R8: a new register entry with the title and a quote passes" || fail "R8: approved entry failed"
[ "$(rw 'feat: x' '' "$W/head.json" "$W/base.json")" = 0 ] && ok "R8: removing register entries passes" || fail "R8: removing entries failed"
echo '{' > "$W/bad.json"
[ "$(rw '[rule-reword] x' "$Q" "$W/base.json" "$W/bad.json")" = 2 ] && ok "R8: an unreadable head register fails closed" || fail "R8: bad register not refused"
rm -rf "$W"
grep -qE '^/?rule-line-register\.json[[:space:]]+@Thitic9203' "$REPO_ROOT/.github/CODEOWNERS" && ok "R8: CODEOWNERS assigns the register to the owner" || fail "R8: no CODEOWNERS entry for the register"
finish
