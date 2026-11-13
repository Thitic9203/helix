#!/usr/bin/env bash
# Helix updater. Two modes, picked by the argument:
#   --check   read-only. Run by the SessionStart hook: one `git ls-remote --tags` on the release tags,
#             prints ONE line when a newer release exists, changes nothing else (no fetch, no merge,
#             no link-skills, no plugin sync). HELIX_AUTO_UPDATE=0 turns this check off.
#   (no args) the update command, run by the user: fetch origin, fast-forward ~/.helix/tc-fe-prep to the
#             newest release tag (never an unreleased main), refresh the plugin-cache link, run
#             link-skills.sh and claude-plugin-sync.sh. Failures are recorded in last-update-error.
#             Release gate (docs/sdd/token-budget-guard R10): the newest release is installed only when its
#             token-report.json asset names that tag and commit and has verdict "pass". A missing, failing
#             or unreadable report keeps the current version and prints one line saying why (fail closed).
# HELIX_FORCE_UPDATE and HELIX_AUTO_UPDATE_INTERVAL_SEC are accepted and ignored.
# HELIX_RELEASE_ASSETS overrides where release assets are read (tests point it at a local directory).
#
# Usage:
#   bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh              # update (you run it)
#   HELIX_AUTO_UPDATE_VERBOSE=1 bash scripts/helix-auto-update.sh      # same, print progress
#   bash scripts/helix-auto-update.sh --check                          # what the hook runs

set -euo pipefail

REPO="${HELIX_REPO_DIR:-$HOME/.helix/tc-fe-prep}"
STATE_DIR="${HELIX_STATE_DIR:-$HOME/.helix}"
STAMP_FILE="$STATE_DIR/.last-auto-update-check"
LOG_FILE="$STATE_DIR/auto-update.log"
# Last failure of a step that should have worked; hooks/session-start surfaces it once per session.
ERR_FILE="$STATE_DIR/last-update-error"
ERRORS_THIS_RUN=0
# Where release tags are read when there is no clone (tests point this at a local bare repo).
REMOTE_URL="${HELIX_REMOTE_URL:-https://github.com/Thitic9203/helix.git}"
# Release assets: <base>/<tag>/token-report.json (GitHub release download URL, or a local directory).
REPORT_BASE="${HELIX_RELEASE_ASSETS:-https://github.com/Thitic9203/helix/releases/download}"
MARKETPLACE_NAME="helix-dev"
PLUGIN_NAME="helix"
CACHE_BASE="$HOME/.claude/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME"

log() {
  if [ -n "${HELIX_AUTO_UPDATE_VERBOSE:-}" ]; then
    echo "[helix-auto-update] $*" | tee -a "$LOG_FILE"
  else
    echo "[helix-auto-update] $*" >>"$LOG_FILE" 2>/dev/null || true
  fi
}

note_error() {
  ERRORS_THIS_RUN=$((ERRORS_THIS_RUN + 1))
  log "ERROR: $*"
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >>"$ERR_FILE" 2>/dev/null || true
}

auto_update_disabled() {
  case "${HELIX_AUTO_UPDATE:-1}" in
    0 | false | FALSE | no | NO | off | OFF) return 0 ;;
    *) return 1 ;;
  esac
}

version_gt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$1" ]
}

# Highest vX.Y.Z on the remote, from one read-only ls-remote. Non-zero when the remote cannot be read.
# GIT_HTTP_LOW_SPEED_* make a stalled connection give up after 5 s instead of hanging session start.
newest_remote_release() {
  local remote="$1" tags dir="."
  [ "$remote" = origin ] && dir="$REPO"
  tags=$(GIT_TERMINAL_PROMPT=0 GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=5 \
    git -C "$dir" ls-remote --tags --refs "$remote" 'v*' 2>>"$LOG_FILE") || return 1
  printf '%s\n' "$tags" \
    | sed -n 's#.*refs/tags/v\([0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\)$#\1#p' \
    | sort -t. -k1,1n -k2,2n -k3,3n | tail -1
}

