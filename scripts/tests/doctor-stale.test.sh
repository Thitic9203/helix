#!/usr/bin/env bash
# helix-doctor.sh warns when the auto-update stamp is missing or older than 24h.
. "$(dirname "$0")/lib.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/repo/.git" "$W/home" "$W/state" "$W/bin"
echo 1.0.0 > "$W/repo/VERSION"
doctor() { # PATH without a claude CLI keeps the run offline and fast
  HOME="$W/home" HELIX_REPO_DIR="$W/repo" HELIX_STATE_DIR="$W/state" PATH="$W/bin:/usr/bin:/bin" \
    bash "$REPO_ROOT/scripts/helix-doctor.sh" 2>&1
}
out="$(doctor)"
echo "$out" | grep -q "WARN No auto-update stamp" && ok "missing stamp warns" || fail "missing stamp did not warn"

echo $(( $(date +%s) - 2 * 86400 )) > "$W/state/.last-auto-update-check"
out="$(doctor)"
echo "$out" | grep -q "WARN Last auto-update check was 48h ago" && ok "48h-old stamp warns" || fail "48h-old stamp did not warn"

date +%s > "$W/state/.last-auto-update-check"
out="$(doctor)"
echo "$out" | grep -q "OK   Last auto-update check 0h ago" && ok "fresh stamp is OK" || fail "fresh stamp not OK"
echo "$out" | grep -q "WARN Last auto-update" && fail "fresh stamp warned" || ok "fresh stamp does not warn"
finish
