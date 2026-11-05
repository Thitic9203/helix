#!/usr/bin/env bash
# bump-version.sh and sync-version.sh
. "$(dirname "$0")/lib.sh"
R="$(copy_repo)"; trap 'rm -rf "$R"' EXIT
cd "$R"
echo 1.2.3 > VERSION && bash scripts/sync-version.sh >/dev/null
expect_exit 0 "sync-version writes every marker so --check passes" -- bash scripts/sync-version.sh --check
grep -q '"version": "1.2.3"' .claude-plugin/plugin.json && ok "plugin.json carries 1.2.3" || fail "plugin.json carries 1.2.3"
# README install block names the release tag (Spec: docs/sdd/install-pinned-checksum R3, Q3 = B)
grep -q '^HELIX_TAG=v1.2.3$' README.md && ok "sync-version writes the tag into README's install block" || fail "README install block tag after sync: $(grep -m1 '^HELIX_TAG=' README.md)"
sed -i.bak 's/^HELIX_TAG=v.*/HELIX_TAG=v0.0.1/' README.md && rm -f README.md.bak
expect_exit 1 "--check fails when README's install tag differs from VERSION" -- bash scripts/sync-version.sh --check
bash scripts/sync-version.sh >/dev/null
expect_exit 0 "sync-version repairs the README install tag" -- bash scripts/sync-version.sh --check
cp README.md README.keep; grep -v '^HELIX_TAG=' README.keep > README.md
expect_exit 1 "--check fails when README has no install tag line" -- bash scripts/sync-version.sh --check
bash scripts/sync-version.sh >/dev/null 2>&1
expect_exit 1 "sync-version does not invent a missing install block" -- bash scripts/sync-version.sh --check
mv README.keep README.md; bash scripts/sync-version.sh >/dev/null
bash scripts/bump-version.sh patch >/dev/null; [ "$(cat VERSION)" = 1.2.4 ] && ok "patch 1.2.3 -> 1.2.4" || fail "patch -> $(cat VERSION)"
bash scripts/bump-version.sh minor >/dev/null; [ "$(cat VERSION)" = 1.3.0 ] && ok "minor 1.2.4 -> 1.3.0" || fail "minor -> $(cat VERSION)"
bash scripts/bump-version.sh major >/dev/null; [ "$(cat VERSION)" = 2.0.0 ] && ok "major 1.3.0 -> 2.0.0" || fail "major -> $(cat VERSION)"
expect_exit 0 "markers still in sync after bumps" -- bash scripts/sync-version.sh --check
sed -i.bak 's/"version": "2.0.0"/"version": "9.9.9"/' .claude-plugin/plugin.json && rm -f .claude-plugin/plugin.json.bak
expect_exit 1 "--check fails when plugin.json drifts from VERSION" -- bash scripts/sync-version.sh --check
echo "not-semver" > VERSION
expect_exit 1 "a non-semver VERSION is refused" -- bash scripts/sync-version.sh --check
finish
