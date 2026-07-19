#!/usr/bin/env bash
# gen-secret-hashes.sh — regenerate the HASH_ALL block in check-no-secrets.sh from a
# LOCAL, off-repo plaintext denylist. The cleartext OLS identifiers NEVER live in this
# public repo — only their SHA-256 hashes do. Run this after adding a new OLS secret to
# the local list, then paste the printed block into check-no-secrets.sh (HASH_ALL=...).
#
# Local list default: ~/.helix-ols-denylist  (one literal per line; # comments + blanks ignored)
# Override with: DENYLIST=/path/to/list ./scripts/gen-secret-hashes.sh
#
# Matching is case-insensitive and token-boundary (charset [A-Za-z0-9._@-], min len 6),
# so store each identifier as it appears as a discrete token (e.g. a full hostname).

set -o pipefail
DENYLIST="${DENYLIST:-$HOME/.helix-ols-denylist}"

if [ ! -f "$DENYLIST" ]; then
  echo "gen-secret-hashes: local denylist not found: $DENYLIST" >&2
  echo "Create it (chmod 600), one OLS identifier per line, then re-run." >&2
  exit 1
fi

hasher() {  # sha256 hex of stdin, macOS + linux
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else sha256sum | awk '{print $1}'; fi
}

echo "# Paste into check-no-secrets.sh as:  HASH_ALL='<first-hash>"
echo "# ...<more hashes>'  (single-quoted, newline-separated)"
n=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue ;; esac
  printf '%s' "$line" | tr '[:upper:]' '[:lower:]' | hasher
  n=$((n + 1))
done < "$DENYLIST"
echo "# ($n literals hashed)" >&2
