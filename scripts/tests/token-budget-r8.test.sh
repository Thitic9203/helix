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
finish
