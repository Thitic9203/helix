#!/usr/bin/env bash
# install.sh puts the clone on the named release tag, never on main, and never discards work.
# Spec: docs/sdd/install-pinned-checksum R6 R7
# Sandbox: a bare "origin" with tags v0.9.0, v1.0.0 and a later unreleased commit on main, a
# sandbox HOME, a stub `claude`, and git redirected to the local origin with url.insteadOf.
. "$(dirname "$0")/lib.sh"
S="$(mktemp -d)"; trap 'rm -rf "$S"' EXIT
G() { git -c user.name=t -c user.email=t@t "$@"; }

W="$S/work"; mkdir -p "$W"
(cd "$REPO_ROOT" && git ls-files -co --exclude-standard -z | xargs -0 -I{} sh -c 'mkdir -p "$1/$(dirname "$2")" && cp -P "$2" "$1/$2"' _ "$W" {})
( cd "$W" && git init -q -b main && echo 0.9.0 > VERSION && bash scripts/sync-version.sh >/dev/null 2>&1 \
  && G add -A >/dev/null 2>&1 && G commit -q -m c1 && git tag v0.9.0 \
  && echo 1.0.0 > VERSION && bash scripts/sync-version.sh >/dev/null 2>&1 && G commit -q -am c2 && git tag v1.0.0 \
  && echo unreleased > UNRELEASED && G add UNRELEASED && G commit -q -m c3 ) || { fail "sandbox origin built"; finish; exit $?; }
C1="$(git -C "$W" rev-parse v0.9.0)"; C2="$(git -C "$W" rev-parse v1.0.0)"; C3="$(git -C "$W" rev-parse main)"
git clone -q --bare "$W" "$S/origin.git"
mkdir -p "$S/bin"; printf '#!/bin/sh\nexit 0\n' > "$S/bin/claude"; chmod +x "$S/bin/claude"
INSTALL="$REPO_ROOT/scripts/install.sh"

new_home() { rm -rf "$S/home"; mkdir -p "$S/home"; REPO="$S/home/.helix/tc-fe-prep"; }
run_install() { # run_install [VAR=value ...] -> exit code; log in $S/log
  ( cd "$S/home" && env -u HELIX_TAG HOME="$S/home" PATH="$S/bin:$PATH" GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
      GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0="url.$S/origin.git.insteadOf" GIT_CONFIG_VALUE_0="https://github.com/Thitic9203/helix.git" \
      "$@" bash "$INSTALL" ) >"$S/log" 2>&1
}
head_of() { git -C "$REPO" rev-parse HEAD 2>/dev/null; }
mk_clone_at() { # mk_clone_at <sha>: an old-style clone (branch main) moved to <sha>
  mkdir -p "$(dirname "$REPO")"; git clone -q "$S/origin.git" "$REPO" && git -C "$REPO" checkout -q "$1"; }

new_home; run_install HELIX_TAG=v1.0.0; rc=$?
{ [ "$rc" -eq 0 ] && [ "$(head_of)" = "$C2" ] && [ ! -e "$REPO/UNRELEASED" ]; } && ok "fresh install with HELIX_TAG=v1.0.0 ends at the tag, not main" || fail "fresh install (rc=$rc head=$(head_of) want $C2; $(tail -2 "$S/log" | tr '\n' ' '))"

new_home; mk_clone_at "$C1"; run_install HELIX_TAG=v1.0.0; rc=$?
{ [ "$rc" -eq 0 ] && [ "$(head_of)" = "$C2" ]; } && ok "existing clone behind the tag fast-forwards to the tag (not to main)" || fail "ff to tag (rc=$rc head=$(head_of) want $C2; $(tail -2 "$S/log" | tr '\n' ' '))"

new_home; mk_clone_at "$C2"; run_install HELIX_TAG=v1.0.0; rc=$?
{ [ "$rc" -eq 0 ] && [ "$(head_of)" = "$C2" ]; } && ok "clone already at the tag: install succeeds, HEAD unchanged" || fail "already at tag (rc=$rc)"

new_home; mk_clone_at "$C2"; (cd "$REPO" && echo mine > mine.txt && G add mine.txt && G commit -q -m local); before="$(head_of)"
run_install HELIX_TAG=v1.0.0; rc=$?
{ [ "$rc" -ne 0 ] && [ "$(head_of)" = "$before" ] && [ -f "$REPO/mine.txt" ]; } && ok "local commit: rc=$rc, commit and file still there" || fail "local commit (rc=$rc head=$(head_of) want $before)"
grep -q '^install.sh: .*not an ancestor' "$S/log" && ok "...and it says why" || fail "no reason printed for the local-commit refusal: $(tail -2 "$S/log")"

new_home; mk_clone_at "$C1"; echo edited >> "$REPO/README.md"; before="$(head_of)"
run_install HELIX_TAG=v1.0.0; rc=$?
{ [ "$rc" -ne 0 ] && [ "$(head_of)" = "$before" ] && tail -1 "$REPO/README.md" | grep -q '^edited$'; } && ok "uncommitted edit: rc=$rc, edit and HEAD untouched" || fail "uncommitted edit (rc=$rc)"
grep -q '^install.sh: .*local changes' "$S/log" && ok "...and it says why" || fail "no reason printed for the dirty-clone refusal: $(tail -2 "$S/log")"

new_home; mk_clone_at "$C3"; run_install HELIX_TAG=v1.0.0; rc=$?
{ [ "$rc" -ne 0 ] && [ "$(head_of)" = "$C3" ]; } && ok "clone on unreleased main (ahead of the tag): rc=$rc, HEAD stays" || fail "clone ahead of tag (rc=$rc head=$(head_of))"

for bad in main v1.0 v1.0.0-x '../x' ''; do
  new_home; run_install "HELIX_TAG=$bad"; rc=$?
  { [ "$rc" -ne 0 ] && [ ! -e "$REPO" ]; } && ok "HELIX_TAG='$bad' is refused, nothing cloned" || fail "HELIX_TAG='$bad' (rc=$rc, clone exists? $([ -e "$REPO" ] && echo y || echo n))"
done
new_home; run_install HELIX_TAG=v9.9.9; rc=$?
{ [ "$rc" -ne 0 ] && [ ! -e "$REPO/.git" ]; } && ok "unknown tag v9.9.9: rc=$rc, no half clone left" || fail "unknown tag (rc=$rc)"
new_home; run_install; rc=$?
{ [ "$rc" -ne 0 ] && [ ! -e "$REPO" ]; } && ok "HELIX_TAG unset and no clone: refused (rc=$rc), nothing created" || fail "unset tag, no clone (rc=$rc)"
new_home; mk_clone_at "$C1"; run_install; rc=$?
{ [ "$rc" -eq 0 ] && [ "$(head_of)" = "$C1" ]; } && ok "HELIX_TAG unset, existing clone: re-links the clone as it is, no git move" || fail "unset tag, existing clone (rc=$rc head=$(head_of))"
finish
