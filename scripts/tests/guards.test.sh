#!/usr/bin/env bash
# ci-check-portable-skills.sh, check-no-secrets.sh, ci-check-skill-structure.sh
. "$(dirname "$0")/lib.sh"
R="$(copy_repo)"; trap 'rm -rf "$R"' EXIT
cd "$R"
expect_exit 0 "portable check passes on the repo as shipped" -- bash scripts/ci-check-portable-skills.sh
printf 'see ~/.helix/tc-fe-prep\n' > references/zz-probe.md
expect_exit 1 "portable check catches a machine path in references/" -- bash scripts/ci-check-portable-skills.sh
printf 'call mcp__Control_Chrome__open_url\n' > references/zz-probe.md
expect_exit 1 "portable check catches a host-specific tool name" -- bash scripts/ci-check-portable-skills.sh
expect_exit 0 "portable check runs without ripgrep on PATH" -- env PATH=/usr/bin:/bin bash -c 'rm -f references/zz-probe.md; bash scripts/ci-check-portable-skills.sh'
printf 'clean text\n' > references/zz-probe.md
expect_exit 0 "secret guard passes a clean file" -- bash scripts/check-no-secrets.sh references/zz-probe.md
# Probe strings are assembled at run time so this file never contains a secret shape itself
# (the pre-commit secret guard scans it too).
fake_token="$(printf 'z%.0s' $(seq 1 32))"
printf 'Authorization: %s %s\n' "Bear""er" "$fake_token" > references/zz-probe.md
expect_exit 1 "secret guard blocks a bearer token" -- bash scripts/check-no-secrets.sh references/zz-probe.md
printf -- '-----BEGIN RSA %s KEY-----\n' "PRIV""ATE" > references/zz-probe.md
expect_exit 1 "secret guard blocks a private key header" -- bash scripts/check-no-secrets.sh references/zz-probe.md
rm -f references/zz-probe.md
expect_exit 0 "skill structure passes as shipped" -- bash scripts/ci-check-skill-structure.sh
cp skills/helix/SKILL.md "$R/zz-helix.bak"
python3 - skills/helix/SKILL.md <<'PY'
import sys;p=sys.argv[1];s=open(p).read();open(p,'w').write(s.replace('\n---\n','\nmetadata:\n  proactive_triggers:\n    - x\n---\n',1))
PY
expect_exit 1 "skill structure fails when frontmatter has proactive_triggers" -- bash scripts/ci-check-skill-structure.sh
tail -n +2 "$R/zz-helix.bak" > skills/helix/SKILL.md
expect_exit 1 "skill structure fails when a SKILL.md has no frontmatter" -- bash scripts/ci-check-skill-structure.sh
cp "$R/zz-helix.bak" skills/helix/SKILL.md; rm -f "$R/zz-helix.bak"
mkdir -p skills/zz-unregistered && printf -- '---\nname: zz-unregistered\ndescription: probe\n---\n' > skills/zz-unregistered/SKILL.md
expect_exit 1 "skill structure fails on a skill missing from plugin.json" -- bash scripts/ci-check-skill-structure.sh
rm -rf skills/zz-unregistered
# Spec docs/sdd/project-agnostic R9: whole-word, case-sensitive project tokens, hashed (T2).
printf 'ZZPROJ\n' > "$R/zz-tokens.txt"
printf 'see the ZZPROJ portal\n' > references/zz-probe.md
expect_exit 1 "portable check catches a project token from the runtime list" -- env HELIX_EXTRA_PROJECT_TOKENS="$R/zz-tokens.txt" bash scripts/ci-check-portable-skills.sh
printf 'see the zzproj portal\n' > references/zz-probe.md
expect_exit 0 "project token match is case-sensitive" -- env HELIX_EXTRA_PROJECT_TOKENS="$R/zz-tokens.txt" bash scripts/ci-check-portable-skills.sh
printf 'see XZZPROJX here\n' > references/zz-probe.md
expect_exit 0 "project token match is whole-word only" -- env HELIX_EXTRA_PROJECT_TOKENS="$R/zz-tokens.txt" bash scripts/ci-check-portable-skills.sh
printf 'run zz-ZZPROJ-qa now\n' > references/zz-probe.md
expect_exit 1 "project token is found inside a hyphenated name" -- env HELIX_EXTRA_PROJECT_TOKENS="$R/zz-tokens.txt" bash scripts/ci-check-portable-skills.sh
cp scripts/project-token-hashes.txt "$R/zz-hashes.bak" 2>/dev/null || : > "$R/zz-hashes.bak"
printf '%s\n' "$(printf '%s' ZZPROJ | shasum -a 256 | awk '{print $1}')" >> scripts/project-token-hashes.txt
expect_exit 1 "portable check catches a token listed by hash in project-token-hashes.txt" -- bash scripts/ci-check-portable-skills.sh
cp "$R/zz-hashes.bak" scripts/project-token-hashes.txt; rm -f "$R/zz-hashes.bak" "$R/zz-tokens.txt" references/zz-probe.md
expect_exit 0 "portable check still passes as shipped after the token probes" -- bash scripts/ci-check-portable-skills.sh
# Spec docs/sdd/project-agnostic R8/R10: every file Helix owns (skipped by the ols-qa sync) must exist.
owned_ok='[ -f helix-owned-files.txt ] && grep -v "^#" helix-owned-files.txt | grep -v "^$" | { ok=0; while read -r f; do [ -f "$f" ] || { echo "missing: $f"; ok=1; }; done; exit $ok; }'
expect_exit 0 "every path in helix-owned-files.txt exists" -- bash -c "$owned_ok"
if [ -f helix-owned-files.txt ]; then
  cp helix-owned-files.txt "$R/zz-owned.bak"
  printf 'skills/zz-not-a-file.md\n' >> helix-owned-files.txt
  expect_exit 1 "owned-list check fails on a path that does not exist" -- bash -c "$owned_ok"
  cp "$R/zz-owned.bak" helix-owned-files.txt; rm -f "$R/zz-owned.bak"
fi
finish
