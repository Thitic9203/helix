#!/usr/bin/env bash
# helix-auto-update.sh (the update command, no args) follows release tags only, never moves backwards,
# and reports failures that hooks/session-start then surfaces. A session start only checks (--check).
# Offline: origin is a local bare repo.
. "$(dirname "$0")/lib.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
AU="$REPO_ROOT/scripts/helix-auto-update.sh"
git init -q --bare -b main "$W/origin.git"
git init -q -b main "$W/seed"; cd "$W/seed"
git config user.name t; git config user.email t@example.invalid
for v in 1.0.0 1.0.1 1.0.2; do
  echo "$v" > VERSION; git add VERSION; git commit -qm "v$v"
  [ "$v" = 1.0.2 ] || git tag "v$v"          # 1.0.2 = on main, never released
done
git remote add origin "$W/origin.git"; git push -q origin main --tags
# R10 (docs/sdd/token-budget-guard): every published release carries a pass token-report.json asset
run_au() { pass_reports "$W/origin.git" "$W/assets"; HOME="$W/home" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_RELEASE_ASSETS="$W/assets" bash "$AU" >/dev/null 2>&1; }
fresh_clone() { rm -rf "$W/clone"; git clone -q "$W/origin.git" "$W/clone"; git -C "$W/clone" reset -q --hard "$1"; }
mkdir -p "$W/home"

fresh_clone v1.0.0; run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "updates to the newest release (1.0.1), not unreleased main (1.0.2)" || fail "clean clone ended at $(cat "$W/clone/VERSION")"
[ ! -e "$W/state/last-update-error" ] && ok "a clean update leaves no error notice" || fail "error notice written on a clean update"

run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "already at the release: nothing moves" || fail "re-run moved to $(cat "$W/clone/VERSION")"

fresh_clone v1.0.0
git -C "$W/clone" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m "local work"
run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.0 ] && ok "a diverged clone is not moved" || fail "diverged clone moved to $(cat "$W/clone/VERSION")"
grep -q "fast-forward to v1.0.1 failed" "$W/state/last-update-error" 2>/dev/null && ok "the failed fast-forward is recorded for session-start" || fail "no error notice for the failed fast-forward"

out="$(HOME="$W/home" HELIX_AUTO_UPDATE=0 bash "$REPO_ROOT/hooks/session-start" 2>/dev/null)"
mkdir -p "$W/home/.helix"; cp "$W/state/last-update-error" "$W/home/.helix/last-update-error"
out2="$(HOME="$W/home" HELIX_AUTO_UPDATE=0 bash "$REPO_ROOT/hooks/session-start" 2>/dev/null)"
! printf '%s' "$out" | grep -q "update problem" && printf '%s' "$out2" | grep -q "update problem" \
  && ok "session-start shows the notice only when an error is recorded" || fail "session-start notice wrong (without: $(printf '%s' "$out" | grep -c 'update problem'), with: $(printf '%s' "$out2" | grep -c 'update problem'))"
printf '%s' "$out2" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null && ok "session-start output with the notice is valid JSON" || fail "session-start output is not valid JSON"

fresh_clone v1.0.0; run_au
[ ! -e "$W/state/last-update-error" ] && ok "the next clean run clears the notice" || fail "notice survived a clean run"

fresh_clone v1.0.0
HOME="$W/home" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_RELEASE_ASSETS="$W/assets" HELIX_FORCE_UPDATE=1 HELIX_AUTO_UPDATE_INTERVAL_SEC=0 bash "$AU" >/dev/null 2>&1
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "a clone install updates (FORCE_UPDATE / INTERVAL_SEC are accepted and ignored)" || fail "update with legacy env left the clone at $(cat "$W/clone/VERSION")"

fresh_clone v1.0.0
git -C "$W/clone" tag -f v1.0.1 v1.0.0 >/dev/null   # a stale local tag that disagrees with origin
run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "a stale local release tag does not block the update (origin tags win)" || fail "stale local tag left the clone at $(cat "$W/clone/VERSION")"

fresh_clone main; run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.2 ] && ok "a clone ahead of the release is never moved back" || fail "clone moved back to $(cat "$W/clone/VERSION")"

# Every session (R2 update-notify-only): a --check run probes the tag list and prints a notice; it never
# fetches or moves. Only the update command moves the clone.
run_session() { HOME="$W/home" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" bash "$AU" --check 2>/dev/null; }
fresh_clone v1.0.0; run_au                      # at release 1.0.1
fetches() { grep -c "fetching origin" "$W/state/auto-update.log" 2>/dev/null || true; }
before="$(fetches)"; msg="$(run_session)"
[ "$(fetches)" = "$before" ] && [ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && [ -z "$msg" ] \
  && ok "a session with no new release prints nothing and fetches nothing" || fail "no-new-release session fetched, moved or printed (VERSION $(cat "$W/clone/VERSION"), msg '$msg')"
git -C "$W/seed" tag v1.0.2 && git -C "$W/seed" push -q origin v1.0.2
msg="$(run_session)"
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && [ "$(fetches)" = "$before" ] && printf '%s' "$msg" | grep -q "v1.0.2 is available" \
  && ok "a release published after the last check is announced, not installed" || fail "session moved or stayed silent (VERSION $(cat "$W/clone/VERSION"), msg '$msg')"
run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.2 ] && ok "the update command then installs it" || fail "update command left $(cat "$W/clone/VERSION")"

# R10 (docs/sdd/retire-devenv): the updater never runs helix-setup-devenv.sh, even on an opted-in machine.
mkdir -p "$W/seed/scripts"
printf '#!/bin/sh\ntouch "%s/sentinel"\n' "$W" > "$W/seed/scripts/helix-setup-devenv.sh"; chmod +x "$W/seed/scripts/helix-setup-devenv.sh"
echo 1.0.3 > "$W/seed/VERSION"; git -C "$W/seed" add VERSION scripts/helix-setup-devenv.sh; git -C "$W/seed" commit -qm "v1.0.3"
git -C "$W/seed" tag v1.0.3 && git -C "$W/seed" push -q origin main v1.0.3
fresh_clone v1.0.2; mkdir -p "$W/state"; echo 1 > "$W/state/.devenv-opted-in"
run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.3 ] && [ ! -e "$W/sentinel" ] && ok "an update on an opted-in machine does not run helix-setup-devenv.sh" || fail "R10: VERSION $(cat "$W/clone/VERSION"), sentinel $([ -e "$W/sentinel" ] && echo present || echo absent)"
! grep -q devenv "$AU" && ok "helix-auto-update.sh has no devenv reference" || fail "R10: devenv still referenced in helix-auto-update.sh"
finish
