# Shared by scripts/helix-setup-devenv.sh (the undo) and scripts/helix-doctor.sh (leftover warning).
# Spec: docs/sdd/retire-devenv R2, R5, R14. Sourced, not executed. Needs jq for the functions below.

# Every allowlist rule any Helix version shipped (commit 8894507, blob c925107 — the only version
# that ever wrote them). The undo needs this list; nothing adds these rules any more.
DEVENV_SHIPPED_RULES='[
  "Bash(git status)","Bash(git status *)","Bash(git diff *)","Bash(git log *)",
  "Bash(git show *)","Bash(git add *)","Bash(git commit *)","Bash(git branch)",
  "Bash(git branch *)","Bash(git checkout -b *)","Bash(git stash *)",
  "Bash(git fetch *)","Bash(git pull --rebase *)",
  "Bash(rtk *)","Bash(ls *)","Bash(cat *)","Bash(find *)","Bash(grep *)","Bash(rg *)",
  "Bash(which *)","Bash(node *)","Bash(npx *)","Bash(npm run *)","Bash(python3 *)",
  "Bash(wc *)","Bash(head *)","Bash(tail *)","Bash(sort *)","Bash(diff *)",
  "Bash(mkdir *)","Bash(basename *)","Bash(dirname *)","Bash(realpath *)",
  "Bash(stat *)","Bash(chmod +x *)",
  "Bash(gh pr view *)","Bash(gh pr list *)","Bash(gh pr diff *)",
  "Bash(gh issue view *)","Bash(gh issue list *)","Bash(gh run view *)",
  "Bash(gh run list *)","Bash(gh repo view *)","Bash(gh api *)",
  "Bash(bash scripts/*)"
]'
DEVENV_MARK_START="<!-- HELIX-DEVENV:START (managed by scripts/helix-setup-devenv.sh — do not edit inside) -->"
DEVENV_MARK_END="<!-- HELIX-DEVENV:END -->"

# devenv_oldest_backup <file> — the earliest <file>.helix-bak.* (names sort by time), or nothing.
devenv_oldest_backup() {
  local f
  f="$(ls -1 "$1".helix-bak.* 2>/dev/null | sort | head -1)"
  [ -n "$f" ] && printf '%s\n' "$f"
  return 0
}

# devenv_keep_rules <settings> — JSON array: shipped rules the oldest backup already had (the user's own).
devenv_keep_rules() {
  local b; b="$(devenv_oldest_backup "$1")"
  [ -n "$b" ] || { echo '[]'; return 0; }
  jq -c --argjson r "$DEVENV_SHIPPED_RULES" \
    '[(.permissions.allow? // [])[]? | select(. as $x | $r | index($x))] | unique' "$b" 2>/dev/null || echo '[]'
}

# devenv_leftover_rules <settings> — JSON array: shipped rules in <settings> that Helix added.
devenv_leftover_rules() {
  local keep; keep="$(devenv_keep_rules "$1")"
  jq -c --argjson r "$DEVENV_SHIPPED_RULES" --argjson keep "$keep" \
    '[(.permissions.allow? // [])[]? | select(. as $x | ($r | index($x)) and (($keep | index($x)) | not))]' "$1" 2>/dev/null || echo '[]'
}

# devenv_helix_set_mode <settings> — exit 0 when Helix set permissions.defaultMode (owner decision Q1,
# option A): the value is acceptEdits and the oldest backup exists and has no defaultMode.
devenv_helix_set_mode() {
  local b; b="$(devenv_oldest_backup "$1")"
  [ -n "$b" ] || return 1
  [ "$(jq -r '.permissions.defaultMode? // empty' "$1" 2>/dev/null)" = "acceptEdits" ] || return 1
  jq -e '(.permissions.defaultMode? // null) == null' "$b" >/dev/null 2>&1
}
