#!/usr/bin/env bash
# Skill lists in docs and in helix-doctor.sh follow the skills link-skills.sh links.
# Spec: docs/sdd/skill-list-drift R1-R7
. "$(dirname "$0")/lib.sh"
R="$(copy_repo)"; H="$(mktemp -d)"; B="$(mktemp -d)"; trap 'rm -rf "$R" "$H" "$B"' EXIT

# R1: the helper lists exactly what link-skills.sh links
mkdir -p "$H/.cursor"
HOME="$H" HELIX_QUIET=1 bash "$R/scripts/link-skills.sh" >/dev/null 2>&1
want="$(find "$H/.cursor/skills" -maxdepth 1 -type l -exec basename {} \; | sort | tr '\n' ' ')"
got="$(. "$R/scripts/lib/skill-list.sh" && helix_linked_skills "$R" | tr '\n' ' ')"
[ -n "$got" ] && [ "$got" = "$want" ] && ok "helper lists the skills link-skills.sh links" || fail "helper [$got] != linked [$want]"
total="$(echo "$got" | wc -w | tr -d ' ')"

# R1, R2: doctor counts from the skills folder (PATH without a claude CLI keeps it offline)
mkdir -p "$R/.git"
doctor() { HOME="$H" HELIX_REPO_DIR="$R" HELIX_STATE_DIR="$H/state" PATH="$B:/usr/bin:/bin" bash "$R/scripts/helix-doctor.sh" 2>&1; }
out="$(doctor)"
echo "$out" | grep -q "Cursor: all $total skills linked" && ok "doctor checks all $total linked skills" || fail "doctor did not report all $total skills linked"
echo "$out" | grep -q "expect helix + $((total - 1)) workflows" && ok "doctor header shows the computed count" || fail "doctor header count is not $((total - 1))"
mkdir -p "$R/skills/zz-workflow" && printf -- '---\nname: zz-workflow\n---\n' > "$R/skills/zz-workflow/SKILL.md"
out="$(doctor)"; echo "$out" | grep -q "Skill zz-workflow" && ok "doctor picks up a new skill without edits" || fail "doctor ignored a new skill"
rm -rf "$R/skills/zz-workflow"
mkdir -p "$R/skills/in-progress/yy-workflow" && touch "$R/skills/in-progress/yy-workflow/SKILL.md"
out="$(doctor)"; echo "$out" | grep -q "Skill yy-workflow" && fail "doctor counted an in-progress skill" || ok "doctor skips in-progress skills"
rm -rf "$R/skills/in-progress/yy-workflow"

# R3-R5: the doc check passes on the repo and fails on each planted drift
check() { bash "$R/scripts/ci-check-doc-skill-lists.sh" "$R"; }
expect_exit 0 "doc check passes on the current docs" -- check
cp "$R/README.md" "$B/README.md"
grep -v 'test-data-prep-workflow' "$B/README.md" > "$R/README.md"
expect_exit 1 "doc check fails when README drops a workflow" -- check
cp "$B/README.md" "$R/README.md"
cp "$R/docs/wiki/Home.md" "$B/Home.md"
echo "- Symlink **helix + 7 workflow skills**" >> "$R/docs/wiki/Home.md"
expect_exit 1 "doc check fails on a wrong installed count" -- check
cp "$B/Home.md" "$R/docs/wiki/Home.md"
echo "- Menus and questions are **English only**." >> "$R/README.md"
expect_exit 1 "doc check fails on an English-only chat line" -- check
cp "$B/README.md" "$R/README.md"
sed -E 's/options 1–[0-9]+/options 1–7/' "$B/README.md" > "$R/README.md"
expect_exit 1 "doc check fails when README's menu range differs from menu-text.md" -- check
cp "$B/README.md" "$R/README.md"

# R6: a non-executable script fails the regression check
(cd "$R" && git init -q . 2>/dev/null; chmod -x scripts/link-skills.sh)
out="$(cd "$R" && bash scripts/helix-regression-check.sh 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && echo "$out" | grep -q "FAIL: not executable: scripts/link-skills.sh" && ok "regression check fails on a non-executable script" || fail "regression check passed with a non-executable script"
finish
