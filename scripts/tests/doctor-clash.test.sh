#!/usr/bin/env bash
# helix-doctor.sh warns about skill-name clashes (Spec: docs/sdd/link-skills-no-delete R13).
. "$(dirname "$0")/lib.sh"
. "$REPO_ROOT/scripts/lib/skill-list.sh"
R="$(copy_repo)"; W="$(mktemp -d)"; trap 'rm -rf "$R" "$W"' EXIT
mkdir -p "$R/.git" "$W/home/.cursor" "$W/state" "$W/bin"
S="$(helix_linked_skills "$R" | head -1)"
HOME="$W/home" bash "$R/scripts/link-skills.sh" >/dev/null 2>&1
doctor() { # PATH without a claude CLI keeps the run offline and fast
  HOME="$W/home" HELIX_REPO_DIR="$R" HELIX_STATE_DIR="$W/state" PATH="$W/bin:/usr/bin:/bin" "$@" \
    bash "$R/scripts/helix-doctor.sh" 2>&1
}
out="$(doctor)"
echo "$out" | grep -q "OK   Cursor: all .* skills linked" && ok "clean links report all linked" || fail "clean links not OK: $(echo "$out" | grep 'Cursor')"
echo "$out" | grep -q "clash" && fail "clean links reported a clash" || ok "clean links report no clash"

# A user's own folder with a Helix skill's name, and a user symlink elsewhere
rm "$W/home/.cursor/skills/$S"; mkdir "$W/home/.cursor/skills/$S"
mkdir -p "$W/home/.codex/skills" "$W/elsewhere"; ln -s "$W/elsewhere" "$W/home/.codex/skills/$S"
out="$(doctor)"
echo "$out" | grep "WARN" | grep "clash" | grep -F "$S" | grep -qF "$W/home/.cursor/skills/$S" && ok "user folder $S warned as a clash with its path" || fail "no clash WARN for user folder: $(echo "$out" | grep -E 'Cursor|clash')"
echo "$out" | grep "WARN" | grep "clash" | grep -qF "$W/home/.codex/skills/$S" && ok "user symlink elsewhere warned as a clash" || fail "no clash WARN for foreign symlink"
echo "$out" | grep -q "OK   Cursor: all" && fail "clash still counted as linked" || ok "clash not counted as linked"
echo "$out" | grep "clash" | grep -q "link-skills.sh" && ok "clash WARN names the fix" || fail "clash WARN has no fix"

# Workspace folders are checked too
WS="$W/ws"; mkdir -p "$WS/.agents/skills/$S"
out="$(doctor env HELIX_LINK_WORKSPACE="$WS")"
echo "$out" | grep "WARN" | grep "clash" | grep -qF "$WS/.agents/skills/$S" && ok "workspace clash warned" || fail "workspace clash not warned"
finish
