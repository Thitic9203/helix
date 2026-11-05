#!/usr/bin/env bash
# helix-setup-devenv.sh — RETIRED. It no longer adds anything. It only undoes what an earlier
# version wrote into your GLOBAL Claude Code setup (Spec: docs/sdd/retire-devenv).
#
# Undo (--uninstall), safe to run twice:
#   1. removes the Bash allowlist rules Helix added from ~/.claude/settings.json (rules you already
#      had before are kept) and the defaultMode Helix set
#   2. removes the HELIX-DEVENV block from ~/.claude/CLAUDE.md
#   3. deletes ~/.helix/.devenv-opted-in and ~/.helix/.devenv-notice-count
#   Files are backed up before a change and restored byte-for-byte when nothing else changed.
#
# Undo:            bash scripts/helix-setup-devenv.sh --uninstall
# No argument:     does nothing — except on a machine that opted in earlier, where the old
#                  updater's last call undoes it the same way.

set -uo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
STATE_DIR="${HELIX_STATE_DIR:-$HOME/.helix}"
OPTIN_MARKER="$STATE_DIR/.devenv-opted-in"
NOTICE_COUNT="$STATE_DIR/.devenv-notice-count"
. "$(cd "$(dirname "$0")" && pwd)/lib/devenv-rules.sh"
MARK_START="$DEVENV_MARK_START"
MARK_END="$DEVENV_MARK_END"

log() { echo "[helix-devenv] $*"; }

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    log "ERROR: jq is required to safely edit settings.json. Install jq, then re-run."
    log "  macOS: brew install jq"
    exit 1
  fi
}

# Copy <file> to <file>.helix-bak.<time>; never overwrites an existing backup.
backup() {
  local f="$1" ts b n=0
  [ -f "$f" ] || return 0
  ts="$(date +%Y%m%d%H%M%S)"; b="$f.helix-bak.$ts"
  while [ -e "$b" ]; do n=$((n + 1)); b="$f.helix-bak.$ts.$n"; done
  cp -p "$f" "$b" && log "backed up $f -> $b"
}

# jq -S view with the allow list as a sorted set (v1 sorted it with `unique`).
NORM='if (.permissions|type)=="object" and (.permissions.allow|type)=="array" then .permissions.allow |= unique else . end'

unmerge_settings() {
  [ -f "$SETTINGS" ] || return 0
  if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then
    log "WARN: $SETTINGS is not valid JSON; left untouched."; return 0
  fi
  local oldest keep del_mode=false bjson="null" cand_raw cand rule tmp
  oldest="$(devenv_oldest_backup "$SETTINGS")"
  keep="$(devenv_keep_rules "$SETTINGS")"
  if [ -n "$oldest" ] && jq -e 'type=="object"' "$oldest" >/dev/null 2>&1; then bjson="$(jq -c . "$oldest")"; fi
  if devenv_helix_set_mode "$SETTINGS"; then
    del_mode=true
  elif [ -z "$oldest" ] && [ "$(jq -r '.permissions.defaultMode? // empty' "$SETTINGS")" = "acceptEdits" ]; then
    log "no backup found: left permissions.defaultMode (acceptEdits) as is. If Helix set it, remove it with: jq 'del(.permissions.defaultMode)' \"$SETTINGS\""
  fi
  while IFS= read -r rule; do
    [ -n "$rule" ] && log "kept $rule (it was already in your settings before the opt-in)"
  done < <(jq -r --argjson keep "$keep" '(.permissions.allow? // [])[]? | select(. as $x | $keep | index($x))' "$SETTINGS")
  cand_raw="$(jq --argjson r "$DEVENV_SHIPPED_RULES" --argjson keep "$keep" --argjson dm "$del_mode" '
    ($r - $keep) as $rm
    | (if (.permissions|type)=="object" and (.permissions.allow|type)=="array"
       then .permissions.allow |= map(select(. as $x | $rm | index($x) | not)) else . end)
    | (if $dm then del(.permissions.defaultMode) else . end)' "$SETTINGS")" || return 0
  if [ "$(printf '%s' "$cand_raw" | jq -S .)" = "$(jq -S . "$SETTINGS")" ]; then
    log "no Helix allowlist rules or defaultMode found in $SETTINGS"; return 0
  fi
  # Drop containers Helix created (an empty allow / permissions the backup did not have).
  cand="$(printf '%s' "$cand_raw" | jq --argjson b "$bjson" '
    if $b == null then . else
      (if (.permissions|type)=="object" and (.permissions.allow == [])
          and (($b.permissions|type) != "object" or ($b.permissions|has("allow")|not))
       then del(.permissions.allow) else . end)
      | (if .permissions == {} and ($b|has("permissions")|not) then del(.permissions) else . end)
    end')"
  tmp="$(mktemp)"
  if [ -n "$oldest" ] && [ "$(printf '%s' "$cand" | jq -S "$NORM")" = "$(jq -S "$NORM" "$oldest" 2>/dev/null)" ]; then
    cp "$oldest" "$tmp"
    log "restored $SETTINGS to its pre-opt-in bytes"
  else
    printf '%s\n' "$cand" | jq . > "$tmp"
    log "removed Helix allowlist rules from $SETTINGS; the order/format of your own rules could not be restored."
  fi
  if ! cmp -s "$tmp" "$SETTINGS"; then backup "$SETTINGS"; cat "$tmp" > "$SETTINGS"; fi
  rm -f "$tmp"
}

remove_claude_md() {
  [ -f "$CLAUDE_MD" ] || return 0
  grep -qF "$MARK_START" "$CLAUDE_MD" || { log "no Helix block in $CLAUDE_MD"; return 0; }
  local tmp oldest
  tmp="$(mktemp)"; oldest="$(devenv_oldest_backup "$CLAUDE_MD")"
  python3 - "$CLAUDE_MD" "$MARK_START" "$MARK_END" "$oldest" > "$tmp" <<'PY'
import sys
path, mark_s, mark_e, oldest = sys.argv[1:5]
text = open(path, encoding="utf-8", newline="").read()
if mark_s in text and mark_e in text:
    pre = text[:text.index(mark_s)].rstrip("\n")
    post = text[text.index(mark_e) + len(mark_e):].lstrip("\n")
    out = pre + ("\n" if pre and post else "") + post
    if out and not out.endswith("\n"):
        out += "\n"
    if oldest:
        old = open(oldest, encoding="utf-8", newline="").read()
        if out.rstrip("\n") == old.rstrip("\n"):
            out = old  # nothing else changed: give back the exact pre-opt-in bytes
else:
    out = text
sys.stdout.buffer.write(out.encode("utf-8"))
PY
  if ! cmp -s "$tmp" "$CLAUDE_MD"; then backup "$CLAUDE_MD"; cat "$tmp" > "$CLAUDE_MD"; log "removed managed rules block from $CLAUDE_MD"; fi
  rm -f "$tmp"
}

undo_all() {
  require_jq
  unmerge_settings
  remove_claude_md
  rm -f "$OPTIN_MARKER" "$NOTICE_COUNT"
  log "done. (backups kept)"
}

retired() {
  log "helix-setup-devenv.sh is retired: it no longer adds any setting."
  log "To undo what an earlier version wrote: bash scripts/helix-setup-devenv.sh --uninstall"
}

case "${1:-}" in
  --uninstall)
    log "undoing Helix devenv config..."
    undo_all
    ;;
  "")
    if [ -f "$OPTIN_MARKER" ]; then
      log "this machine opted in earlier; undoing it now."
      undo_all
    fi
    retired
    ;;
  *)
    retired
    ;;
esac
