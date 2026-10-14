#!/usr/bin/env bash
# Every command target a hook manifest executes directly must be mode 100755 in the git index.
# A 100644 target fails at session start with "Permission denied" (exit 126) on every machine that
# installs from git, while the author's working copy may still be executable and hide the problem.
# Commands that start with an interpreter (bash, sh, ...) are fine: the interpreter reads the file.
#
# Usage: bash scripts/ci-check-hook-exec.sh [repo-root]   (default: this repo)
# Exit: 0 = all targets executable, 1 = at least one problem, 2 = could not check.
set -uo pipefail
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
cd "$ROOT" || exit 2
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "not a git work tree: $ROOT"; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "python3 required"; exit 2; }

# Hook manifests: hooks/*.json plus any file named by a plugin manifest "hooks" field.
manifests="$(git ls-files 'hooks/*.json')"
for pm in .claude-plugin/plugin.json .cursor-plugin/plugin.json; do
  [ -f "$pm" ] || continue
  ref="$(python3 -c 'import json,sys; h=json.load(open(sys.argv[1])).get("hooks"); print(h if isinstance(h,str) else "")' "$pm")" || exit 2
  [ -n "$ref" ] && manifests="$manifests"$'\n'"${ref#./}"
done
manifests="$(printf '%s\n' "$manifests" | sed '/^$/d' | sort -u)"
[ -n "$manifests" ] || { echo "no hook manifests found — nothing to check"; exit 0; }

# Print "<manifest>\t<target or INTERP:name>" for every command in every manifest.
targets="$(python3 - $manifests <<'PY'
import json, shlex, sys
INTERP = {"bash", "sh", "zsh", "node", "python", "python3", "env"}
def commands(o):
    if isinstance(o, dict):
        for k, v in o.items():
            if k == "command" and isinstance(v, str):
                yield v
            else:
                yield from commands(v)
    elif isinstance(o, list):
        for v in o:
            yield from commands(v)
for path in sys.argv[1:]:
    try:
        data = json.load(open(path))
    except FileNotFoundError:
        print(f"{path}\tMISSING_MANIFEST"); continue
    for cmd in commands(data):
        cmd = cmd.replace("${CLAUDE_PLUGIN_ROOT}/", "").replace("$CLAUDE_PLUGIN_ROOT/", "")
        tok = shlex.split(cmd)[0] if cmd.strip() else ""
        base = tok.rsplit("/", 1)[-1]
        if base in INTERP:
            print(f"{path}\tINTERP:{base}")
        else:
            print(f"{path}\t{tok[2:] if tok.startswith('./') else tok}")
PY
)" || exit 2

bad=0; checked=0
while IFS=$'\t' read -r manifest target; do
  [ -n "$manifest" ] || continue
  checked=$((checked + 1))
  case "$target" in
    MISSING_MANIFEST) echo "FAIL $manifest: referenced but missing"; bad=$((bad + 1)); continue ;;
    INTERP:*) echo "ok   $manifest: run via ${target#INTERP:}"; continue ;;
  esac
  mode="$(git ls-files -s -- "$target" | awk '{print $1}')"
  if [ -z "$mode" ]; then
    echo "FAIL $manifest: $target is not tracked by git"; bad=$((bad + 1))
  elif [ "$mode" != 100755 ]; then
    echo "FAIL $manifest: $target is $mode in the git index (want 100755) — fix: git update-index --chmod=+x $target"
    bad=$((bad + 1))
  else
    echo "ok   $manifest: $target 100755"
  fi
done <<<"$targets"
[ "$checked" -gt 0 ] || { echo "hook manifests contain no commands"; exit 0; }
[ "$bad" -eq 0 ]
