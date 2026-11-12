# Shared helpers for scripts/tests/token-budget-*.test.sh (sourced after lib.sh; not a test itself).
# tb_repo prints a throwaway git repo holding the current working tree, committed once, with the
# helix hooks enabled and this repo's object store as an alternate (so the R2 self-test can read 18200e2).
TM="$REPO_ROOT/scripts/token-measure.py"
KA_COMMIT=18200e2d6249f22bff6b4f874e9344058bf71987
tb_objects() { echo "$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir)/objects"; }
tb_repo() {
  local d; d="$(copy_repo)"
  git -C "$d" init -q -b main
  echo "$(tb_objects)" > "$d/.git/objects/info/alternates"
  git -C "$d" config user.name t; git -C "$d" config user.email t@example.invalid
  git -C "$d" config core.hooksPath scripts/hooks
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
