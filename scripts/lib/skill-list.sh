#!/usr/bin/env bash
# Skills that link-skills.sh links: every skills/*/SKILL.md except procedures/ and in-progress/.
# Usage: . scripts/lib/skill-list.sh; helix_linked_skills <repo>   (one name per line, sorted)
# Spec: docs/sdd/skill-list-drift R1
helix_linked_skills() {
  [ -d "$1/skills" ] || return 0
  find "$1/skills" -name SKILL.md -not -path '*/in-progress/*' -not -path '*/procedures/*' \
    | while IFS= read -r f; do basename "$(dirname "$f")"; done | sort
}
