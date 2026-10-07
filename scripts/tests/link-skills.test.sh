#!/usr/bin/env bash
# link-skills.sh links every shipped skill, never procedures/ or in-progress/
. "$(dirname "$0")/lib.sh"
R="$(copy_repo)"; H="$(mktemp -d)"; trap 'rm -rf "$R" "$H"' EXIT
mkdir -p "$H/.claude"
HOME="$H" HELIX_QUIET=1 bash "$R/scripts/link-skills.sh" >/dev/null 2>&1
want="$(python3 -c "import json;print(len(json.load(open('$R/.claude-plugin/plugin.json'))['skills']))")"
got="$(find "$H/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ')"
[ "$got" = "$want" ] && ok "links all $want plugin.json skills into ~/.claude/skills" || fail "linked $got, want $want"
[ ! -e "$H/.claude/skills/procedures" ] && [ ! -e "$H/.claude/skills/in-progress" ] && ok "procedures/ and in-progress/ are not linked" || fail "procedures/ or in-progress/ got linked"
bad=0; for l in "$H/.claude/skills"/*; do [ -f "$l/SKILL.md" ] || bad=1; done
[ "$bad" = 0 ] && ok "every link resolves to a SKILL.md" || fail "a link does not resolve to a SKILL.md"
finish
