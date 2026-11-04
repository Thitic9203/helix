#!/usr/bin/env bash
# install.sh / setup.sh delete only Helix's own plugin-cache links (Spec: docs/sdd/link-skills-no-delete R11, R12).
. "$(dirname "$0")/lib.sh"
R="$(copy_repo)"; T="$(mktemp -d)"; trap 'rm -rf "$R" "$T"' EXIT
VER="$(tr -d '[:space:]' < "$R/VERSION")"
snap() { (cd "$1" && find . -type f -exec cksum {} +) | sort; }
clone_before="$(snap "$R/skills")"

# Fake cache: an old Helix version link (to the clone, with and without a trailing slash),
# a real folder the claude CLI could have written, and a symlink somewhere else.
H="$T/h1"; C="$H/.claude/plugins/cache/helix-dev/helix"
mkdir -p "$C/copy-1" "$H/elsewhere"; echo cli >"$C/copy-1/plugin.json"
ln -s "$R" "$C/0.0.1"; ln -s "$R/" "$C/0.0.2"; ln -s "$H/elsewhere" "$C/other"
(cd "$R" && git init -q . && git add -A >/dev/null 2>&1 && git -c user.email=t@t -c user.name=t commit -qm t)
(cd "$R" && HOME="$H" bash "$R/scripts/setup.sh") >"$T/out1" 2>"$T/err1"; rc=$?
[ "$rc" = 0 ] && ok "setup.sh exits 0 with foreign cache entries" || fail "setup.sh exit $rc: $(tail -3 "$T/err1")"
[ ! -e "$C/0.0.1" ] && [ ! -L "$C/0.0.1" ] && [ ! -L "$C/0.0.2" ] && ok "old Helix version links removed" || fail "old Helix version links left"
[ "$(cat "$C/copy-1/plugin.json" 2>/dev/null)" = cli ] && [ ! -L "$C/copy-1" ] && ok "real cache folder kept byte-identical" || fail "real cache folder deleted or changed"
[ "$(readlink "$C/other")" = "$H/elsewhere" ] && [ -d "$H/elsewhere" ] && ok "foreign cache symlink kept" || fail "foreign cache symlink removed"
[ "$(grep -c '^keep (plugin cache)' "$T/err1" | tr -d ' ')" = 2 ] && ok "stderr names the 2 kept entries" || fail "kept-entry warnings: $(cat "$T/err1")"
[ "$(cd "$(readlink "$C/$VER")" && pwd -P)" = "$(cd "$R" && pwd -P)" ] && ok "current version linked to the clone" || fail "version link: $(readlink "$C/$VER" 2>&1)"
[ "$(snap "$R/skills")" = "$clone_before" ] && ok "clone files untouched" || fail "clone files changed"

# R12: a real folder at <VERSION> is not written into or over; the step still exits 0.
H="$T/h2"; C="$H/.claude/plugins/cache/helix-dev/helix"; mkdir -p "$C/$VER"; echo cli >"$C/$VER/plugin.json"
before="$(snap "$C/$VER")"
(cd "$R" && HOME="$H" bash "$R/scripts/setup.sh") >"$T/out2" 2>"$T/err2"; rc=$?
[ "$rc" = 0 ] && [ "$(snap "$C/$VER")" = "$before" ] && [ ! -L "$C/$VER" ] && ok "real folder at <VERSION> left as is, exit 0" || fail "real <VERSION> folder changed (rc $rc): $(ls -la "$C/$VER")"
grep -q "skip (plugin cache) $C/$VER" "$T/err2" && ok "occupied <VERSION> warned" || fail "occupied <VERSION> not warned: $(cat "$T/err2")"

# install.sh uses the same helper; no recursive delete of the cache is left in either script.
grep -q 'helix_link_plugin_cache "\$CACHE_BASE" "\$VERSION" "\$REPO_DIR"' "$R/scripts/install.sh" && ok "install.sh uses helix_link_plugin_cache" || fail "install.sh does not use helix_link_plugin_cache"
grep -nE 'rm -[a-zA-Z]*r' "$R/scripts/install.sh" "$R/scripts/setup.sh" >/dev/null && fail "install.sh/setup.sh still have a recursive rm" || ok "no recursive rm in install.sh or setup.sh"
finish
