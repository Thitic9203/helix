#!/usr/bin/env bash
# helix-auto-update.sh follows release tags only, never moves backwards, and reports failures
# that hooks/session-start then surfaces. Offline: origin is a local bare repo.
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
echo 1.0.2 > "$W/remote-version"
run_au() { HOME="$W/home" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_FORCE_UPDATE=1 \
  HELIX_VERSION_URL="file://$W/remote-version" bash "$AU" >/dev/null 2>&1; }
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
! printf '%s' "$out" | grep -q "auto-update problem" && printf '%s' "$out2" | grep -q "auto-update problem" \
  && ok "session-start shows the notice only when an error is recorded" || fail "session-start notice wrong (without: $(printf '%s' "$out" | grep -c 'auto-update problem'), with: $(printf '%s' "$out2" | grep -c 'auto-update problem'))"
printf '%s' "$out2" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null && ok "session-start output with the notice is valid JSON" || fail "session-start output is not valid JSON"

fresh_clone v1.0.0; run_au
[ ! -e "$W/state/last-update-error" ] && ok "the next clean run clears the notice" || fail "notice survived a clean run"

fresh_clone v1.0.0
HOME="$W/home" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_FORCE_UPDATE=1 \
  HELIX_VERSION_URL="https://127.0.0.1:9/unreachable" bash "$AU" >/dev/null 2>&1
[ "$(cat "$W/clone/VERSION")" = 1.0.1 ] && ok "a clone install updates even when the VERSION URL is unreachable (curl/TLS failure)" || fail "unreachable VERSION URL left the clone at $(cat "$W/clone/VERSION")"

fresh_clone main; run_au
[ "$(cat "$W/clone/VERSION")" = 1.0.2 ] && ok "a clone ahead of the release is never moved back" || fail "clone moved back to $(cat "$W/clone/VERSION")"
finish
