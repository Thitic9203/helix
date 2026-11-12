#!/usr/bin/env bash
# docs/sdd/update-notify-only: session start only NOTIFIES; the update command the user starts is the
# only thing that fetches, moves the clone, or re-links. Everything is offline: origin is a bare repo on
# disk, HOME is a throwaway directory, claude/curl are stubs that leave a sentinel.
. "$(dirname "$0")/lib.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
AU="$REPO_ROOT/scripts/helix-auto-update.sh"
HOOK="$REPO_ROOT/hooks/session-start"
UPD='bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh'

# --- sandbox: bare origin with v1.0.0 and v1.0.1; v1.0.1 carries stub link/sync scripts ---------------
mkdir -p "$W/bin"
printf '#!/bin/sh\necho x >> "%s/sentinel-claude"\n' "$W" > "$W/bin/claude"
printf '#!/bin/sh\necho x >> "%s/sentinel-curl"\n' "$W" > "$W/bin/curl"
chmod +x "$W/bin/claude" "$W/bin/curl"
git init -q --bare -b main "$W/origin.git"
git init -q -b main "$W/seed"; cd "$W/seed"
git config user.name t; git config user.email t@example.invalid
echo 1.0.0 > VERSION; git add VERSION; git commit -qm v1.0.0; git tag v1.0.0
mkdir scripts
for s in link-skills claude-plugin-sync; do
  printf '#!/bin/sh\necho x >> "%s/sentinel-%s"\n' "$W" "$s" > "scripts/$s.sh"; chmod +x "scripts/$s.sh"
done
echo 1.0.1 > VERSION; git add VERSION scripts; git commit -qm v1.0.1; git tag v1.0.1
git remote add origin "$W/origin.git"; git push -q origin main --tags
cd "$REPO_ROOT"

