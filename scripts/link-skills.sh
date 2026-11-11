#!/usr/bin/env bash
# Link shippable Helix skills into common agent skill directories.
#
# Global (default): symlinks under ~/.cursor/skills, ~/.codex/skills, etc.
# Claude Code loads Helix from the plugin helix@helix-dev only, so ~/.claude/skills gets no links and
# old Helix links there are removed (Spec: docs/sdd/single-claude-install R1, R3-R5).
# Project (optional): set HELIX_LINK_WORKSPACE=/path/to/repo to also link under
#   .github/skills, .agents/skills, .windsurf/skills, .cline/skills, .gemini/skills

set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
REPO_P="$(cd "$REPO" && pwd -P)"
CLASHES=0
# Spec: docs/sdd/link-skills-no-delete — never delete or replace what Helix did not create.
. "$REPO/scripts/lib/helix-owned.sh"

# warn_clash <label> <name> <path>: one stderr line per skipped entry (R2, R10)
warn_clash() {
  local label="$1" name="$2" path="$3" kind
  if [ -L "$path" ]; then
    kind="symlink -> $(readlink "$path")"
  elif [ -d "$path" ]; then
    kind="folder"
  else
    kind="file"
  fi
  echo "skip ($label) $name: $path is your own $kind, not a Helix link. Rename or remove it, then run: bash $REPO/scripts/link-skills.sh" >&2
  CLASHES=$((CLASHES + 1))
}

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

  # Process substitution, not a pipe: CLASHES must survive the loop (plan.md).
  while IFS= read -r -d '' skill_md; do
    local src name target link_target
    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$DEST/$name"

    if [ -e "$target" ] || [ -L "$target" ]; then
      if ! helix_is_skill_link "$target" "$name" "$RELATIVE" "$REPO" "$REPO_P"; then
        warn_clash "$LABEL" "$name" "$target"   # R1, R3: leave it exactly as it is
        continue
      fi
    fi

    if [ "$RELATIVE" = 1 ]; then
      link_target="../../skills/$name"
    else
      link_target="$src"
    fi

    ln -sfn "$link_target" "$target"   # target is absent or a Helix link (R4, R5)
    echo "linked ($LABEL) $name"
  done < <(find "$SKILL_ROOT" -name SKILL.md \
    -not -path '*/in-progress/*' \
    -not -path '*/procedures/*' \
    -print0)
}

# remove_old_claude_links: unlink only Helix skill links under ~/.claude/skills (R3, R4)
remove_old_claude_links() {
  local dir="$HOME/.claude/skills" entry removed=0
  [ -d "$dir" ] || return 0
  for entry in "$dir"/*; do
    [ -L "$entry" ] || continue
    if helix_is_skill_link "$entry" "$(basename "$entry")" 0 "$REPO" "$REPO_P"; then
      rm -f -- "$entry"
      removed=$((removed + 1))
    fi
  done
  if [ "$removed" -gt 0 ]; then   # R5: one line, only when something was removed
    echo "removed $removed old Helix skill link(s) from $dir — Claude Code now loads Helix from the plugin only"
  fi
}

echo "=== Helix link-skills (repo: $REPO) ==="
echo ""
remove_old_claude_links

# --- Global user skill directories (Agent Skills interoperable paths) ---
GLOBAL_DESTS=(
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

if [ "$CLASHES" -gt 0 ]; then
  echo "$CLASHES skill(s) skipped because of name clashes (see above)" >&2
fi

echo ""
echo "Done. Skills source: $REPO/skills/"
echo "Docs: docs/supported-agents.md · prompts: references/agent-entry.md"
