#!/usr/bin/env bash
# docs/sdd/token-budget-guard R3/R4/R5/R7 with the tree UNDER its committed budget (the state right after a
# PR that lowers tokens, before the next release ratchets the budget down): an increase that stays under
# the committed budget passes — the budget is the only baseline — and an increase above it is refused.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
R="$(tb_repo)"; O="$(mktemp -d)"; trap 'rm -rf "$R" "$O"' EXIT
git init -q --bare -b main "$O/origin.git"; git -C "$R" remote add origin "$O/origin.git"
budget_headroom "$R" 40; git -C "$R" add -A; git -C "$R" commit -q --no-verify -m "budget 40 tokens above the tree"
git -C "$R" push -q origin main >/dev/null 2>&1; git -C "$R" tag v1.0.0; git -C "$R" checkout -q -b pr
grow_mandatory "$R"; git -C "$R" add -A                                  # +16 tokens: inside the headroom
out="$(git -C "$R" commit -qm small 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "under budget: an increase inside the headroom is committed" || fail "small increase refused: $(tail -2 <<<"$out")"
out="$(git -C "$R" push -q origin pr 2>&1)"; rc=$?
[ "$rc" = 0 ] && ok "under budget: the same head is pushed" || fail "small increase refused at push: $(tail -2 <<<"$out")"
expect_exit 0 "under budget: the PR check passes it" -- bash -c "cd '$R' && bash scripts/ci-token-budget.sh pr main"
expect_exit 0 "under budget: the release gate passes it" -- bash -c "cd '$R' && bash scripts/ci-token-budget.sh release v1.0.1 '$O/r.json'"
h="$(git -C "$R" rev-parse HEAD)"
grow_mandatory "$R"; grow_mandatory "$R"; git -C "$R" add -A             # +48 in all: above the headroom
out="$(git -C "$R" commit -qm big 2>&1)"; rc=$?
[ "$rc" != 0 ] && [ "$(git -C "$R" rev-parse HEAD)" = "$h" ] && grep -q "token-budget: FAIL" <<<"$out" \
  && ok "under budget: an increase above the committed budget is refused at commit" || fail "big increase committed (rc=$rc)"
git -C "$R" commit -q --no-verify -m big
out="$(git -C "$R" push -q origin pr 2>&1)"; rc=$?
[ "$rc" != 0 ] && ok "under budget: ...and refused at push" || fail "big increase pushed"
expect_exit 1 "under budget: ...and by the PR check" -- bash -c "cd '$R' && bash scripts/ci-token-budget.sh pr main"
expect_exit 1 "under budget: ...and by the release gate" -- bash -c "cd '$R' && bash scripts/ci-token-budget.sh release v1.0.1 '$O/r.json'"
finish
