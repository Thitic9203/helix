#!/usr/bin/env bash
# helix-doctor.sh warns about devenv leftovers and writes nothing (Spec: docs/sdd/retire-devenv R14).
. "$(dirname "$0")/lib.sh"
V1="$REPO_ROOT/scripts/tests/fixtures/helix-setup-devenv.v1.sh"
R="$(copy_repo)"; W="$(mktemp -d)"; trap 'rm -rf "$R" "$W"' EXIT
mkdir -p "$R/.git" "$W/bin" "$W/home/.claude" "$W/state"
export HOME="$W/home" CLAUDE_CONFIG_DIR="$W/home/.claude" HELIX_STATE_DIR="$W/home/.helix"
doctor() { # PATH without a claude CLI keeps the run offline and fast
  HELIX_REPO_DIR="$R" PATH="$W/bin:/usr/bin:/bin:$(dirname "$(command -v jq)")" bash "$R/scripts/helix-doctor.sh" 2>&1
}
devenv_warns() { echo "$1" | grep "WARN" | grep -c "devenv"; }
sums() { cksum "$HOME/.claude/"* "$HOME/.helix/"* 2>/dev/null; }

out="$(doctor)"
[ "$(echo "$out" | grep -ci devenv)" -eq 0 ] && ok "clean home: no devenv line" || fail "clean home printed: $(echo "$out" | grep -i devenv)"

printf '{\n  "permissions": {"allow": ["Bash(git status)", "Bash(zeta *)"]}\n}\n' > "$HOME/.claude/settings.json"; printf 'mine\n' > "$HOME/.claude/CLAUDE.md"
bash "$V1" >/dev/null 2>&1
before="$(sums)"; out="$(doctor)"; after="$(sums)"
echo "$out" | grep "WARN" | grep "devenv" | grep -q "allowlist rule" && ok "warns about leftover allowlist rules" || fail "no rules WARN"
echo "$out" | grep "WARN" | grep "devenv" | grep -q "CLAUDE.md" && ok "warns about the HELIX-DEVENV block" || fail "no block WARN"
echo "$out" | grep "WARN" | grep "devenv" | grep -q "opt-in marker" && ok "warns about the opt-in marker" || fail "no marker WARN"
echo "$out" | grep "WARN" | grep "devenv" | grep -q "defaultMode" && ok "warns about a defaultMode Helix set" || fail "no defaultMode WARN"
echo "$out" | grep "WARN" | grep "devenv" | grep -q -- "--uninstall" && ok "WARN names the undo command" || fail "no undo command in WARN"
[ "$before" = "$after" ] && ok "doctor writes nothing" || fail "doctor changed files"

bash "$R/scripts/helix-setup-devenv.sh" --uninstall >/dev/null 2>&1
out="$(doctor)"
[ "$(echo "$out" | grep -ci devenv)" -eq 0 ] && ok "after the undo: no devenv line" || fail "after undo printed: $(echo "$out" | grep -i devenv)"
finish
