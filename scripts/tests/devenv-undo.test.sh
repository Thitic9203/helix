#!/usr/bin/env bash
# helix-setup-devenv.sh is retired: it only undoes (Spec: docs/sdd/retire-devenv R1-R9, R13).
# Every case builds its own throwaway HOME under one temp dir that is deleted at the end.
# The "old opt-in" is a frozen copy of the v1 script (blob c925107) so the undo is proved
# against what real machines actually have.
. "$(dirname "$0")/lib.sh"
V1="$REPO_ROOT/scripts/tests/fixtures/helix-setup-devenv.v1.sh"
NEW="$REPO_ROOT/scripts/helix-setup-devenv.sh"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
mkdir -p "$W/shim" "$W/empty"
# v1 names backups by second; a counter keeps each backup distinct and in order.
cat > "$W/shim/date" <<'EOF'
#!/bin/sh
case "$1" in
  +%Y%m%d%H%M%S) n=$(cat "$DATECTR" 2>/dev/null || echo 0); n=$((n + 1)); echo "$n" > "$DATECTR"; printf '2026010100%04d\n' "$n" ;;
  *) exec /bin/date "$@" ;;
esac
EOF
chmod +x "$W/shim/date"

N=0
newhome() { # sets H and the env overrides to a fresh sandbox home
  N=$((N + 1)); H="$W/h$N"; mkdir -p "$H"
  export HOME="$H" CLAUDE_CONFIG_DIR="$H/.claude" HELIX_STATE_DIR="$H/.helix" DATECTR="$W/ctr$N"
  S="$H/.claude/settings.json"; M="$H/.claude/CLAUDE.md"; MARK="$H/.helix/.devenv-opted-in"
}
run() { PATH="$W/shim:$PATH" bash "$@"; }
old_optin() { run "$V1" >/dev/null 2>&1; }
write_pre() { # a settings file with odd formatting and unsorted rules, plus a CLAUDE.md
  mkdir -p "$H/.claude"
  printf '{\n    "model": "opus",\n    "permissions": {\n        "allow": ["Bash(zeta *)", "Bash(alpha)"],\n        "deny": ["Read(.env)"]\n    }\n}\n' > "$S"
  printf '# My rules\n\nBe kind.\n' > "$M"
}
keep_pre() { cp "$S" "$W/pre.s" 2>/dev/null; cp "$M" "$W/pre.m" 2>/dev/null; }
same() { cmp -s "$1" "$2"; }
snapshot() { (cd "$1" && find . -type f | sort | xargs cksum 2>/dev/null); }
nbak() { ls "$1".helix-bak.* 2>/dev/null | wc -l | tr -d ' '; }

# T0: the frozen v1 fixture
[ "$(git -C "$REPO_ROOT" hash-object "$V1" 2>/dev/null)" = "c925107ed6948849c708083ab781cb630595a745" ] && ok "v1 fixture hash is c925107" || fail "v1 fixture missing or changed"
newhome; write_pre; keep_pre; old_optin
n_rules="$(jq '.permissions.allow | length' "$S" 2>/dev/null)"
[ "$n_rules" = "47" ] && ok "old opt-in wrote 45 rules + 2 user rules" || fail "old opt-in rules: $n_rules"
grep -q "HELIX-DEVENV:START" "$M" && [ -f "$MARK" ] && ok "old opt-in wrote block and marker" || fail "old opt-in block/marker missing"

# T1: no-argument run
newhome
out="$(run "$NEW" 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "no-arg run on a clean home exits 0" || fail "no-arg exit $rc"
[ -z "$(find "$H" -type f)" ] && ok "no-arg run on a clean home creates no file" || fail "no-arg created: $(find "$H" -type f)"
echo "$out" | grep -qi "retired" && echo "$out" | grep -q -- "--uninstall" && ok "no-arg run says retired + undo command" || fail "no-arg message: $out"
newhome; write_pre; keep_pre; old_optin
mkdir -p "$H/.helix"; echo 2 > "$H/.helix/.devenv-notice-count"
run "$NEW" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && same "$S" "$W/pre.s" && same "$M" "$W/pre.m" && [ ! -e "$MARK" ] && [ ! -e "$H/.helix/.devenv-notice-count" ] && ok "no-arg run on an opted-in home undoes: byte-equal, marker + notice count gone" || fail "no-arg on opted-in home did not undo (rc $rc)"

