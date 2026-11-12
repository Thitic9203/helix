# Shared helpers for scripts/tests/token-budget-*.test.sh (sourced after lib.sh; not a test itself).
# tb_repo prints a throwaway git repo holding the current working tree, committed once, with its
# token-budget.json re-baselined to the copy's measured cost, the helix hooks enabled and this repo's object store as an alternate (so the R2 self-test can read 18200e2).
TM="$REPO_ROOT/scripts/token-measure.py"
KA_COMMIT=18200e2d6249f22bff6b4f874e9344058bf71987
tb_objects() { echo "$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)/objects"; }
tb_repo() {
  local d; d="$(copy_repo)"
  git -C "$d" init -q -b main
  echo "$(tb_objects)" > "$d/.git/objects/info/alternates"
  git -C "$d" config user.name t; git -C "$d" config user.email t@example.invalid
  git -C "$d" config core.hooksPath scripts/hooks
  # Re-baseline: the copy's budget is its own measured cost, so a "+1 token" probe is an increase whether
  # the real tree sits at the committed budget or under it (a PR that lowers tokens leaves headroom).
  python3 "$d/scripts/token-measure.py" budget --root "$d" --tag v0.0.0 --commit "$(printf 'b%.0s' {1..40})" \
    --out "$d/token-budget.json" --selftest-repo "$d" >/dev/null || { echo "tb_repo: re-baseline failed" >&2; return 1; }
  git -C "$d" add -A; git -C "$d" commit -q --no-verify -m base   # seed commit only; hooks are tested below
  echo "$d"
}
# grow_mandatory <repo>: append one line (+>=1 token) to a mandatory-read file of retest-bug-workflow
grow_mandatory() { printf '%s\n' "One more line of mandatory reading added by the token-budget test." >> "$1/skills/procedures/retest-bug-workflow/WORKFLOW.md"; }
shrink_mandatory() { python3 - "$1/skills/procedures/retest-bug-workflow/WORKFLOW.md" <<'PY'
import re,sys; p=sys.argv[1]; L=open(p,encoding="utf-8").read().split("\n"); cut=0
for i in range(len(L)-1,-1,-1):  # drop non-rule lines from the end until >= 400 bytes are gone
    if cut >= 400: break
    if L[i].strip() and not re.search("MUST|NEVER|STOP|GATE|\U0001F534", L[i]): cut += len(L[i].encode()) + 1; L[i] = None
open(p,"w",encoding="utf-8").write("\n".join(l for l in L if l is not None))
PY
}
# budget_headroom <repo> <n>: raise every retest-bug-workflow number in the copy's budget by <n> tokens
budget_headroom() { python3 - "$1/token-budget.json" "$2" <<'PY'
import json,sys; p,n=sys.argv[1],int(sys.argv[2]); d=json.load(open(p))
for k in ("direct","routed"): d["skills"]["retest-bug-workflow"][k]+=n
json.dump(d,open(p,"w"),indent=1)
PY
}
