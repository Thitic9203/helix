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
mkdir -p skills/zz-unregistered && printf -- '---\nname: zz-unregistered\ndescription: probe\n---\n' > skills/zz-unregistered/SKILL.md
expect_exit 1 "skill structure fails on a skill missing from plugin.json" -- bash scripts/ci-check-skill-structure.sh
finish
