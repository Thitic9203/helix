#!/usr/bin/env bash
# R3 (docs/sdd/token-budget-guard): the pre-commit hook measures the STAGED tree when skills/, references/,
# commands/ or hooks/ change and refuses any increase over token-budget.json; a decrease is allowed.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
R="$(tb_repo)"; trap 'rm -rf "$R"' EXIT
h0="$(git -C "$R" rev-parse HEAD)"
grow_mandatory "$R"; git -C "$R" add -A
out="$(git -C "$R" commit -qm grow 2>&1)"; rc=$?
[ "$rc" != 0 ] && [ "$(git -C "$R" rev-parse HEAD)" = "$h0" ] && grep -q "token-budget: FAIL" <<<"$out" \
  && ok "R3: a +1-token change to a mandatory read is refused at commit" || fail "R3: rc=$rc out: $(tail -2 <<<"$out")"
grep -q "retest-bug-workflow.direct" <<<"$out" && ok "R3: the refusal names the skill that grew" || fail "R3: no skill named"
# the index grows but the working tree is back to the original: the STAGED content decides
F=skills/procedures/retest-bug-workflow/WORKFLOW.md
git -C "$R" reset -q --hard "$h0"; grow_mandatory "$R"; git -C "$R" add -A; git -C "$R" show "HEAD:$F" > "$R/$F"   # index grown, working tree original
out="$(git -C "$R" commit -qm staged-grow 2>&1)"; rc=$?
[ "$rc" != 0 ] && ok "R3: the staged blob is measured, not the working tree" || fail "R3: staged increase committed (rc=$rc)"
git -C "$R" reset -q --hard "$h0"
shrink_mandatory "$R"; git -C "$R" add -A
out="$(git -C "$R" commit -qm shrink 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "R3: a decrease is committed" || fail "R3: decrease refused: $(tail -2 <<<"$out")"
mkdir -p "$R/docs"; echo note > "$R/docs/token-note.md"; git -C "$R" add -A
out="$(git -C "$R" commit -qm docs 2>&1)"; rc=$?
[ "$rc" = 0 ] && ! grep -q "token-measure" <<<"$out" && ok "R3: a commit outside the watched paths skips the measurement" || fail "R3: rc=$rc out: $out"
git -C "$R" reset -q --hard "$h0"
rm "$R/scripts/token-measure.py"; git -C "$R" add -A
out="$(git -C "$R" commit -qm broken 2>&1)"; rc=$?
[ "$rc" != 0 ] && ok "R3: a commit that removes the measurement is refused (fail closed)" || fail "R3: commit passed without the measurement"
finish
