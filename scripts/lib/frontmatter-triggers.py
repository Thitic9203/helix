#!/usr/bin/env python3
"""Exit 0 when a SKILL.md frontmatter lists proactive_triggers, else 1.

Accepted forms (spec docs/sdd/helix-skill-quality R1/R2 in ols-qa):
  metadata:
    proactive_triggers:      <- target form (passes skill-creator quick_validate)
      - phrase
  proactive_triggers:        <- legacy top-level form, accepted during migration
    - phrase
Usage: frontmatter-triggers.py SKILL.md [--metadata-only]
"""
import re
import sys


def frontmatter(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return m.group(1) if m else None


def has_triggers(fm, metadata_only):
    lines = fm.splitlines()
    in_meta = False
    for i, line in enumerate(lines):
        if re.match(r"^[A-Za-z_-]+:", line):
            in_meta = line.startswith("metadata:")
            if not metadata_only and line.startswith("proactive_triggers:"):
                return list_follows(lines, i, 0)
            continue
        m = re.match(r"^(\s+)proactive_triggers:\s*$", line)
        if in_meta and m:
            return list_follows(lines, i, len(m.group(1)))
    return False


def list_follows(lines, i, indent):
    for nxt in lines[i + 1:]:
        if not nxt.strip():
            continue
        m = re.match(r"^(\s*)- \S", nxt)
        return bool(m) and len(m.group(1)) >= indent
    return False


def main():
    if len(sys.argv) < 2:
        print("usage: frontmatter-triggers.py SKILL.md [--metadata-only]", file=sys.stderr)
        return 2
    fm = frontmatter(open(sys.argv[1], encoding="utf-8").read())
    if fm is None:
        return 1
    return 0 if has_triggers(fm, "--metadata-only" in sys.argv[2:]) else 1


if __name__ == "__main__":
    sys.exit(main())
