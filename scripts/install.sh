#!/bin/bash
# One-command install: clone + symlinks for major agent skill directories
#
# Usage: run the pinned install block from README.md ("Install (one-time)"). It downloads this file
# from a named release, checks its SHA-256, and runs it with HELIX_TAG set to that release.
# The clone is checked out at that tag, not at main.
#
# Optional (from your project root), set in the same shell before the block's last line:
#   HELIX_LINK_WORKSPACE=1
#   — or after install: HELIX_LINK_WORKSPACE=$PWD ~/.helix/tc-fe-prep/scripts/link-skills.sh

set -e

REPO_URL="https://github.com/Thitic9203/helix.git"
REPO_DIR="${HELIX_REPO_DIR:-$HOME/.helix/tc-fe-prep}"
MARKETPLACE_NAME="helix-dev"
PLUGIN_NAME="helix"
CANONICAL="helix@helix-dev"
CACHE_BASE="$HOME/.claude/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME"

echo "=== Helix QA assistant installer ==="
echo ""

# 1. Clone, or move the existing clone, to the named release tag (never main).
# Spec: docs/sdd/install-pinned-checksum R6 R7
die() { echo "install.sh: $*" >&2; exit 1; }
HELIX_TAG="${HELIX_TAG:-}"
if [ -n "$HELIX_TAG" ] && ! [[ "$HELIX_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "HELIX_TAG must be a release tag like v1.2.3 (got: $HELIX_TAG)"
fi
if [ -d "$REPO_DIR/.git" ]; then
  if [ -z "$HELIX_TAG" ]; then
    echo "[1/5] Repo exists — HELIX_TAG not set, using the clone as it is (no git move)."
  else
    echo "[1/5] Repo exists — moving to $HELIX_TAG..."
    if [ -n "$(git -C "$REPO_DIR" status --porcelain --untracked-files=no)" ]; then
      die "$REPO_DIR has local changes; commit or undo them yourself, nothing was changed"
    fi
    git -C "$REPO_DIR" fetch origin "+refs/tags/$HELIX_TAG:refs/tags/$HELIX_TAG" --quiet \
      || die "could not fetch tag $HELIX_TAG from origin (offline, or the tag does not exist); nothing was changed"
    if ! git -C "$REPO_DIR" merge-base --is-ancestor HEAD "$HELIX_TAG" 2>/dev/null; then
      die "$REPO_DIR sits on a commit that is not an ancestor of $HELIX_TAG (local commits or unreleased main); nothing was changed"
    fi
    git -C "$REPO_DIR" merge --ff-only "$HELIX_TAG" --quiet \
      || die "could not fast-forward $REPO_DIR to $HELIX_TAG; nothing was changed"
  fi
else
  [ -n "$HELIX_TAG" ] || die "HELIX_TAG is not set; run the pinned install block from README.md (Install, one-time)"
  echo "[1/5] Cloning repo at $HELIX_TAG..."
  mkdir -p "$(dirname "$REPO_DIR")"
  git -c advice.detachedHead=false clone --branch "$HELIX_TAG" "$REPO_URL" "$REPO_DIR" --quiet \
    || die "could not clone tag $HELIX_TAG from $REPO_URL"
fi

cd "$REPO_DIR"

# 2. Claude Code plugin cache symlink
if [ -f VERSION ]; then
  VERSION="$(tr -d '[:space:]' < VERSION)"
else
  echo "Error: missing VERSION file"
  exit 1
fi
bash "$REPO_DIR/scripts/sync-version.sh" --check 2>/dev/null || bash "$REPO_DIR/scripts/sync-version.sh"

echo "[2/5] Claude plugin cache symlink (v$VERSION)..."
# Remove only Helix's own version links; keep and warn about anything else
# (Spec: docs/sdd/link-skills-no-delete R11, R12).
. "$REPO_DIR/scripts/lib/helix-owned.sh"
helix_link_plugin_cache "$CACHE_BASE" "$VERSION" "$REPO_DIR"

# 3. Link skills for all supported agents
echo "[3/5] Linking skills (global + optional workspace)..."
if [ -n "${HELIX_LINK_WORKSPACE:-}" ]; then
  export HELIX_LINK_WORKSPACE
fi
bash "$REPO_DIR/scripts/link-skills.sh"

# 4. Git hooks for cache rename on pull
echo "[4/5] Enabling git hooks (cache rename on pull)..."
git config core.hooksPath scripts/hooks

# 5. Claude Code: helix@helix-dev (not legacy helix@local)
echo "[5/5] Claude Code plugin ($CANONICAL via scripts/claude-plugin-sync.sh)..."
bash "$REPO_DIR/scripts/claude-plugin-sync.sh" || true

echo ""
echo "=== Install complete ==="
echo "Repo:    $REPO_DIR"
echo "Plugin:  $CACHE_BASE/$VERSION -> $REPO_DIR"
echo ""
echo "Version: $VERSION"
echo ""
echo "Start Helix:"
echo "  Claude Code     /helix"
echo "  Cursor/Windsurf @helix  (skill: helix)"
echo "  Copilot/Cline   use skill helix — see references/agent-entry.md"
echo ""
echo "Workflow shortcuts (Claude Code): /tc-fe-prep /tc-api-prep /retest-bug /testing-ticket /create-bug"
echo ""
echo "Supported agents: docs/supported-agents.md"
echo "Health check:   bash $REPO_DIR/scripts/helix-doctor.sh"
echo "Claude plugin:  bash $REPO_DIR/scripts/claude-plugin-sync.sh  (helix@helix-dev only)"
echo "Update:         bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh"
echo ""
if [ -z "${HELIX_LINK_WORKSPACE:-}" ]; then
  echo "Tip: link into current project (Copilot team):"
  echo "  HELIX_LINK_WORKSPACE=\$PWD $REPO_DIR/scripts/link-skills.sh"
fi
