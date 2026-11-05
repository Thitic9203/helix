#!/usr/bin/env bash
# No documented or scripted path pipes a download into bash (it used to read straight from main).
# Spec: docs/sdd/install-pinned-checksum R5 R8
# docs/sdd/ and docs/plan/ are left out: they quote the old line as evidence.
. "$(dirname "$0")/lib.sh"
cd "$REPO_ROOT"
# the pattern is built from parts so this file does not match itself
PIPE="[|] *ba""sh"
hits="$(git grep -nE "curl.*${PIPE}" -- README.md docs scripts .github ':!docs/sdd' ':!docs/plan' || true)"
if [ -z "$hits" ]; then ok "no curl-into-bash line in README, docs, scripts, .github"
else fail "curl piped into bash still present:"; printf '%s\n' "$hits" | sed 's/^/        /'; fi
hits="$(git grep -nE "raw\.githubusercontent\.com/[^ ]*/main/[^ ]*install\.sh" -- README.md docs scripts .github ':!docs/sdd' ':!docs/plan' || true)"
if [ -z "$hits" ]; then ok "no install.sh URL that reads from main"
else fail "install.sh read from main still referenced:"; printf '%s\n' "$hits" | sed 's/^/        /'; fi
hits="$(git grep -nE "git (-C [^ ]+ )?pull( origin main)?" -- scripts/install.sh scripts/helix-doctor.sh || true)"
if [ -z "$hits" ]; then ok "install.sh and helix-doctor.sh neither run nor print a git pull of main"
else fail "git pull of main still in install.sh / helix-doctor.sh:"; printf '%s\n' "$hits" | sed 's/^/        /'; fi
finish