# T2: plain byte-equal undo (CLAUDE.md with and without a trailing newline)
newhome; write_pre; keep_pre; old_optin
out="$(run "$NEW" --uninstall 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && ok "--uninstall exits 0" || fail "--uninstall exit $rc"
same "$S" "$W/pre.s" && ok "settings.json byte-equal to pre-opt-in" || fail "settings.json differs from pre-opt-in"
same "$M" "$W/pre.m" && ok "CLAUDE.md byte-equal to pre-opt-in" || fail "CLAUDE.md differs from pre-opt-in"
[ ! -e "$MARK" ] && ok "marker removed" || fail "marker still present"
newhome; write_pre; printf 'no newline at end' > "$M"; keep_pre; old_optin
run "$NEW" --uninstall >/dev/null 2>&1
same "$M" "$W/pre.m" && same "$S" "$W/pre.s" && ok "byte-equal when CLAUDE.md had no trailing newline" || fail "no-trailing-newline case differs"

# T3: files missing before opt-in
newhome; old_optin
run "$NEW" --uninstall >/dev/null 2>&1
[ "$(cat "$S" 2>/dev/null)" = "{}" ] && ok "missing settings.json comes back as the backup ({})" || fail "settings.json after undo: $(cat "$S" 2>/dev/null)"
[ -f "$M" ] && [ ! -s "$M" ] && ok "missing CLAUDE.md comes back empty" || fail "CLAUDE.md after undo not empty"

# T4: a user rule that is also in the shipped list survives
newhome; mkdir -p "$H/.claude"
printf '{\n  "permissions": {"allow": ["Bash(git status)", "Bash(zeta *)"]}\n}\n' > "$S"; printf 'x\n' > "$M"; keep_pre; old_optin
out="$(run "$NEW" --uninstall 2>&1)"
jq -e '.permissions.allow | index("Bash(git status)")' "$S" >/dev/null && ok "pre-existing listed rule kept" || fail "pre-existing listed rule was removed"
echo "$out" | grep -F "Bash(git status)" | grep -qi "kept\|keep" && ok "kept rule is named in the output" || fail "kept rule not named: $out"
same "$S" "$W/pre.s" && ok "settings byte-equal with a kept rule" || fail "settings differ with a kept rule"

# T5: defaultMode (owner decision Q1 = option A)
newhome; mkdir -p "$H/.claude"; printf '{\n  "permissions": {"defaultMode": "plan", "allow": []}\n}\n' > "$S"; printf 'x\n' > "$M"; keep_pre; old_optin
run "$NEW" --uninstall >/dev/null 2>&1
[ "$(jq -r '.permissions.defaultMode' "$S")" = "plan" ] && same "$S" "$W/pre.s" && ok "5a: user's defaultMode kept" || fail "5a: user's defaultMode lost"
newhome; write_pre; keep_pre; old_optin
[ "$(jq -r '.permissions.defaultMode' "$S")" = "acceptEdits" ] || fail "5b setup: Helix did not set defaultMode"
run "$NEW" --uninstall >/dev/null 2>&1
[ "$(jq -r '.permissions.defaultMode // "none"' "$S")" = "none" ] && ok "5b: Helix-set defaultMode removed" || fail "5b: defaultMode still set"
newhome; write_pre; old_optin; rm -f "$S".helix-bak.* "$M".helix-bak.*
out="$(run "$NEW" --uninstall 2>&1)"
[ "$(jq -r '.permissions.defaultMode' "$S")" = "acceptEdits" ] && ok "5c: no backup -> defaultMode left alone" || fail "5c: defaultMode changed without a backup"
echo "$out" | grep -i "defaultMode" | grep -qi "backup" && ok "5c: hint line printed" || fail "5c: no hint: $out"
[ "$(jq -c '.permissions.allow' "$S")" = '["Bash(alpha)","Bash(zeta *)"]' ] && ok "5c: all 45 rules removed, user rules kept" || fail "5c: allow is $(jq -c '.permissions.allow' "$S")"
[ "$(jq -r .model "$S")" = "opus" ] && ok "5c: other keys untouched" || fail "5c: model lost"

