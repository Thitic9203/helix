#!/usr/bin/env bash
# Helix install health check — symlinks, version, optional workspace link hint.
#
# Usage:
#   bash ~/.helix/tc-fe-prep/scripts/helix-doctor.sh
#   HELIX_REPO_DIR=/path/to/helix bash scripts/helix-doctor.sh
#   HELIX_LINK_WORKSPACE=$PWD bash scripts/helix-doctor.sh  # also check project skills

set -euo pipefail

REPO="${HELIX_REPO_DIR:-$HOME/.helix/tc-fe-prep}"
FAIL=0
WARN=0

ok() { echo "  OK   $*"; }
warn() { echo "  WARN $*"; WARN=$((WARN + 1)); }
bad() { echo "  FAIL $*"; FAIL=$((FAIL + 1)); }

echo "=== Helix doctor ==="
echo ""

# --- Repo ---
if [ ! -d "$REPO/.git" ]; then
  bad "Helix repo not found at $REPO — run the pinned install block in README.md (Install, one-time)"
  echo ""
  echo "Result: FAIL (install required)"
  exit 1
fi

if [ -f "$REPO/VERSION" ]; then
  VER="$(tr -d '[:space:]' < "$REPO/VERSION")"
  ok "Version $VER at $REPO"
else
  bad "Missing VERSION in $REPO"
fi

if [ -d "$REPO/skills/helix" ]; then
  ok "Router skill present"
else
  bad "Missing skills/helix"
fi

# Same list link-skills.sh links, read from the repo (Spec: docs/sdd/skill-list-drift R1).
# An empty skills/ falls back to helix so the checks below still report what is missing.
. "$(cd "$(dirname "$0")" && pwd)/lib/skill-list.sh"
# Same "Helix link" test link-skills.sh uses (Spec: docs/sdd/link-skills-no-delete R13).
. "$(cd "$(dirname "$0")" && pwd)/lib/helix-owned.sh"
REPO_P="$(cd "$REPO" && pwd -P)"
EXPECTED_SKILLS=()
while IFS= read -r s; do EXPECTED_SKILLS+=("$s"); done < <(helix_linked_skills "$REPO")
[ "${#EXPECTED_SKILLS[@]}" -gt 0 ] || EXPECTED_SKILLS=(helix)
for s in "${EXPECTED_SKILLS[@]}"; do
  if [ -f "$REPO/skills/$s/SKILL.md" ]; then
    ok "Skill $s"
  else
    bad "Missing skills/$s/SKILL.md"
  fi
done

echo ""
echo "--- Global skill links (expect helix + $((${#EXPECTED_SKILLS[@]} - 1)) workflows) ---"

check_dest() {
  local dest="$1"
  local label="$2"
  local relative="${3:-0}"
  if [ ! -d "$(dirname "$dest")" ]; then
    warn "$label: parent missing ($(dirname "$dest")) — agent may not be installed"
    return
  fi
  if [ ! -d "$dest" ]; then
    warn "$label: $dest not found — run: bash $REPO/scripts/link-skills.sh"
    return
  fi
  local missing=0 clashes=0
  for s in "${EXPECTED_SKILLS[@]}"; do
    if [ ! -e "$dest/$s" ] && [ ! -L "$dest/$s" ]; then
      missing=$((missing + 1))
    elif ! helix_is_skill_link "$dest/$s" "$s" "$relative" "$REPO" "$REPO_P"; then
      clashes=$((clashes + 1))
      warn "$label: skill-name clash — $dest/$s is not a Helix link (your own skill?), so Helix's $s is not linked there. Rename or remove it, then run: bash $REPO/scripts/link-skills.sh"
    fi
  done
  if [ "$missing" -eq 0 ] && [ "$clashes" -eq 0 ]; then
    ok "$label: all ${#EXPECTED_SKILLS[@]} skills linked"
  elif [ "$missing" -gt 0 ]; then
    warn "$label: $missing skill(s) missing under $dest"
  fi
}

