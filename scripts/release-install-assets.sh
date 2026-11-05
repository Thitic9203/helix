#!/usr/bin/env bash
# Build the two release assets of the pinned install: install.sh and install.sh.sha256.
# Usage: scripts/release-install-assets.sh <out-dir>
# Used by the release job (.github/workflows/version.yml); kept here so it can be tested offline.
# Spec: docs/sdd/install-pinned-checksum R1 R9
set -euo pipefail

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
  echo "usage: release-install-assets.sh <out-dir>" >&2
  exit 2
fi
OUT="$1"
SRC="$(cd "$(dirname "$0")" && pwd)/install.sh"
[ -f "$SRC" ] || { echo "error: $SRC not found" >&2; exit 1; }

# one hash tool is enough: GNU sha256sum, else Perl shasum (macOS)
if command -v sha256sum >/dev/null 2>&1; then
  hash_of() { sha256sum "$1" | cut -d' ' -f1; }
  check_in() { (cd "$1" && sha256sum -c install.sh.sha256 >/dev/null); }
elif command -v shasum >/dev/null 2>&1; then
  hash_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
  check_in() { (cd "$1" && shasum -a 256 -c install.sh.sha256 >/dev/null); }
else
  echo "error: neither sha256sum nor shasum is available" >&2
  exit 1
fi

mkdir -p "$OUT"
cp "$SRC" "$OUT/install.sh"
cmp -s "$SRC" "$OUT/install.sh" || { echo "error: copy of install.sh differs from source" >&2; exit 1; }

HASH="$(hash_of "$OUT/install.sh")"
case "$HASH" in
  *[!0-9a-f]*|"") echo "error: not a SHA-256 hex digest: '$HASH'" >&2; exit 1 ;;
esac
[ "${#HASH}" -eq 64 ] || { echo "error: SHA-256 digest is not 64 hex characters" >&2; exit 1; }

printf '%s  install.sh\n' "$HASH" > "$OUT/install.sh.sha256"
# same check a user runs; if it fails here the release must not be created
if ! check_in "$OUT"; then
  rm -f "$OUT/install.sh.sha256"
  echo "error: self-check of install.sh.sha256 failed" >&2
  exit 1
fi
echo "ok: $OUT/install.sh and install.sh.sha256 ($HASH)"
