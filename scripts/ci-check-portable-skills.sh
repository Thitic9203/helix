#!/usr/bin/env bash
# Fail if committed skills/commands/references contain machine paths, host-specific tool
# names, or single-project coupling.
# Excludes docs that list forbidden patterns as examples.
# Uses grep (always present) rather than rg: a missing scanner must never read as "clean".

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DIRS=(skills commands references)
EXCLUDES=(
  --exclude=portable-content.md
  --exclude=gotchas.md
)

PATTERNS=(
  '/Users/'
  'C:\Users'
  '~/.helix'
  '~/.cursor'
  'pd3-web-portal'
  'pd3-api'
  'pw:login:pd3'
  'playwright.e2e.config'
  'learner-mhesi'
  'mycreditport.com'
  '.ols-qa-secrets'
  'mcp__Control_Chrome__'
)

FOUND=0
for pat in "${PATTERNS[@]}"; do
  # grep exits 0 = match, 1 = no match, 2 = error. An error is a failure, never "clean".
  set +e
  grep -rnF "${EXCLUDES[@]}" -e "$pat" -- "${DIRS[@]}"
  rc=$?
  set -e
  if [ "$rc" -eq 0 ]; then
    FOUND=1
  elif [ "$rc" -ne 1 ]; then
    echo "::error::grep failed (exit $rc) while scanning for '$pat'"
    exit 2
  fi
done

if [ "$FOUND" -eq 1 ]; then
  echo "::error::Portable-content violation in skills/, commands/ or references/. See references/portable-content.md"
  exit 1
fi

echo "ok: no portable-content violations in skills/, commands/ and references/"
