---
labels: [wayfinder:map]
tracker: local-markdown (same layout as ../wayfinder-round-time/README.md)
created: 2026-11-04
---

# Map: Close Helix's install and update supply-chain risks, and tell the team

## Destination

A decided spec, `SPEC.md` in this folder, that closes the three risks the team lead raised on 2026-11-04. The spec also includes a team notice that is ready to send. Code changes happen after this map, through normal PRs. The owner chose both: fix the code **and** tell the team (2026-11-04).

The three risks, as checked against `origin/main` on 2026-11-04:

1. **Install:** `scripts/install.sh:5` documents `curl -sL https://raw.githubusercontent.com/<owner>/helix/main/scripts/install.sh | bash`. The script installs from `main`. No version is pinned and there is no checksum: a search of `install.sh` and `setup.sh` for sha256, checksum or shasum returned 0 hits.
2. **Auto-update:** the SessionStart hook runs `scripts/helix-auto-update.sh`. That script fetches the newest `v*` release tag, fast-forwards the clone to it (lines 135–163), then runs `link-skills.sh` and `claude-plugin-sync.sh` from the new code in the same session (lines 115–119 and 179). The update is gated to release tags that are on `origin/main`, and those tags are created only after CI passes. A search for gpg, signature or verify found **no tag-signature check**. If upstream were compromised, the new code would run on every machine at its next session start.
3. **setup-devenv:** `scripts/helix-setup-devenv.sh` is **opt-in** (lines 16–17). Once a user runs it, it:
   - merges a broad allowlist into `~/.claude/settings.json`, including `Bash(npx *)`, `Bash(node *)`, `Bash(python3 *)`, `Bash(gh api *)` and `Bash(bash scripts/*)` (lines 29–43);
   - sets `defaultMode: acceptEdits` (line 90);
   - injects a "Bias toward action — do, ask less" block into the global `~/.claude/CLAUDE.md` (line 46).

   `helix-auto-update.sh` then keeps both in sync on every later update (line 10 of the header).

## Notes

- Domain: Helix install, update and environment scripts (`scripts/install.sh`, `scripts/setup.sh`, `scripts/helix-auto-update.sh`, `scripts/claude-plugin-sync.sh`, `scripts/helix-setup-devenv.sh`, `hooks/hooks.json`, `scripts/hooks/*`).
- **Standing rule (owner, 2026-11-04):** the helix skill evaluation (round 6) is paused until this map's destination is reached.
- **Free only** (global rule 3). Any option that costs money (paid signing service, paid scanner) goes to the owner with an estimate. It is never chosen by the agent.
- Every "recommended" option must cite a document that was opened (Claude Code docs, git docs, a measured fact in this repo) together with its date. Guesses are not allowed.
- This repo is public. No company names, hosts, ids or personal paths go in any file here.
- No grilling or domain-modeling skill is installed. HITL tickets are worked through AskUserQuestion with the owner, as in `wayfinder-round-time`.
- Shared skills sync to `ols-qa`. Any change to a shared file follows the helix-sync rule there.

## Decisions so far

<!-- one line per closed ticket -->

## Not yet specified

- **Release integrity:** whether release tags or artifacts get signed (git tag signing, Sigstore or GitHub artifact attestations), who holds the key, and how the installer and updater verify the signature. This waits on the update-policy and install-path decisions.
- **Regression guard:** a CI or lint check that fails when a script widens the allowlist, writes to the global `CLAUDE.md`, or adds an unverified download. Its shape depends on what the devenv decision keeps.
- **Migration for existing installs:** how machines that already have auto-update, or the devenv opt-in, move to the new posture. That covers an uninstall or reset step and what the next session prints.
- **`ols-qa` impact:** whether `ols-qa` carries copies of these scripts or hooks that need the same change.

## Out of scope

- Helix skill-quality evaluation, round 6 (paused, not cancelled). It resumes as its own effort after this map.