# release_report_check <tag> [commit]: 0 when the release's token-report.json is a pass for <tag> (and
# <commit>, when given). Otherwise prints the reason and returns 1. Update path only, never --check.
json_str() { # json_str <flat-json> <key>: the value of the one "<key>": "..." pair, empty if absent or repeated
  local hits
  hits=$(printf '%s' "$1" | grep -oE "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" || true)
  [ "$(printf '%s' "$hits" | grep -c .)" = 1 ] || return 0
  printf '%s' "$hits" | sed -E 's/.*:[[:space:]]*"([^"]*)"$/\1/'
}
release_report_check() {
  local tag="$1" commit="${2:-}" f rc=0 flat verdict rtag rcommit
  f="$(mktemp 2>/dev/null)" || { echo "a temp file for its token-report.json could not be created"; return 1; }
  case "$REPORT_BASE" in
    http://* | https://*)
      if ! command -v curl >/dev/null 2>&1; then
        rm -f "$f"; echo "its token-report.json could not be fetched (curl is not installed)"; return 1
      fi
      curl -fsSL --max-time 20 -o "$f" "$REPORT_BASE/$tag/token-report.json" 2>>"$LOG_FILE" || rc=$?
      if [ "$rc" = 22 ]; then rm -f "$f"; echo "its token-report.json is missing from the release"; return 1; fi
      if [ "$rc" != 0 ]; then rm -f "$f"; echo "its token-report.json could not be fetched (offline? curl exit $rc)"; return 1; fi
      ;;
    *)
      cp "$REPORT_BASE/$tag/token-report.json" "$f" 2>/dev/null || { rm -f "$f"; echo "its token-report.json is missing from the release"; return 1; }
      ;;
  esac
  flat="$(tr -d '\n\r' <"$f")"; rm -f "$f"
  verdict="$(json_str "$flat" verdict)"; rtag="$(json_str "$flat" release_tag)"; rcommit="$(json_str "$flat" release_commit)"
  if [ -z "$verdict" ] || [ -z "$rtag" ]; then echo "its token-report.json is unreadable"; return 1; fi
  if [ "$rtag" != "$tag" ]; then echo "its token-report.json is for $rtag, not $tag"; return 1; fi
  if [ -n "$commit" ] && [ "$rcommit" != "$commit" ]; then echo "its token-report.json is for a different commit"; return 1; fi
  if [ "$verdict" != pass ]; then echo "its token-report.json verdict is '$verdict' (session-token budget not met)"; return 1; fi
  return 0
}

refuse_release() { # refuse_release <target-version> <installed-version> <reason>: the one line the user sees
  log "refused v$1: $3"
  echo "Helix update refused: v$1 was not installed because $3; staying on v${2:-current}."
}

mark_checked() {
  mkdir -p "$STATE_DIR"
  date +%s >"$STAMP_FILE"
}

local_version() {
  # With a clone: its VERSION. Without one: the VERSION of the repo this script runs from.
  local f="$REPO/VERSION"
  [ -d "$REPO/.git" ] || f="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/VERSION"
  if [ -f "$f" ]; then
    tr -d '[:space:]' <"$f"
  else
    echo ""
  fi
}

refresh_cache_symlink() {
  local ver="$1"
  [ -n "$ver" ] || return 0
  [ -d "$REPO" ] || return 0
  mkdir -p "$CACHE_BASE"
  ln -sfn "$REPO" "$CACHE_BASE/$ver"
}

refresh_after_pull() {
  local ver="$1"
  refresh_cache_symlink "$ver"
  if [ -x "$REPO/scripts/link-skills.sh" ]; then
    HELIX_QUIET=1 bash "$REPO/scripts/link-skills.sh" >>"$LOG_FILE" 2>&1 \
      || note_error "link-skills.sh failed (exit $?) after updating to $ver"
  fi
  if [ -x "$REPO/scripts/claude-plugin-sync.sh" ]; then
    HELIX_QUIET=1 HELIX_REPO_DIR="$REPO" bash "$REPO/scripts/claude-plugin-sync.sh" >>"$LOG_FILE" 2>&1 \
      || note_error "claude-plugin-sync.sh failed (exit $?) after updating to $ver"
  fi
}

