#!/usr/bin/env bash
# R2 (docs/sdd/token-budget-guard): scripts/token-measure.py measures session cost the graph_v2 way and its
# known-answer self-test reproduces the token-diet numbers of helix 18200e2. Measurement errors fail closed.
. "$(dirname "$0")/lib.sh"; . "$(dirname "$0")/token-budget-helpers.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
out="$(python3 "$TM" self-test --repo "$REPO_ROOT" 2>&1)"; rc=$?
[ "$rc" = 0 ] && grep -q "self-test pass" <<<"$out" && ok "R2: self-test passes on 18200e2" || fail "R2: self-test rc=$rc: $out"
mkdir -p "$W/ka"; git -C "$REPO_ROOT" archive "$KA_COMMIT" | tar -x -C "$W/ka"
m="$(python3 "$TM" measure "$W/ka" 2>/dev/null)"
want='catch-ai-workflow 9337 14491|create-bug-workflow 6876 14571|helix 8195 None|retest-bug-workflow 18495 25907|tc-api-prep-workflow 6287 13982|tc-fe-prep-workflow 17173 24585|tc-review-workflow 8069 15221|testing-ticket-workflow 17179 24874|always_on 5090 1272'
got="$(python3 -c '
import json,sys; d=json.load(sys.stdin); K=["catch-ai-workflow","create-bug-workflow","helix","retest-bug-workflow","tc-api-prep-workflow","tc-fe-prep-workflow","tc-review-workflow","testing-ticket-workflow"]
r=["%s %s %s"%(k,d["skills"][k]["direct"],d["skills"][k]["routed"]) for k in K]; a=d["always_on"]
print("|".join(r+["always_on %s %s"%(a["description_bytes"],a["tokens"])]))' <<<"$m" 2>&1)"
[ "$got" = "$want" ] && ok "R2: per-skill direct/routed and always-on numbers equal graph_v2 + compare_tokens on 18200e2" || fail "R2: got $got"
dig="$(python3 "$TM" graph-digest "$W/ka" 2>&1)"
[ "$dig" = acce664f2828a04c0f4977d57f31145e0f313055edda6687adea0f3b7fea1217 ] && ok "R2: graph output equals graph_v2 output on 18200e2 (canonical digest)" || fail "R2: digest $dig"
git init -q "$W/empty"
expect_exit 2 "R2: self-test fails closed when 18200e2 cannot be read" -- python3 "$TM" self-test --repo "$W/empty"
expect_exit 2 "R2: measuring a tree without skills/ fails closed" -- python3 "$TM" measure "$W/nothing-here"
finish