GLOBAL_DESTS=(
  "$HOME/.claude/skills|Claude Code"
  "$HOME/.cursor/skills|Cursor"
  "$HOME/.codex/skills|Codex"
  "$HOME/.copilot/skills|GitHub Copilot"
  "$HOME/.gemini/skills|Gemini CLI"
  "$HOME/.agents/skills|Agent Skills (~/.agents)"
  "$HOME/.codeium/windsurf/skills|Windsurf"
  "$HOME/.cline/skills|Cline"
  "$HOME/.config/opencode/skills|OpenCode"
  "$HOME/.pi/agent/skills|Pi"
)

for entry in "${GLOBAL_DESTS[@]}"; do
  dest="${entry%%|*}"
  label="${entry##*|}"
  check_dest "$dest" "$label"
done

echo ""
echo "--- Claude plugin cache ---"
CACHE_BASE="$HOME/.claude/plugins/cache/helix-dev/helix"
if [ -n "${VER:-}" ] && [ -L "$CACHE_BASE/$VER" ]; then
  ok "Plugin cache symlink $CACHE_BASE/$VER"
elif [ -d "$CACHE_BASE" ]; then
  warn "Plugin cache dir exists but version symlink missing — re-run install.sh"
else
  warn "Claude plugin cache not found (Claude Code only)"
fi

echo ""
echo "--- Claude Code marketplace plugin ---"
if command -v claude >/dev/null 2>&1; then
  PLIST="$(claude plugin list 2>/dev/null || true)"
  if echo "$PLIST" | grep -qF "helix@helix-dev"; then
    if echo "$PLIST" | grep -A4 "helix@helix-dev" | grep -q "Status: ✔ enabled"; then
      ok "helix@helix-dev enabled"
    else
      warn "helix@helix-dev installed but not enabled — run: bash $REPO/scripts/claude-plugin-sync.sh"
    fi
    if [ -n "${VER:-}" ] && echo "$PLIST" | grep -A3 "helix@helix-dev" | grep -q "Version: $VER"; then
      ok "helix@helix-dev version matches repo ($VER)"
    elif [ -n "${VER:-}" ]; then
      warn "helix@helix-dev version may be stale (repo $VER) — run: bash $REPO/scripts/claude-plugin-sync.sh"
    fi
  else
    warn "helix@helix-dev not installed — run: bash $REPO/scripts/claude-plugin-sync.sh"
  fi
  if echo "$PLIST" | grep -A4 "helix@local" | grep -q "Status: ✔ enabled"; then
    bad "Legacy helix@local is still enabled — run: bash $REPO/scripts/claude-plugin-sync.sh"
  elif echo "$PLIST" | grep -qF "helix@local"; then
    warn "Legacy helix@local still listed (should be disabled) — run: bash $REPO/scripts/claude-plugin-sync.sh"
  fi
else
  warn "Claude CLI not on PATH — skip marketplace plugin check"
fi

echo ""
echo "--- Auto-update freshness ---"
# helix-auto-update.sh --check writes this stamp after each successful check. A stamp older than a day
# means the SessionStart hook is not running the check (e.g. the hook itself fails).
STAMP="${HELIX_STATE_DIR:-$HOME/.helix}/.last-auto-update-check"
STALE_SEC="${HELIX_DOCTOR_STALE_SEC:-86400}"
if [ ! -f "$STAMP" ]; then
  warn "No auto-update stamp at $STAMP — the updater has never completed a check"
else
  _last="$(tr -d '[:space:]' < "$STAMP" 2>/dev/null || true)"
  case "$_last" in '' | *[!0-9]*) _last=0 ;; esac
  _age=$(( $(date +%s) - _last ))
  if [ "$_age" -gt "$STALE_SEC" ]; then
    warn "Last auto-update check was $((_age / 3600))h ago (limit $((STALE_SEC / 3600))h) — check the SessionStart hook and ${HELIX_STATE_DIR:-$HOME/.helix}/auto-update.log"
  else
    ok "Last auto-update check $((_age / 3600))h ago"
  fi
fi