update_git_clone() {
  # Release-gated: move the clone only to the newest published release tag (vX.Y.Z), never to an
  # unreleased main. The publish job creates a tag only after every CI check passed, so a red main
  # (e.g. 1.5.89-1.5.92, 2026-09) never reaches users.
  if [ ! -d "$REPO/.git" ]; then
    return 1
  fi
  log "fetching origin/main and release tags..."
  # Release tags on origin are authoritative for this install clone: force-update local tags
  # (some installs carry stale v1.5.x tags that once pointed elsewhere, and a plain --tags fetch
  # refuses with "would clobber existing tag").
  if ! git -C "$REPO" fetch origin main '+refs/tags/v*:refs/tags/v*' --quiet 2>>"$LOG_FILE"; then
    note_error "git fetch from origin failed in $REPO (offline, proxy or TLS) — no update this session"
    return 1
  fi
  local tag
  tag=$(git -C "$REPO" tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -1)
  if [ -z "$tag" ]; then
    log "no release tag found — skip (never pull unreleased main)"
    return 1
  fi
  if ! git -C "$REPO" merge-base --is-ancestor "$tag" origin/main 2>/dev/null; then
    log "release $tag is not on origin/main — skip"
    return 1
  fi
  local target="${tag#v}"
  TARGET_VERSION="$target"
  local local_ver
  local_ver=$(local_version)
  if [ "$local_ver" = "$target" ]; then
    log "clone already at release $target"
    refresh_cache_symlink "$target"
    return 2
  fi
  if git -C "$REPO" merge-base --is-ancestor "$tag" HEAD 2>/dev/null; then
    log "clone ($local_ver) is already past release $target — nothing to do"
    return 2
  fi
  local why
  if ! why="$(release_report_check "$tag" "$(git -C "$REPO" rev-parse "$tag^{commit}")")"; then
    refuse_release "$target" "$local_ver" "$why"
    return 3
  fi
  log "updating $local_ver -> release $target..."
  if ! git -C "$REPO" merge --ff-only "$tag" --quiet 2>>"$LOG_FILE"; then
    note_error "fast-forward to $tag failed (local changes or diverged branch in $REPO)"
    return 1
  fi
  refresh_after_pull "$target"
  log "clone updated to release $target"
  return 0
}

update_marketplace_only() {
  local remote="$1"
  if ! command -v claude >/dev/null 2>&1; then
    log "no ~/.helix clone and no claude CLI — skip"
    return 0
  fi
  if [ -x "$REPO/scripts/claude-plugin-sync.sh" ]; then
    HELIX_QUIET=1 HELIX_REPO_DIR="$REPO" bash "$REPO/scripts/claude-plugin-sync.sh" >>"$LOG_FILE" 2>&1 \
      || note_error "claude-plugin-sync.sh failed (exit $?)"
  fi
  if claude plugin list 2>/dev/null | grep -A3 "helix@helix-dev" | grep -q "Version: $remote"; then
    log "helix@helix-dev already at $remote"
  else
    log "helix@helix-dev sync requested (target $remote)"
  fi
  return 0
}

# --- check mode: read-only. Nothing below run_check is reachable from it. ---
run_check() {
  auto_update_disabled && exit 0
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  local remote_ref="$REMOTE_URL" newest
  [ -d "$REPO/.git" ] && remote_ref="origin"
  log "check: ls-remote release tags ($remote_ref)"
  newest=$(newest_remote_release "$remote_ref") || { log "check: remote not readable — no notice"; exit 0; }
  mark_checked
  local installed
  installed=$(local_version)
  if [ -n "$newest" ] && [ -n "$installed" ] && version_gt "$newest" "$installed"; then
    echo "Helix v$newest is available (installed v$installed). Update: bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh"
  fi
  exit 0
}

MODE=update
case "${1:-}" in
  "") ;;
  --check) MODE=check ;;
  *) echo "usage: helix-auto-update.sh [--check]" >&2; exit 2 ;;
esac
if [ "$MODE" = check ]; then
  run_check
fi

# --- update mode: the command the user starts ---
mkdir -p "$STATE_DIR"
mark_checked

UPDATED=0
TARGET_VERSION=""
REMOTE=""
if [ -d "$REPO/.git" ]; then
  pull_rc=0
  update_git_clone || pull_rc=$?
  if [ "$pull_rc" -eq 0 ]; then
    UPDATED=1
    REMOTE="$TARGET_VERSION"
  fi
else
  REMOTE="$(newest_remote_release "$REMOTE_URL" || true)"
  if [ -z "$REMOTE" ]; then
    note_error "could not read the release tags from $REMOTE_URL (git ls-remote failed; check proxy or TLS settings)"
  elif ! why="$(release_report_check "v$REMOTE")"; then
    refuse_release "$REMOTE" "$(local_version)" "$why"
  else
    update_marketplace_only "$REMOTE"
  fi
fi

# A run that finished without a step failure clears the previous error notice.
if [ "$ERRORS_THIS_RUN" -eq 0 ]; then
  rm -f "$ERR_FILE" 2>/dev/null || true
fi

if [ "$UPDATED" -eq 1 ]; then
  echo "Helix updated to v$REMOTE (skills active; restart Claude Code once for plugin hooks if /helix looks old)."
fi

exit 0
