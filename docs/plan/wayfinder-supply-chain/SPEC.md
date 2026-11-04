# Spec: Helix install and update supply-chain hardening

Status: decided, 2026-11-04. All decisions in [MAP.md](MAP.md) are closed. The [Team notice](tickets/06-team-notice.md) draft is waiting for the owner's approval. Code changes land through normal PRs, each with its own `docs/sdd/<slug>/` spec, plan and tasks.

## Rules

- **R1 — Install is pinned and checked** ([04](tickets/04-install-path.md)). The only documented install downloads the installer of a named release tag and checks it against the SHA-256 published with that release. If the check fails, the installer stops before it runs anything. The `curl … | bash` line from `main` is removed from README and `scripts/install.sh`.
  - Done when: README has no `| bash` from `main`; a test feeds the installer a tampered file and gets a non-zero exit with nothing written.
- **R2 — Session start never runs newly fetched code** ([03](tickets/03-auto-update-policy.md)). The SessionStart path only compares the installed release with the newest release tag and prints one line when a newer one exists. Fetch, fast-forward, `link-skills.sh`, `claude-plugin-sync.sh` and the devenv re-sync run only from an update command the user starts.
  - Done when: a test runs the session-start hook against a remote with a newer tag, and the clone's HEAD, the skill links and the plugin cache are all unchanged afterwards.
- **R3 — devenv is retired, with a full undo** ([05](tickets/05-devenv-posture.md)). `scripts/helix-setup-devenv.sh` no longer adds anything. Its undo:
  - removes every allowlist rule any Helix version added;
  - removes the `HELIX-DEVENV` block from `~/.claude/CLAUDE.md`;
  - restores `defaultMode` only if Helix set it;
  - deletes `~/.helix/.devenv-opted-in`.

  `helix-auto-update.sh` no longer re-runs devenv (today at `:223-228`). `hooks/session-start` no longer tells the agent to suggest running devenv (today at `:25-41`, shown on every machine that has not opted in).
  - Done when: the session-start hook's output contains no `helix-setup-devenv`.
  - Done when: a test on a fake `$HOME` that has the old opt-in applied ends with settings and CLAUDE.md byte-equal to their pre-opt-in state.
- **R4 — Install never deletes user files** ([07](tickets/07-link-skills-overwrite.md)). On a name clash with a non-symlink, `link-skills.sh` skips that skill and prints the clash. It never runs `rm -rf` on anything Helix did not create.
  - Done when: a test with a same-named user folder ends with the folder intact and a warning printed.
- **R5 — Team notice** ([06](tickets/06-team-notice.md)). A notice file in this repo, drafted in [notice-draft.md](notice-draft.md), goes out after the owner approves it. It is updated again when the fixed release ships.

## Accepted limits

- A SHA-256 published next to the code on GitHub does not protect against a compromised upstream; see [research 01](research/01-claude-plugin-pinning.md). Signed releases are a follow-up (below).
- With notify-only updates, teammates stay on older versions until they update. This replaces the owner's 2026-10-20 wish for automatic updates.

## Follow-ups (from the map's fog; not part of this spec)

- Release integrity: sign tags (`git verify-tag` with SSH signing, free) and verify before update.
- Regression guard: a CI check that fails on new broad allowlist entries, global `CLAUDE.md` writes, or unverified downloads.
- `ols-qa` impact: the 2026-11-04 check of `ols-qa` (`origin/main` as last fetched; a fresh fetch failed during a GitHub incident) found none of these scripts. Its project `.claude/settings.json` allows `Bash(python3 *)` and `Bash(npx playwright *)`. Re-check after a fresh fetch.

## Cost and repos

New cost: none (everything uses git, GitHub releases and shell, all free). Other repos touched: `ols-qa` only through the usual helix-sync of shared files, if any change touches them.