if [ -n "${HELIX_DOCTOR_FIX:-}" ]; then
  echo ""
  echo "--- Auto-fix (HELIX_DOCTOR_FIX) ---"
  bash "$REPO/scripts/claude-plugin-sync.sh" || warn "claude-plugin-sync failed"
  bash "$REPO/scripts/link-skills.sh" 2>/dev/null || true
  if [ -n "${HELIX_LINK_WORKSPACE:-}" ]; then
    export HELIX_LINK_WORKSPACE
    bash "$REPO/scripts/link-skills.sh" 2>/dev/null || true
  fi
fi

if [ -n "${HELIX_LINK_WORKSPACE:-}" ]; then
  echo ""
  echo "--- Workspace: $HELIX_LINK_WORKSPACE ---"
  WS="$(cd "$HELIX_LINK_WORKSPACE" && pwd)"
  _ws_rel=0
  [ -f "$WS/skills/helix/SKILL.md" ] && _ws_rel=1
  for sub in .github/skills .agents/skills .windsurf/skills .cline/skills .gemini/skills; do
    check_dest "$WS/$sub" "${sub}" "$_ws_rel"
  done
  if [ -f "$WS/skills/helix/SKILL.md" ] && [ -L "$WS/.github/skills/helix" ]; then
    _hl="$(readlink "$WS/.github/skills/helix" 2>/dev/null || true)"
    case "$_hl" in
      ../../skills/helix) ok "Workspace .github/skills/helix uses portable relative link" ;;
      "$HOME"/*|.helix/*|/*)
        warn "Workspace has local skills/ but .github/skills/helix → $_hl (run HELIX_LINK_WORKSPACE=$WS …/link-skills.sh for relative links)"
        ;;
    esac
  fi
fi

# Leftovers from the retired helix-setup-devenv.sh (Spec: docs/sdd/retire-devenv R14). Read-only:
# prints one WARN per leftover and the undo command; prints nothing on a clean machine.
. "$(cd "$(dirname "$0")" && pwd)/lib/devenv-rules.sh"
_dv_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
_dv_undo="bash $REPO/scripts/helix-setup-devenv.sh --uninstall"
if command -v jq >/dev/null 2>&1 && [ -f "$_dv_dir/settings.json" ]; then
  _dv_n="$(devenv_leftover_rules "$_dv_dir/settings.json" | jq 'length' 2>/dev/null || echo 0)"
  [ "${_dv_n:-0}" -gt 0 ] && warn "devenv leftover: $_dv_n Helix allowlist rule(s) in $_dv_dir/settings.json — undo: $_dv_undo"
  devenv_helix_set_mode "$_dv_dir/settings.json" && warn "devenv leftover: permissions.defaultMode acceptEdits in $_dv_dir/settings.json was set by Helix — undo: $_dv_undo"
fi
[ -f "$_dv_dir/CLAUDE.md" ] && grep -qF "$DEVENV_MARK_START" "$_dv_dir/CLAUDE.md" 2>/dev/null \
  && warn "devenv leftover: HELIX-DEVENV block in $_dv_dir/CLAUDE.md — undo: $_dv_undo"
[ -f "${HELIX_STATE_DIR:-$HOME/.helix}/.devenv-opted-in" ] \
  && warn "devenv leftover: opt-in marker ${HELIX_STATE_DIR:-$HOME/.helix}/.devenv-opted-in — undo: $_dv_undo"

echo ""
echo "--- Works best with ---"
echo "  • Jira (MCP or browser logged in)"
echo "  • Playwright installed in the project you test"
echo "  • Optional: references/*-guide.md in your app repo"
echo ""
echo "Docs:  $REPO/docs/supported-agents.md"
echo "Start: /helix (Claude) · @helix / skill helix (others)"
echo "Direct: /tc-fe-prep /tc-api-prep /retest-bug /testing-ticket /create-bug"
echo "Update: you run bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh · session start only checks (HELIX_AUTO_UPDATE=0 turns the check off) · log ~/.helix/auto-update.log"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Result: FAIL ($FAIL error(s), $WARN warning(s))"
  exit 1
fi
if [ "$WARN" -gt 0 ]; then
  echo "Result: OK with warnings ($WARN) — install or link-skills may help"
  exit 0
fi
echo "Result: OK"
exit 0
