#!/usr/bin/env bash
# R10 (docs/sdd/token-budget-guard): the update command moves an install only to a release whose
# token-report.json asset exists, names that tag and commit, and has verdict "pass". Otherwise it stays on
# the current version and prints one line saying why. Fail closed: an unreadable report means no update.
# The read-only --check path is unchanged (no report fetch). Offline: origin is a bare repo on disk.
. "$(dirname "$0")/lib.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
AU="$REPO_ROOT/scripts/helix-auto-update.sh"
mkdir -p "$W/bin" "$W/home"
git init -q --bare -b main "$W/origin.git"; git init -q -b main "$W/seed"; cd "$W/seed"
git config user.name t; git config user.email t@example.invalid
for v in 1.0.0 1.0.1; do echo "$v" > VERSION; git add VERSION; git commit -qm "v$v"; git tag "v$v"; done
git remote add origin "$W/origin.git"; git push -q origin main --tags; cd "$REPO_ROOT"
C1="$(git -C "$W/origin.git" rev-parse v1.0.1^{commit})"; C0="$(git -C "$W/origin.git" rev-parse v1.0.0^{commit})"
fresh() { rm -rf "$W/clone" "$W/state" "$W/assets" "$W"/sentinel-*; git clone -q "$W/origin.git" "$W/clone"; git -C "$W/clone" reset -q --hard v1.0.0; }
upd() { env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_RELEASE_ASSETS="${ASSETS:-$W/assets}" "$@" bash "$AU" 2>/dev/null; }
ver() { cat "$W/clone/VERSION"; }
lines() { printf '%s' "$1" | grep -c . ; }

fresh; make_report "$W/assets" v1.0.1 "$C1" pass; out="$(upd)"
[ "$(ver)" = 1.0.1 ] && ok "R10: a release with a pass report for its commit is installed" || fail "R10: pass report left $(ver): $out"

fresh; make_report "$W/assets" v1.0.1 "$C1" fail; out="$(upd)"
[ "$(ver)" = 1.0.0 ] && [ "$(lines "$out")" = 1 ] && grep -q "v1.0.1" <<<"$out" && grep -qi "verdict" <<<"$out" \
  && ok "R10: verdict fail — install stays on v1.0.0 with one line of reason" || fail "R10: verdict fail: VERSION $(ver), out '$out'"
grep -q "staying on v1.0.0" <<<"$out" && ok "R10: the line names the version the install stays on" || fail "R10: line: $out"

fresh; out="$(upd)"
[ "$(ver)" = 1.0.0 ] && [ "$(lines "$out")" = 1 ] && grep -qi "missing" <<<"$out" && ok "R10: a release without token-report.json is refused" || fail "R10: missing asset: VERSION $(ver), out '$out'"

fresh; make_report "$W/assets" v1.0.1 "$C0" pass; out="$(upd)"
[ "$(ver)" = 1.0.0 ] && grep -qi "commit" <<<"$out" && ok "R10: a pass report for a different commit is refused" || fail "R10: wrong commit: VERSION $(ver), out '$out'"

fresh; make_report "$W/assets" v1.0.1 "$C1" pass; sed -i.bak 's/"release_tag": "v1.0.1"/"release_tag": "v1.0.0"/' "$W/assets/v1.0.1/token-report.json"; out="$(upd)"
[ "$(ver)" = 1.0.0 ] && ok "R10: a report naming another tag is refused" || fail "R10: wrong tag installed"

fresh; mkdir -p "$W/assets/v1.0.1"; echo '<html>404</html>' > "$W/assets/v1.0.1/token-report.json"; out="$(upd)"
[ "$(ver)" = 1.0.0 ] && ok "R10: an unreadable report is refused" || fail "R10: garbage report installed"

