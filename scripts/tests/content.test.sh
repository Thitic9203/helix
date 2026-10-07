#!/usr/bin/env bash
# Content invariants that were decided on purpose and have been lost before.
. "$(dirname "$0")/lib.sh"
cd "$REPO_ROOT"
# references/non-pass-challenge-gate.md must keep catch-ai's Defect scope. An ols-qa sync
# (cc9b698, 2026-10-07) once replaced it with an older copy that dropped this line.
f=references/non-pass-challenge-gate.md
grep -q 'catch-ai-workflow' "$f" && grep -q 'classify as a Defect' "$f" \
  && ok "$f keeps the catch-ai Defect scope line" \
  || fail "$f lost the catch-ai Defect scope line — restore it from main before merging (see docs/plan/tech-debt-2026-10.md, phase 3 incident)"
# Chat follows the user's language (user decision 2026-10-07); skill files stay English.
if grep -rqiE 'do not reply in thai|english only in chat|english for user chat' references skills commands hooks AGENTS.md 2>/dev/null; then
  fail "an 'English-only chat' rule came back: $(grep -rliE 'do not reply in thai|english only in chat|english for user chat' references skills commands hooks AGENTS.md | tr '\n' ' ')"
else
  ok "no 'English-only chat' rule (chat follows the user's language)"
fi
finish
