# Spec: Helix install and update supply-chain hardening

Status: **implemented and released in v1.5.167 (2026-11-05).** All decisions in [MAP.md](MAP.md) are closed; owner answers to the SDD questions are in [owner-decisions-2026-11-04.md](owner-decisions-2026-11-04.md). Each rule shipped as one PR with its own `docs/sdd/<slug>/` spec, plan and tasks:

| Rule | SDD | PR |
|---|---|---|
| R4 | `docs/sdd/link-skills-no-delete` | [#16](https://github.com/Thitic9203/helix/pull/16) |
| R3 | `docs/sdd/retire-devenv` | [#17](https://github.com/Thitic9203/helix/pull/17) |
| R2 | `docs/sdd/update-notify-only` | [#18](https://github.com/Thitic9203/helix/pull/18) |
| R1 | `docs/sdd/install-pinned-checksum` | [#19](https://github.com/Thitic9203/helix/pull/19) |
| R5 | [SECURITY-NOTICE.md](../../../SECURITY-NOTICE.md) | updated for v1.5.167 |

Checked after release (2026-11-05): release `v1.5.167` targets the merge commit and carries `install.sh` and `install.sh.sha256`; the README install block run against it in a sandbox home exits 0, leaves the clone at `v1.5.167`, and writes nothing outside the sandbox.

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
- `ols-qa` impact: checked on 2026-11-04 after a fresh fetch (`origin/main` `e0a512e`): none of these scripts exist there. Its project `.claude/settings.json` allows `Bash(python3 *)` and `Bash(npx playwright *)`. Nothing to change.
- Doc wording: a grep on 2026-11-05 of README, wiki, DOC-MAP, supported-agents, CONTRIBUTING, `references/` and the helix skill found no user-facing "auto-update" claim left outside script and file names (`helix-auto-update.sh`, `auto-update.log`, `HELIX_AUTO_UPDATE`). The update-notify-only test (R13) covers only the patterns it names, so this grep is not enforced.

## Cost and repos

New cost: none (everything uses git, GitHub releases and shell, all free). Other repos touched: `ols-qa` only through the usual helix-sync of shared files, if any change touches them.
