#!/usr/bin/env bash
# Run every scripts/tests/*.test.sh; exit non-zero if any fails or none ran.
set -uo pipefail
cd "$(dirname "$0")"
failed=0; ran=0
for t in *.test.sh; do
  [ -e "$t" ] || continue
  ran=$((ran + 1)); echo "== $t"
  bash "$t" || failed=$((failed + 1))
done
[ "$ran" -gt 0 ] || { echo "no test files found — refusing"; exit 2; }
echo "== $ran test files, $failed failed"
[ "$failed" -eq 0 ]
