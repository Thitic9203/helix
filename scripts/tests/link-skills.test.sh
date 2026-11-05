#!/usr/bin/env bash
# link-skills.sh links every shipped skill, never procedures/ or in-progress/
# and never deletes or replaces an entry Helix did not create (Spec: docs/sdd/link-skills-no-delete).
. "$(dirname "$0")/lib.sh"
. "$REPO_ROOT/scripts/lib/skill-list.sh"
R="$(copy_repo)"; H="$(mktemp -d)"; T="$(mktemp -d)"; trap 'rm -rf "$R" "$H" "$T"' EXIT
mkdir -p "$H/.claude"
HOME="$H" HELIX_QUIET=1 bash "$R/scripts/link-skills.sh" >/dev/null 2>&1
want="$(python3 -c "import json;print(len(json.load(open('$R/.claude-plugin/plugin.json'))['skills']))")"
got="$(find "$H/.claude/skills" -maxdepth 1 -type l | wc -l | tr -d ' ')"
[ "$got" = "$want" ] && ok "links all $want plugin.json skills into ~/.claude/skills" || fail "linked $got, want $want"
[ ! -e "$H/.claude/skills/procedures" ] && [ ! -e "$H/.claude/skills/in-progress" ] && ok "procedures/ and in-progress/ are not linked" || fail "procedures/ or in-progress/ got linked"
bad=0; for l in "$H/.claude/skills"/*; do [ -f "$l/SKILL.md" ] || bad=1; done
[ "$bad" = 0 ] && ok "every link resolves to a SKILL.md" || fail "a link does not resolve to a SKILL.md"

S="$(helix_linked_skills "$R" | head -1)"
N="$(helix_linked_skills "$R" | wc -l | tr -d ' ')"
snap() { (cd "$1" && find . -exec ls -ld {} + | awk '{print $1, $NF}' ; find . -type f -exec cksum {} +) | sort; }
newhome() { local h; h="$(mktemp -d "$T/h.XXXX")"; mkdir -p "$h/.claude/skills"; echo "$h"; }
run() { # run <home> [extra env...] — writes $1/out $1/err $1/rc
  local h="$1"; shift
  env HOME="$h" "$@" bash "$R/scripts/link-skills.sh" >"$h/out" 2>"$h/err"; echo $? >"$h/rc"
}
clash_lines() { grep -c "skip (" "$1/err" | tr -d ' '; }
links_to_clone() { local d="$1" c=0 e; for e in "$d"/*; do [ -L "$e" ] && [ -f "$e/SKILL.md" ] && c=$((c + 1)); done; echo "$c"; }

# T1 (R1, R2, R6): a user's same-named folder survives untouched and is warned about once
h="$(newhome)"; mkdir "$h/.claude/skills/$S"; echo mine >"$h/.claude/skills/$S/SKILL.md"
before="$(snap "$h/.claude/skills/$S")"; run "$h"
[ "$(snap "$h/.claude/skills/$S")" = "$before" ] && [ ! -L "$h/.claude/skills/$S" ] && ok "T1 user folder $S is byte-identical and not replaced" || fail "T1 user folder $S was changed or replaced"
[ "$(clash_lines "$h")" = 1 ] && grep "skip (" "$h/err" | grep -F "$S" | grep -F "$h/.claude/skills/$S" | grep -q "link-skills.sh" && ok "T1 one stderr line names $S, its path and the re-run command" || fail "T1 warning missing or wrong: $(cat "$h/err")"

# T2 (R1): a plain file with the skill's name survives
h="$(newhome)"; echo myfile >"$h/.claude/skills/$S"; run "$h"
[ -f "$h/.claude/skills/$S" ] && [ ! -L "$h/.claude/skills/$S" ] && [ "$(cat "$h/.claude/skills/$S")" = myfile ] && [ "$(clash_lines "$h")" = 1 ] && ok "T2 user file $S intact and warned" || fail "T2 user file $S changed or not warned"

# T3 (R3): a user symlink elsewhere and a broken user symlink keep their target text
h="$(newhome)"; mkdir -p "$h/elsewhere"; ln -s "$h/elsewhere" "$h/.claude/skills/$S"; run "$h"
[ "$(readlink "$h/.claude/skills/$S")" = "$h/elsewhere" ] && [ "$(clash_lines "$h")" = 1 ] && ok "T3 foreign working symlink kept and warned" || fail "T3 foreign symlink replaced: $(readlink "$h/.claude/skills/$S")"
h="$(newhome)"; ln -s "$h/gone" "$h/.claude/skills/$S"; run "$h"
[ "$(readlink "$h/.claude/skills/$S")" = "$h/gone" ] && [ "$(clash_lines "$h")" = 1 ] && ok "T3 foreign broken symlink kept and warned" || fail "T3 broken symlink replaced: $(readlink "$h/.claude/skills/$S")"
# Q2: a link into an older clone is not Helix-owned either
h="$(newhome)"; mkdir -p "$h/old-clone/skills/$S"; ln -s "$h/old-clone/skills/$S" "$h/.claude/skills/$S"; run "$h"
[ "$(readlink "$h/.claude/skills/$S")" = "$h/old-clone/skills/$S" ] && [ "$(clash_lines "$h")" = 1 ] && ok "T3 link into an old clone kept and warned (owner Q2)" || fail "T3 old-clone link replaced"

# T4 (R4): a broken Helix link and a stale in-clone link are refreshed without a warning
h="$(newhome)"; ln -s "$R/skills/does-not-exist/$S" "$h/.claude/skills/$S"; run "$h"
[ -f "$h/.claude/skills/$S/SKILL.md" ] && [ "$(readlink "$h/.claude/skills/$S")" = "$R/skills/$S" ] && [ "$(clash_lines "$h")" = 0 ] && ok "T4 broken Helix link refreshed, no warning" || fail "T4 broken Helix link not refreshed: $(readlink "$h/.claude/skills/$S") / $(cat "$h/err")"
h="$(newhome)"; ln -s "$(cd "$R" && pwd -P)/skills/$S" "$h/.claude/skills/$S"; run "$h"
[ "$(readlink "$h/.claude/skills/$S")" = "$R/skills/$S" ] && [ "$(clash_lines "$h")" = 0 ] && ok "T4 physical-path Helix link refreshed, no warning" || fail "T4 physical-path link not treated as Helix"

# T5 (R8, R10): with a clash the run exits 0, links every other skill, warns on stderr, prints a summary
h="$(newhome)"; mkdir "$h/.claude/skills/$S"; run "$h"
[ "$(cat "$h/rc")" = 0 ] && ok "T5 exit 0 with a clash" || fail "T5 exit $(cat "$h/rc") with a clash"
[ "$(links_to_clone "$h/.claude/skills")" = "$((N - 1))" ] && ok "T5 the other $((N - 1)) skills are linked" || fail "T5 linked $(links_to_clone "$h/.claude/skills"), want $((N - 1))"
grep -q "1 skill(s) skipped" "$h/err" && ok "T5 summary line on stderr" || fail "T5 no summary line: $(cat "$h/err")"
grep -q "skip (" "$h/out" && fail "T5 clash warning leaked to stdout" || ok "T5 clash warning not on stdout"
w="$(HOME="$h" bash "$R/scripts/link-skills.sh" 2>&1 >/dev/null)"
echo "$w" | grep -q "skip (claude) $S" && ok "T5 warning visible with stdout silenced" || fail "T5 warning hidden with stdout silenced"

# T6 (R9): re-runs are idempotent with and without a clash
h="$(newhome)"; mkdir "$h/.claude/skills/$S"; echo mine >"$h/.claude/skills/$S/SKILL.md"
run "$h"; s1="$(snap "$h/.claude/skills")"; e1="$(cat "$h/err")"
run "$h"; s2="$(snap "$h/.claude/skills")"; e2="$(cat "$h/err")"
[ "$s1" = "$s2" ] && [ "$e1" = "$e2" ] && ok "T6 two runs with a clash: same tree, same warnings" || fail "T6 runs with a clash differ"
h="$(newhome)"; run "$h"; s1="$(snap "$h/.claude/skills")"; run "$h"; s2="$(snap "$h/.claude/skills")"
[ "$s1" = "$s2" ] && [ ! -s "$h/err" ] && ok "T6 two clean runs: same tree, no warnings" || fail "T6 clean re-run changed something"

# T7 (R7): another global folder, and workspace folders in absolute and relative mode
h="$(newhome)"; mkdir -p "$h/.cursor/skills/$S"; echo mine >"$h/.cursor/skills/$S/SKILL.md"; run "$h"
[ "$(cat "$h/.cursor/skills/$S/SKILL.md")" = mine ] && [ ! -L "$h/.cursor/skills/$S" ] && grep -q "skip (cursor) $S" "$h/err" && ok "T7 clash in ~/.cursor/skills kept and warned" || fail "T7 cursor clash not handled"
h="$(newhome)"; W="$h/ws"; mkdir -p "$W/.agents/skills/$S"; echo mine >"$W/.agents/skills/$S/SKILL.md"
run "$h" HELIX_LINK_WORKSPACE="$W"
[ "$(cat "$W/.agents/skills/$S/SKILL.md")" = mine ] && [ ! -L "$W/.agents/skills/$S" ] && grep -q "skip (agents-project) $S" "$h/err" && [ "$(cat "$h/rc")" = 0 ] && ok "T7 workspace clash (absolute mode) kept and warned" || fail "T7 workspace absolute clash not handled"
h="$(newhome)"; W="$h/ws"; mkdir -p "$W/skills/helix" "$W/.agents/skills/helix" "$W/.github/skills"
echo ws >"$W/skills/helix/SKILL.md"; echo mine >"$W/.agents/skills/helix/SKILL.md"
ln -s "$R/skills/helix" "$W/.github/skills/helix"
run "$h" HELIX_LINK_WORKSPACE="$W"
[ "$(cat "$W/.agents/skills/helix/SKILL.md")" = mine ] && [ ! -L "$W/.agents/skills/helix" ] && grep -q "skip (agents-project) helix" "$h/err" && ok "T7 workspace clash (relative mode) kept and warned" || fail "T7 workspace relative clash not handled"
[ "$(readlink "$W/.github/skills/helix")" = "../../skills/helix" ] && ok "T7 old absolute Helix link refreshed to relative in relative mode" || fail "T7 absolute Helix link not refreshed: $(readlink "$W/.github/skills/helix")"

# T8 (R6): no recursive delete left in link-skills.sh
grep -nE 'rm -[a-zA-Z]*r' "$R/scripts/link-skills.sh" >/dev/null && fail "T8 link-skills.sh still has a recursive rm" || ok "T8 no recursive rm in link-skills.sh"
finish