setup() { # setup <tag>: a clone parked at <tag>, a fresh fake HOME with one symlink per watched dir
  rm -rf "$W/clone" "$W/home" "$W/state" "$W"/sentinel-*
  git clone -q "$W/origin.git" "$W/clone"; git -C "$W/clone" reset -q --hard "$1"
  mkdir -p "$W/home/.claude/skills" "$W/home/.claude/plugins/cache/helix-dev/helix" "$W/state"
  ln -s "$W/clone" "$W/home/.claude/skills/helix"
  ln -s "$W/clone" "$W/home/.claude/plugins/cache/helix-dev/helix/$(cat "$W/clone/VERSION")"
}
snap() { # everything the hook must leave alone
  git -C "$W/clone" rev-parse HEAD
  git -C "$W/clone" for-each-ref
  git -C "$W/clone" status --porcelain
  ls -a "$W/clone/.git" | grep -c FETCH_HEAD
  ls -laR "$W/home/.claude/skills" "$W/home/.claude/plugins"
}
hook() { env HELIX_REMOTE_URL="$W/no-such-remote.git" HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" "$@" bash "$HOOK" 2>/dev/null; }
update_cmd() { env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" "$@" bash "$AU" >/dev/null 2>&1; }
ctx() { python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("additionalContext") or d["hookSpecificOutput"]["additionalContext"])'; }
notices() { grep -cE 'Helix v[0-9.]+ is available' <<<"$(ctx <<<"$1")"; }
valid_json() { printf '%s' "$1" | python3 -c 'import json,sys; json.load(sys.stdin)' 2>/dev/null; }
sentinels() { ls "$W"/sentinel-* 2>/dev/null | wc -l | tr -d ' '; }

# --- T1/T2: hook leaves state alone and prints exactly one notice ------------------------------------
setup v1.0.0; before="$(snap)"; out="$(hook)"; after="$(snap)"
[ "$before" = "$after" ] && ok "R1/R2: hook leaves clone HEAD, refs, status, skill dirs and plugin cache untouched" \
  || fail "R1/R2: state changed: $(diff <(echo "$before") <(echo "$after") | head -4 | tr '\n' ' ')"
[ "$(sentinels)" = 0 ] && ok "R2: hook ran no link-skills / claude-plugin-sync / claude" || fail "R2: sentinels: $(ls "$W"/sentinel-* | xargs -n1 basename | tr '\n' ' ')"
valid_json "$out" && ok "R5: hook output is one valid JSON object" || fail "R5: invalid JSON: $out"
[ "$(notices "$out")" = 1 ] && ok "R5: exactly one notice line when a newer release exists" || fail "R5: notice count $(notices "$out")"
ctx <<<"$out" | grep -q "Helix v1.0.1 is available (installed v1.0.0). Update: $UPD" \
  && ok "R5: notice names both versions and the update command" || fail "R5: notice text: $(ctx <<<"$out" | grep available)"

# --- R15: notice tells the agent to ask first, run the update command only on yes ---------------------
ctx <<<"$out" | grep -qiE 'ask the user' && ctx <<<"$out" | grep -qiE 'only (after|if|when) the user (answers|says|confirms) yes' \
  && ok "R15: notice tells the agent to ask the user and update only on yes" || fail "R15: notice has no ask-then-update instruction: $(ctx <<<"$out" | grep -A1 'update available')"
ctx <<<"$out" | grep -q "$UPD" && ok "R15: notice carries the update command to run on yes" || fail "R15: no update command in notice"

# --- T7: the check writes the freshness stamp --------------------------------------------------------
st="$W/state/.last-auto-update-check"
if [ -f "$st" ]; then
  d=$(( $(date +%s) - $(tr -d '[:space:]' < "$st") ))
  [ "$d" -ge 0 ] && [ "$d" -le 5 ] && ok "R11: check wrote the stamp (${d}s old)" || fail "R11: stamp age ${d}s"
else fail "R11: no stamp written"; fi

# --- T3: FORCE and interval cannot unlock the hook ---------------------------------------------------
setup v1.0.0; before="$(snap)"; out="$(hook HELIX_FORCE_UPDATE=1 HELIX_AUTO_UPDATE_INTERVAL_SEC=0)"; after="$(snap)"
[ "$before" = "$after" ] && [ "$(sentinels)" = 0 ] && ok "R7/R9/R10: FORCE_UPDATE=1 + INTERVAL_SEC=0 change nothing in the hook" || fail "R7/R9/R10: moved or ran stubs"
[ "$(notices "$out")" = 1 ] && ok "R10: check still runs every session (one notice)" || fail "R10: notice count $(notices "$out")"

# --- T4: nothing newer, nothing printed --------------------------------------------------------------
setup v1.0.1; out="$(hook)"
[ "$(notices "$out")" = 0 ] && valid_json "$out" && ok "R5: clone at the newest release: no notice" || fail "R5: notice at newest"
git -C "$W/clone" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m ahead
out="$(hook)"
[ "$(notices "$out")" = 0 ] && ok "R5: clone ahead of the newest release: no notice" || fail "R5: notice when ahead"

# --- T5: off switch ----------------------------------------------------------------------------------
setup v1.0.0; hook >/dev/null
grep -q "ls-remote" "$W/state/auto-update.log" 2>/dev/null && ok "R8 control: an enabled check logs its ls-remote" || fail "R8 control: no ls-remote line when enabled"
setup v1.0.0; out="$(hook HELIX_AUTO_UPDATE=0)"
[ "$(notices "$out")" = 0 ] && valid_json "$out" && ok "R8: HELIX_AUTO_UPDATE=0 prints no notice" || fail "R8: notice with the check off"
! grep -q "ls-remote" "$W/state/auto-update.log" 2>/dev/null && [ ! -e "$W/state/.last-auto-update-check" ] \
  && ok "R8: HELIX_AUTO_UPDATE=0 does no ls-remote and writes no stamp" || fail "R8: check ran with HELIX_AUTO_UPDATE=0"
update_cmd HELIX_AUTO_UPDATE=0
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "R8: HELIX_AUTO_UPDATE=0 does not block the update command" || fail "R8: update command blocked by the off switch"

# --- T6: offline check is quiet ----------------------------------------------------------------------
setup v1.0.0; git -C "$W/clone" remote set-url origin "$W/missing.git"
out="$(hook)"
[ "$(notices "$out")" = 0 ] && valid_json "$out" && [ ! -e "$W/state/last-update-error" ] \
  && ok "R12: unreachable remote: no notice, valid JSON, no last-update-error" || fail "R12: offline check noisy (error file: $(cat "$W/state/last-update-error" 2>/dev/null))"

# --- T8: no clone -> ls-remote on the repo URL, never curl -------------------------------------------
setup v1.0.0; rm -rf "$W/clone" "$W/copy"; mkdir -p "$W/copy/scripts"
cp "$AU" "$W/copy/scripts/"; echo 1.0.0 > "$W/copy/VERSION"
nc="$(env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_REMOTE_URL="$W/origin.git" \
  bash "$W/copy/scripts/helix-auto-update.sh" --check 2>/dev/null)"
grep -q "v1.0.1 is available" <<<"$nc" && ok "R3/R4: no clone: newer tag found by ls-remote on the repo URL" || fail "R3/R4: no-clone output: '$nc'"
[ "$(sentinels)" = 0 ] && ok "R4: no curl, no claude call in the no-clone check" || fail "R4: sentinel present: $(ls "$W"/sentinel-* | xargs -n1 basename | tr '\n' ' ')"

# --- T9: the update command still updates ------------------------------------------------------------
setup v1.0.0; update_cmd
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "R6: update command moves the clone to v1.0.1" || fail "R6: clone at $(cat "$W/clone/VERSION")"
[ "$(wc -l < "$W/sentinel-link-skills" 2>/dev/null | tr -d ' ')" = 1 ] && [ "$(wc -l < "$W/sentinel-claude-plugin-sync" 2>/dev/null | tr -d ' ')" = 1 ] \
  && ok "R6: update command runs link-skills and claude-plugin-sync once each" || fail "R6: stub runs missing"
[ -L "$W/home/.claude/plugins/cache/helix-dev/helix/1.0.1" ] && ok "R6: update command refreshes the cache symlink" || fail "R6: no 1.0.1 cache link"
setup v1.0.0; update_cmd HELIX_FORCE_UPDATE=1 HELIX_AUTO_UPDATE_INTERVAL_SEC=99999
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "R9/R10: update command accepts and ignores FORCE_UPDATE / INTERVAL_SEC" || fail "R9/R10: update command affected"

# --- T10: bad argument -------------------------------------------------------------------------------
setup v1.0.0; before="$(snap)"
env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" bash "$AU" --chek >/dev/null 2>&1; rc=$?
[ "$rc" = 2 ] && [ "$before" = "$(snap)" ] && [ "$(sentinels)" = 0 ] && ok "R7: unknown argument exits 2 and changes nothing" || fail "R7: rc=$rc"

# --- T12: error tip text -----------------------------------------------------------------------------
setup v1.0.0; mkdir -p "$W/home/.helix"; echo "2026-01-01T00:00:00Z link-skills.sh failed (exit 1) after updating to 1.0.1" > "$W/home/.helix/last-update-error"
out="$(hook)"; c="$(ctx <<<"$out")"
grep -q "Helix update problem" <<<"$c" && grep -qF "$UPD" <<<"$c" && ! grep -q "HELIX_FORCE_UPDATE" <<<"$c" \
  && ok "R12: recorded error is surfaced as 'Helix update problem' with the update command" || fail "R12: error tip text wrong"
[ -s "$W/home/.helix/last-update-error" ] && [ ! -e "$W/state/last-update-error" ] && ok "R12: the hook neither clears nor writes the error file" || fail "R12: hook touched the error file"

# --- T14: migration — old updater fetches this release once; the next session only notifies ----------
rm -rf "$W/m"; mkdir -p "$W/m"
git init -q --bare -b main "$W/m/origin.git"; git init -q -b main "$W/m/seed"; cd "$W/m/seed"
git config user.name t; git config user.email t@example.invalid
mkdir -p scripts hooks
cp "$REPO_ROOT/scripts/tests/fixtures/helix-auto-update.pre-r2.sh" scripts/helix-auto-update.sh
echo 1.0.0 > VERSION; git add -A; git commit -qm v1.0.0; git tag v1.0.0
cp "$AU" scripts/helix-auto-update.sh; cp "$HOOK" hooks/session-start
for s in link-skills claude-plugin-sync; do printf '#!/bin/sh\necho x >> "%s/sentinel-%s"\n' "$W" "$s" > "scripts/$s.sh"; done
chmod +x scripts/*.sh hooks/session-start
echo 1.0.1 > VERSION; git add -A; git commit -qm v1.0.1; git tag v1.0.1
git remote add origin "$W/m/origin.git"; git push -q origin main --tags; cd "$REPO_ROOT"
rm -rf "$W/clone" "$W/home" "$W/state" "$W"/sentinel-*; mkdir -p "$W/home" "$W/state"
git clone -q "$W/m/origin.git" "$W/clone"; git -C "$W/clone" reset -q --hard v1.0.0
env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_QUIET=1 HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" bash "$W/clone/scripts/helix-auto-update.sh" >/dev/null 2>&1
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "R14: the old updater (last old-style session) moves the clone to the release carrying this change" || fail "R14: clone at $(cat "$W/clone/VERSION")"
git -C "$W/m/seed" commit -q --allow-empty -m v1.0.2 && git -C "$W/m/seed" tag v1.0.2 && git -C "$W/m/seed" push -q origin main v1.0.2
n0="$(sentinels)"; h0="$(git -C "$W/clone" rev-parse HEAD)"
out="$(env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" bash "$W/clone/hooks/session-start" 2>/dev/null)"
[ "$(git -C "$W/clone" rev-parse HEAD)" = "$h0" ] && [ "$(sentinels)" = "$n0" ] && ok "R14: next session does not move the clone or run scripts" || fail "R14: new hook changed state"
ctx <<<"$out" | grep -q "Helix v1.0.2 is available (installed v1.0.1)" && ok "R14: next session prints the notice naming 1.0.2" || fail "R14: no notice for 1.0.2"

# --- T13: docs say notify-only -----------------------------------------------------------------------
bad=0
PAT='updates the next session|auto-update hooks|Disable auto-update|Force check now|Turn off auto-update|HELIX_FORCE_UPDATE=1'
for f in README.md docs/wiki/Home.md docs/DOC-MAP.md scripts/install.sh scripts/helix-doctor.sh; do
  if grep -nE "$PAT" "$REPO_ROOT/$f" >/dev/null; then
    fail "R13: $f still describes auto-update ($(grep -nE "$PAT" "$REPO_ROOT/$f" | head -1 | cut -c1-80))"; bad=1
  fi
done
[ "$bad" = 0 ] && ok "R13: no auto-update wording left in README / wiki / DOC-MAP / install.sh / doctor"
for f in README.md docs/wiki/Home.md; do
  grep -qF "$UPD" "$REPO_ROOT/$f" && ok "R13: $f names the update command" || fail "R13: $f lacks the update command"
done
grep -qF "$UPD" "$REPO_ROOT/scripts/install.sh" && ok "R13: install.sh hint names the update command" || fail "R13: install.sh hint"
finish
