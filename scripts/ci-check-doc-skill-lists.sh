#!/usr/bin/env bash
# Fail when user docs drift from the skills link-skills.sh links.
# Usage: bash scripts/ci-check-doc-skill-lists.sh [repo-root]
# Spec: docs/sdd/skill-list-drift R3 (every workflow named), R4 (installed counts), R5 (no English-only chat)
set -uo pipefail
ROOT="${1:-$(cd "$(dirname "$0")/.." && pwd)}"
. "$(cd "$(dirname "$0")" && pwd)/lib/skill-list.sh"
cd "$ROOT" || exit 2

SKILLS="$(helix_linked_skills "$ROOT")"
TOTAL="$(printf '%s\n' "$SKILLS" | grep -c .)"
WORKFLOWS=$((TOTAL - 1))
[ "$TOTAL" -gt 1 ] || { echo "FAIL: no skills found under $ROOT/skills"; exit 2; }
BAD=0
miss() { echo "  $*"; BAD=$((BAD + 1)); }

# Docs with a per-workflow table; docs/sdd and docs/plan are history and cite old values on purpose.
LIST_DOCS="README.md AGENTS.md docs/wiki/Home.md references/agent-entry.md"
COUNT_DOCS="$(find README.md AGENTS.md docs references -name '*.md' -not -path 'docs/sdd/*' -not -path 'docs/plan/*' 2>/dev/null)"

# R3
for f in $LIST_DOCS; do
  for s in $SKILLS; do
    [ "$s" = helix ] && continue
    grep -q "\`$s\`\|($s)\|/$s/\|\[$s\]" "$f" || miss "$f: does not name $s"
  done
done

# R4
while IFS=: read -r f n text; do
  got="$(printf '%s' "$text" | sed -E 's/.*helix \+ ([0-9]+) workflow.*/\1/')"
  [ "$got" = "$WORKFLOWS" ] || miss "$f:$n: says helix + $got workflows, linked: helix + $WORKFLOWS"
done < <(grep -nE 'helix \+ [0-9]+ workflow' $COUNT_DOCS /dev/null)
while IFS=: read -r f n text; do
  got="$(printf '%s' "$text" | sed -E 's/.*\*\*([0-9]+) skills\*\*.*/\1/')"
  [ "$got" = "$TOTAL" ] || miss "$f:$n: says $got skills, linked: $TOTAL"
done < <(grep -nE '\*\*[0-9]+ skills\*\*' $COUNT_DOCS /dev/null)

# R5 — chat follows the user's language (references/user-communication.md)
while IFS= read -r hit; do
  miss "$hit: chat/menus follow the user's language, not English only"
done < <(grep -niE '(menu|menus|chat|questions|replies)[^.]{0,40}english[ -]only' README.md $COUNT_DOCS /dev/null | cut -d: -f1,2)

# R8 — README menu range matches references/menu-text.md
menu_n="$(grep -oE 'Reply with \*\*1\*\*–\*\*[0-9]+\*\*' references/menu-text.md | grep -oE '[0-9]+\*\*$' | tr -d '*')"
readme_n="$(grep -oE 'options 1–[0-9]+' README.md | grep -oE '[0-9]+$')"
[ -n "$menu_n" ] && [ "$readme_n" = "$menu_n" ] || miss "README.md: menu options 1–${readme_n:-?}, references/menu-text.md: 1–${menu_n:-?}"

if [ "$BAD" -gt 0 ]; then
  echo "FAIL: $BAD doc drift(s) from the $TOTAL linked skills (helix + $WORKFLOWS):"
  exit 1
fi
echo "ok: docs name all $WORKFLOWS workflows and state $TOTAL skills"
