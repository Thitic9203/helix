#!/usr/bin/env bash
# Link shippable Helix skills into common agent skill directories.
#
# Global (default): symlinks under ~/.claude/skills, ~/.cursor/skills, etc.
# Project (optional): set HELIX_LINK_WORKSPACE=/path/to/repo to also link under
#   .github/skills, .agents/skills, .windsurf/skills, .cline/skills, .gemini/skills

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

link_into() {
  local DEST="$1"
  local LABEL="$2"
  local SKILL_ROOT="${3:-$REPO/skills}"
  local RELATIVE="${4:-0}"

  [ -d "$(dirname "$DEST")" ] || return 0

  if [ -L "$DEST" ]; then
    local resolved
    resolved="$(readlink -f "$DEST" 2>/dev/null || readlink "$DEST")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "skip $LABEL: $DEST is already part of this repo"
        return 0
        ;;
    esac
  fi

  mkdir -p "$DEST"

  find "$SKILL_ROOT" -name SKILL.md \
    -not -path '*/in-progress/*' \
    -not -path '*/deprecated/*' \
    -print0 |
  while IFS= read -r -d '' skill_md; do
    local src name target link_target
    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$DEST/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    if [ "$RELATIVE" = 1 ]; then
      link_target="../../skills/$name"
    else
      link_target="$src"
    fi

    ln -sfn "$link_target" "$target"
    echo "linked ($LABEL) $name"
  done
}

echo "=== Helix link-skills (repo: $REPO) ==="
echo ""

# --- Global user skill directories (Agent Skills interoperable paths) ---
GLOBAL_DESTS=(
  "$HOME/.claude/skills|claude"
  "$HOME/.cursor/skills|cursor"
  "$HOME/.codex/skills|codex"
  "$HOME/.copilot/skills|copilot"
  "$HOME/.gemini/skills|gemini"
  "$HOME/.agents/skills|agents"
  "$HOME/.codeium/windsurf/skills|windsurf"
  "$HOME/.cline/skills|cline"
  "$HOME/.config/opencode/skills|opencode"
  "$HOME/.pi/agent/skills|pi"
)

for entry in "${GLOBAL_DESTS[@]}"; do
  dest="${entry%%|*}"
  label="${entry##*|}"
  link_into "$dest" "$label"
done

# --- Optional project / workspace scope ---
if [ -n "${HELIX_LINK_WORKSPACE:-}" ]; then
  WS="$(cd "$HELIX_LINK_WORKSPACE" && pwd)"
  echo ""
  echo "=== Workspace: $WS ==="
  WS_SKILL_ROOT="$REPO/skills"
  WS_RELATIVE=0
  if [ -f "$WS/skills/helix/SKILL.md" ]; then
    WS_SKILL_ROOT="$WS/skills"
    WS_RELATIVE=1
    echo "workspace has local skills/ — using relative symlinks (portable for git)"
  fi
  WORKSPACE_DESTS=(
    "$WS/.github/skills|github-copilot"
    "$WS/.agents/skills|agents-project"
    "$WS/.windsurf/skills|windsurf-project"
    "$WS/.cline/skills|cline-project"
    "$WS/.gemini/skills|gemini-project"
  )
  for entry in "${WORKSPACE_DESTS[@]}"; do
    dest="${entry%%|*}"
    label="${entry##*|}"
    link_into "$dest" "$label" "$WS_SKILL_ROOT" "$WS_RELATIVE"
  done
fi

echo ""
echo "Done. Skills source: $REPO/skills/"
echo "Docs: docs/supported-agents.md · prompts: references/agent-entry.md"