# T6: user edits after opt-in survive (in-place edit, not a byte restore)
newhome; write_pre; old_optin
jq '.permissions.allow += ["Bash(make *)"] | .x = 1' "$S" > "$W/t" && cp "$W/t" "$S"
printf '\nadded after opt-in\n' >> "$M"
out="$(run "$NEW" --uninstall 2>&1)"
[ "$(jq -c '.permissions.allow' "$S")" = '["Bash(alpha)","Bash(make *)","Bash(zeta *)"]' ] && [ "$(jq -r .x "$S")" = "1" ] && [ "$(jq -r .model "$S")" = "opus" ] && ok "later settings edits kept, 45 rules gone" || fail "6: settings is $(jq -c . "$S")"
grep -q "added after opt-in" "$M" && ! grep -q "HELIX-DEVENV" "$M" && ok "later CLAUDE.md text kept, block gone" || fail "6: CLAUDE.md wrong"
echo "$out" | grep -qi "could not be restored" && ok "order/format message printed" || fail "6: no order message: $out"

# T7: partly undone (today's --uninstall already ran) + idempotence
newhome; write_pre; keep_pre; old_optin
run "$V1" --uninstall >/dev/null 2>&1
run "$NEW" --uninstall >/dev/null 2>&1
same "$S" "$W/pre.s" && same "$M" "$W/pre.m" && ok "partly undone home is restored byte-equal" || fail "7: partly undone not restored"
before="$(snapshot "$H")"; sleep 1; touch "$W/stamp"
run "$NEW" --uninstall >/dev/null 2>&1; rc=$?
[ "$rc" -eq 0 ] && [ "$(snapshot "$H")" = "$before" ] && [ -z "$(find "$H" -newer "$W/stamp")" ] && ok "second --uninstall writes nothing" || fail "7: second run changed files: $(find "$H" -newer "$W/stamp")"

# T8: backups are kept, and added only when a file changes
newhome; write_pre; old_optin
b_s="$(nbak "$S")"; b_m="$(nbak "$M")"
run "$NEW" --uninstall >/dev/null 2>&1
[ "$(nbak "$S")" -eq $((b_s + 1)) ] && [ "$(nbak "$M")" -eq $((b_m + 1)) ] && ok "one new backup per changed file" || fail "8: backups $(nbak "$S")/$(nbak "$M") from $b_s/$b_m"
run "$NEW" --uninstall >/dev/null 2>&1
[ "$(nbak "$S")" -eq $((b_s + 1)) ] && [ "$(nbak "$M")" -eq $((b_m + 1)) ] && ok "no new backup on the second run" || fail "8: second run added backups"

# T9: overrides and no jq
newhome; write_pre; old_optin
mkdir -p "$W/decoy"; cp "$S" "$W/decoy/settings.json"; before="$(cksum < "$W/decoy/settings.json")"
export CLAUDE_CONFIG_DIR="$W/decoy"; run "$NEW" --uninstall >/dev/null 2>&1
[ "$(jq '.permissions.allow | length' "$W/decoy/settings.json")" -eq 2 ] && [ "$(jq '.permissions.allow | length' "$S")" -eq 47 ] && ok "CLAUDE_CONFIG_DIR override edits that dir only" || fail "9: override not honoured"
export CLAUDE_CONFIG_DIR="$H/.claude"
newhome; write_pre; old_optin; before="$(snapshot "$H")"
env PATH="$W/empty" /bin/bash "$NEW" --uninstall >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && [ "$(snapshot "$H")" = "$before" ] && ok "no jq -> exit 1, nothing changed" || fail "9: no-jq rc $rc"

# T13: notice-count file is deleted, absence is fine
newhome; write_pre; old_optin; mkdir -p "$H/.helix"; echo 3 > "$H/.helix/.devenv-notice-count"
run "$NEW" --uninstall >/dev/null 2>&1
[ ! -e "$H/.helix/.devenv-notice-count" ] && ok "undo deletes .devenv-notice-count" || fail "13: notice count still there"
run "$NEW" --uninstall >/dev/null 2>&1 && ok "undo without the notice file is fine" || fail "13: failed without notice file"
finish
