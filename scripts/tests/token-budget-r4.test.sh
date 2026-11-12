#!/usr/bin/env bash
# R4 (docs/sdd/token-budget-guard): the pre-push hook re-checks the pushed head, so an increase committed
# with --no-verify cannot leave the machine.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
R="$(tb_repo)"; O="$(mktemp -d)"; trap 'rm -rf "$R" "$O"' EXIT
git init -q --bare -b main "$O/origin.git"; git -C "$R" remote add origin "$O/origin.git"
out="$(git -C "$R" push -q origin main 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "R4: a within-budget push goes through" || fail "R4: base push refused: $(tail -2 <<<"$out")"
r0="$(git -C "$O/origin.git" rev-parse main)"
grow_mandatory "$R"; git -C "$R" add -A; git -C "$R" commit -q --no-verify -m grow
out="$(git -C "$R" push -q origin main 2>&1)"; rc=$?
[ "$rc" != 0 ] && [ "$(git -C "$O/origin.git" rev-parse main)" = "$r0" ] && grep -q "token-budget: FAIL" <<<"$out" \
  && ok "R4: a --no-verify commit that adds tokens is refused at push" || fail "R4: rc=$rc out: $(tail -2 <<<"$out")"
out="$(git -C "$R" push -q origin main:refs/heads/feature 2>&1)"; rc=$?
[ "$rc" != 0 ] && ok "R4: the same head is refused on a new branch too" || fail "R4: new-branch push went through"
git -C "$R" reset -q --hard "$r0"; shrink_mandatory "$R"; git -C "$R" add -A; git -C "$R" commit -q --no-verify -m shrink
out="$(git -C "$R" push -q origin main 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "R4: a decrease is pushed" || fail "R4: decrease refused: $(tail -2 <<<"$out")"
finish