# https path: curl is used; a fetch failure fails closed, a served pass report installs
printf '#!/bin/sh\necho x >> "%s/sentinel-curl"\nexit 6\n' "$W" > "$W/bin/curl"; chmod +x "$W/bin/curl"
fresh; out="$(ASSETS=https://example.invalid/dl upd)"
[ "$(ver)" = 1.0.0 ] && [ "$(lines "$out")" = 1 ] && grep -qi "could not be fetched" <<<"$out" && [ -e "$W/sentinel-curl" ] \
  && ok "R10: report fetch fails (offline) — no update, one line" || fail "R10: offline fetch: VERSION $(ver), out '$out'"
cat > "$W/bin/curl" <<SH
#!/bin/sh
echo x >> "$W/sentinel-curl"; o=""; u=""
while [ \$# -gt 0 ]; do case "\$1" in -o) o="\$2"; shift 2;; -*) shift;; *) u="\$1"; shift;; esac; done
f="$W/served/\${u#https://example.invalid/dl/}"; [ -f "\$f" ] || exit 22; cp "\$f" "\$o"
SH
fresh; make_report "$W/served" v1.0.1 "$C1" pass; out="$(ASSETS=https://example.invalid/dl upd)"
[ "$(ver)" = 1.0.1 ] && ok "R10: a pass report served over https installs the release" || fail "R10: https pass: VERSION $(ver), out '$out'"
fresh; rm -rf "$W/served"; out="$(ASSETS=https://example.invalid/dl upd)"
[ "$(ver)" = 1.0.0 ] && grep -qi "missing" <<<"$out" && ok "R10: an https 404 (asset missing) is refused" || fail "R10: https 404: VERSION $(ver), out '$out'"

# --check stays read-only and offline-tolerant: no report fetch, notice unchanged
fresh; make_report "$W/assets" v1.0.1 "$C1" fail
msg="$(env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_RELEASE_ASSETS=https://example.invalid/dl bash "$AU" --check 2>/dev/null)"
grep -q "v1.0.1 is available" <<<"$msg" && [ ! -e "$W/sentinel-curl" ] && [ "$(ver)" = 1.0.0 ] \
  && ok "R10: --check still only notifies and fetches no report" || fail "R10: --check changed (msg '$msg', curl $([ -e "$W/sentinel-curl" ] && echo called || echo not-called))"
grep -q 'https://github.com/Thitic9203/helix/releases/download' "$AU" && ok "R10: the default report source is the GitHub release asset" || fail "R10: no default release-asset URL"

# no clone (plugin-only install): the plugin sync runs only for a pass report
rm -rf "$W/clone" "$W/copy" "$W"/sentinel-*; mkdir -p "$W/copy/scripts"; cp "$AU" "$W/copy/scripts/"; echo 1.0.0 > "$W/copy/VERSION"
printf '#!/bin/sh\necho x >> "%s/sentinel-claude"\n' "$W" > "$W/bin/claude"; chmod +x "$W/bin/claude"
nc() { env HOME="$W/home" PATH="$W/bin:$PATH" HELIX_REPO_DIR="$W/clone" HELIX_STATE_DIR="$W/state" HELIX_REMOTE_URL="$W/origin.git" HELIX_RELEASE_ASSETS="$W/assets" bash "$W/copy/scripts/helix-auto-update.sh" 2>/dev/null; }
rm -rf "$W/assets"; make_report "$W/assets" v1.0.1 "$C1" fail; out="$(nc)"
[ ! -e "$W/sentinel-claude" ] && [ "$(lines "$out")" = 1 ] && ok "R10: no-clone install — failing report: no plugin sync, one line" || fail "R10: no-clone fail: claude $([ -e "$W/sentinel-claude" ] && echo ran), out '$out'"
rm -rf "$W/assets"; make_report "$W/assets" v1.0.1 "$C1" pass; out="$(nc)"
[ -e "$W/sentinel-claude" ] && ok "R10: no-clone install — pass report: plugin sync runs" || fail "R10: no-clone pass did not sync"
finish
