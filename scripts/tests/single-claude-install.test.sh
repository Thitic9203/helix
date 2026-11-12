#!/usr/bin/env bash
# Claude Code gets Helix only from the plugin; old ~/.claude/skills Helix links are removed,
# nothing else is (Spec: docs/sdd/single-claude-install R1-R5, R7).
. "$(dirname "$0")/lib.sh"
. "$REPO_ROOT/scripts/lib/skill-list.sh"
R="$(copy_repo)"; H="$(mktemp -d)"; B="$(mktemp -d)"; trap 'rm -rf "$R" "$H" "$B"' EXIT
mkdir -p "$H/.claude/skills" "$H/.cursor/skills" "$R/.git"
N="$(helix_linked_skills "$R" | wc -l | tr -d ' ')"
S="$(helix_linked_skills "$R" | head -1)"
count_links() { find "$1" -maxdepth 1 -type l | wc -l | tr -d ' '; }

# claude stub: `plugin list` shows helix@helix-dev only while $B/plugin exists
printf '%s\n' '#!/bin/sh' '[ "$1 $2" = "plugin list" ] && [ -f "$STUB_DIR/plugin" ] && echo "helix@helix-dev"; exit 0' >"$B/claude"; chmod +x "$B/claude"
export STUB_DIR="$B"; PATH="$B:$PATH"

# R1, R2: fresh run links Cursor but not Claude
HOME="$H" bash "$R/scripts/link-skills.sh" >"$H/out" 2>&1
c="$(count_links "$H/.claude/skills")"
[ "$c" = 0 ] && ok "R1 no Helix links in ~/.claude/skills (plugin only)" || fail "R1 ~/.claude/skills has $c links — skills listed twice in Claude Code"
[ "$(count_links "$H/.cursor/skills")" = "$N" ] && ok "R2 ~/.cursor/skills still gets all $N links" || fail "R2 cursor links changed"
grep -q "removed .* old Helix" "$H/out" && fail "R5 notice printed with nothing to remove" || ok "R5 no notice when nothing removed"

# R9: plugin not confirmed -> nothing removed, one 'kept' line
for s_ in $(helix_linked_skills "$R"); do ln -sfn "$R/skills/$s_" "$H/.claude/skills/$s_"; done
out="$(HOME="$H" bash "$R/scripts/link-skills.sh" 2>&1)"
[ "$(count_links "$H/.claude/skills")" = "$N" ] && ok "R9 plugin missing: all $N links kept" || fail "R9 removed links without the plugin: $(count_links "$H/.claude/skills") left of $N"
[ "$(echo "$out" | grep -c "kept $N old Helix")" = 1 ] && ok "R9 one kept line" || fail "R9 kept line wrong: $(echo "$out" | grep 'old Helix')"
touch "$B/plugin"

# R3, R4, R5: an existing user with old links plus their own entries
for s in $(helix_linked_skills "$R"); do ln -sfn "$R/skills/$s" "$H/.claude/skills/$s"; done
rm "$H/.claude/skills/$S"; ln -s "$R/skills/gone/$S" "$H/.claude/skills/$S"   # broken Helix link
mkdir -p "$H/.claude/skills/mine" "$H/elsewhere" "$H/old/skills/x"; echo me >"$H/.claude/skills/mine/SKILL.md"
ln -s "$H/elsewhere" "$H/.claude/skills/foreign"; ln -s "$H/old/skills/x" "$H/.claude/skills/x"
out="$(HOME="$H" bash "$R/scripts/link-skills.sh" 2>&1)"
[ "$(count_links "$H/.claude/skills")" = 2 ] && ok "R3 all $N old Helix links removed (broken one too)" || fail "R3 left $(count_links "$H/.claude/skills") links: $(ls "$H/.claude/skills")"
[ "$(cat "$H/.claude/skills/mine/SKILL.md")" = me ] && [ "$(readlink "$H/.claude/skills/foreign")" = "$H/elsewhere" ] && [ "$(readlink "$H/.claude/skills/x")" = "$H/old/skills/x" ] \
  && ok "R4 user folder, foreign link and old-clone link kept" || fail "R4 user entries changed"
[ "$(echo "$out" | grep -c "old Helix")" = 1 ] && echo "$out" | grep -q "removed $N old Helix" && ok "R5 one notice line with the count" || fail "R5 notice wrong: $(echo "$out" | grep 'old Helix')"

# R7: doctor no longer expects Claude links, warns on leftovers
doctor() { HOME="$H" HELIX_REPO_DIR="$R" HELIX_STATE_DIR="$H/state" PATH="$B:/usr/bin:/bin" bash "$R/scripts/helix-doctor.sh" 2>&1; }
out="$(doctor)"
echo "$out" | grep -q "Claude Code: .*skills linked\|Claude Code: .*missing" && fail "R7 doctor still expects ~/.claude/skills links" || ok "R7 doctor does not expect ~/.claude/skills links"
echo "$out" | grep -q "WARN.*Claude Code.*old Helix" && fail "R7 leftover WARN with nothing left" || ok "R7 no leftover WARN when clean"
ln -s "$R/skills/$S" "$H/.claude/skills/$S"
doctor | grep "WARN" | grep "old Helix" | grep -q "link-skills.sh" && ok "R7 leftover Helix link warned with the fix" || fail "R7 leftover not warned"
finish
