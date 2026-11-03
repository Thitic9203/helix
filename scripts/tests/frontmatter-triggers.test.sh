#!/usr/bin/env bash
# proactive_triggers may live under metadata: (target form) or top-level (legacy);
# a SKILL.md without it, or with an empty list, must fail. --metadata-only rejects the legacy form.
. "$(dirname "$0")/lib.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
CHK="$REPO_ROOT/scripts/lib/frontmatter-triggers.py"

cat > "$W/meta.md" <<'EOF'
---
name: x
description: |
  Does x. Do NOT use for y.
metadata:
  proactive_triggers:
    - do x
---
body
EOF
cat > "$W/legacy.md" <<'EOF'
---
name: x
description: Does x. Do NOT use for y.
proactive_triggers:
  - do x
---
EOF
cat > "$W/missing.md" <<'EOF'
---
name: x
description: Does x. Do NOT use for y.
metadata:
  owner: qa
---
proactive_triggers:
  - body text is not frontmatter
EOF
cat > "$W/empty.md" <<'EOF'
---
name: x
description: Does x.
metadata:
  proactive_triggers:
---
EOF

python3 "$CHK" "$W/meta.md" && ok "metadata form passes" || fail "metadata form rejected"
python3 "$CHK" "$W/legacy.md" && ok "legacy top-level form passes during migration" || fail "legacy form rejected"
python3 "$CHK" "$W/missing.md" && fail "missing triggers passed (body text counted)" || ok "missing triggers fails"
python3 "$CHK" "$W/empty.md" && fail "empty list passed" || ok "empty list fails"
python3 "$CHK" "$W/meta.md" --metadata-only && ok "metadata-only accepts metadata form" || fail "metadata-only rejected metadata form"
python3 "$CHK" "$W/legacy.md" --metadata-only && fail "metadata-only accepted legacy form" || ok "metadata-only rejects legacy form"
finish
