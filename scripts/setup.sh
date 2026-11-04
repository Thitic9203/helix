#!/bin/bash
# Post-clone setup (skip if you used install.sh)

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -z "$REPO_ROOT" ]; then
  echo "Error: run from inside the repo"
  exit 1
fi

cd "$REPO_ROOT"

MARKETPLACE_NAME="helix-dev"
PLUGIN_NAME="helix"
CACHE_BASE="$HOME/.claude/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME"

bash "$REPO_ROOT/scripts/sync-version.sh"
VERSION="$(tr -d '[:space:]' < VERSION)"

# Remove only Helix's own version links; keep and warn about anything else
# (Spec: docs/sdd/link-skills-no-delete R11, R12).
. "$REPO_ROOT/scripts/lib/helix-owned.sh"
helix_link_plugin_cache "$CACHE_BASE" "$VERSION" "$REPO_ROOT"

git config core.hooksPath scripts/hooks
bash "$REPO_ROOT/scripts/link-skills.sh"

echo "Setup complete (v$VERSION)"
