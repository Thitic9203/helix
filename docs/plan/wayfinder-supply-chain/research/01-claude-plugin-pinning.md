# Research 01 — Claude plugin pinning, update control, hook control, git tag verification

Ticket: `docs/plan/wayfinder-supply-chain/tickets/01-claude-plugin-pinning.md`
All web pages below were read on 2026-11-04. Local commands were run on 2026-11-04 (`claude --version` and `git version 2.53.0` output captured in the same session).

## Findings

### Local code (current behaviour)

- L1. Install is `curl -sL https://raw.githubusercontent.com/<owner>/helix/main/scripts/install.sh | bash` — reads from `main`, no pin or checksum. Source: `scripts/install.sh:5`.
- L2. `scripts/claude-plugin-sync.sh:54` runs `claude plugin update "$CANONICAL"`.
- L3. `scripts/helix-auto-update.sh:135` fetches `origin main` plus `+refs/tags/v*:refs/tags/v*` (force-updates local tags); `:140` picks the highest `vX.Y.Z` tag; `:145` checks the tag is an ancestor of `origin/main`; `:163` runs `git merge --ff-only "$tag"`. No `verify-tag` / `--verify-signatures` call appears in the grep of lines matching `merge|fetch|tag` (command: `grep -n 'plugin update\|merge\|fetch\|tag' scripts/claude-plugin-sync.sh scripts/helix-auto-update.sh`).
- L4. Local git is `git version 2.53.0` (`git --version`).
- L5. The hook chain is `hooks/hooks.json:3-10` (SessionStart, matcher `startup|clear|compact`, runs `"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd" session-start`, `"async": false`) → `hooks/session-start:10-14` runs `scripts/helix-auto-update.sh` from the plugin root, or else from `~/.helix/tc-fe-prep/scripts/`, with errors suppressed (`2>/dev/null || true`).

### Claude Code CLI (local, `claude --version` = 2.1.312)

- C1. `claude plugin install --help` lists these options: `--accept-command <sha256>`, `--config`, `--json`, `--marketplace <source>`, `--registry <url>`, `-s/--scope`, `-y/--yes`. There is **no** `--version`, `--ref`, `--tag` or `--sha` option to pick a plugin version at install time (command output, 2026-11-04).
- C2. `claude plugin update --help`: "Update a plugin to the latest version (restart required to apply)". Options: `--accept-command <sha256>`, `--json`, `-s/--scope` (user, project, local, managed), `-y/--yes`. No option to update to a specific version (command output).
- C3. `--accept-command <sha256>` pins only a *marketplace-declared command* (a command-source install or a `headersHelper`): it is accepted only if its sha256 matches; "If either changed (a refresh that moved the catalog counts), the run refuses". It does not pin the plugin's files (same help output).

### Claude Code docs — pinning a plugin to a tag or commit

- D1. A marketplace entry with a `github` plugin source takes `repo` (`owner/repo`) and optional `ref` and `sha`; the docs example shows `"ref": "v2.0.0"` and a 40-hex `"sha"`. Source: https://code.claude.com/docs/en/plugins/marketplace-reference (section "github plugin source"), read 2026-11-04. So pinning is done by whoever writes the **marketplace entry**, not by a CLI flag (see C1).
- D2. `plugin.json` `version`: "Setting it pins the plugin to that version until you change it". Not pinned by this field: plugins with a `command` source, plugins from a marketplace hosted on claude.ai, and plugins loaded in place from a marketplace added from a local path. Source: https://code.claude.com/docs/en/plugins-reference (section "version"), read 2026-11-04.
- D3. A marketplace added from a local directory with a relative-path `source` is read directly from disk; edits take effect at the next session or `/reload-plugins` "with no change to the plugin's `version`". Source: https://code.claude.com/docs/en/plugin-marketplaces, read 2026-11-04.

### Claude Code docs — turning plugin auto-update off

- D4. "Plugins update automatically when the marketplace they came from has auto-update turned on." After session start Claude Code refreshes those marketplaces and updates the on-disk copies; the running session keeps what it loaded. Defaults differ per kind of marketplace: on by default for `claude-plugins-official` and other official names (with listed exceptions). Source: https://code.claude.com/docs/en/discover-plugins ("Keep plugins updated"), read 2026-11-04.
- D5. Setting `DISABLE_UPDATES=1`, `DISABLE_AUTOUPDATER=1` or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` turns the whole plugin auto-update pass off and hides the **Enable auto-update** toggle, unless `FORCE_AUTOUPDATE_PLUGINS=1` is also set. Auto-update also skips a plugin whose marketplace entry declares a `headersHelper`. Source: https://code.claude.com/docs/en/plugins/loading, read 2026-11-04.
- D6. Note: these switches stop Claude Code's *own* auto-update pass. An explicit `claude plugin update <plugin>` (as in `scripts/claude-plugin-sync.sh:54`) is a separate manual command; whether the env vars also block it was **not found** in the pages read (see Unknowns).

### Claude Code docs — limiting or disabling a SessionStart hook

- D7. `disableAllHooks: true` in a settings file turns all hooks off without removing them; `--settings '{"disableAllHooks": true}'` turns them off for one run. "There is no way to disable an individual hook while keeping it in the configuration." Outside managed settings it cannot disable managed hooks. Source: https://code.claude.com/docs/en/hooks ("Disable or remove hooks"), read 2026-11-04.
- D8. Per settings reference, `disableAllHooks` in a non-managed file disables user, project, local and **plugin** hooks; managed hooks, Agent SDK hooks and hooks of plugins force-enabled in managed `enabledPlugins` keep running. In managed settings it disables every configured hook including managed ones. Source: https://code.claude.com/docs/en/settings-reference (`disableAllHooks`), read 2026-11-04.
- D9. `allowManagedHooksOnly` (managed settings): blocks user, project, local and plugin hooks; hooks from plugins force-enabled in managed `enabledPlugins` run (matched on the full `plugin@marketplace` id); command-sourced plugins are also disabled unless `disableCommandPluginSources` is set to `false`. Sources: https://code.claude.com/docs/en/settings-reference ("What runs under allowManagedHooksOnly"), https://code.claude.com/docs/en/hooks, read 2026-11-04.
- D10. Org-level marketplace control (managed settings): `strictKnownMarketplaces` (allowlist; alias `allowedMarketplaces`) and `blockedMarketplaces` (blocklist, checked first). For `github`/`git` sources the allowlist matches `ref` exactly ("an entry with a `ref` matches only sources with that exact ref"), so an org can require a specific ref of a marketplace. `enabledPlugins` can be set in any scope and is locked when set in managed settings. Sources: https://code.claude.com/docs/en/settings-reference (strictKnownMarketplaces vs blockedMarketplaces table, "Exact matching"), https://code.claude.com/docs/en/plugins/org, read 2026-11-04.
- D11. `disableCommandPluginSources` (managed): `true` = never run marketplace-declared commands, do not install/update command-sourced plugins. Source: https://code.claude.com/docs/en/settings-reference, read 2026-11-04.
- D12. Version detection: Claude Code computes a version for every installed plugin; `claude plugin update` and background auto-update recompute it and do not replace the cached copy when it matches what `installed_plugins.json` records ("`<name>` is already at the latest version"). Source: https://code.claude.com/docs/en/plugins/loading ("Versions and updates"), read 2026-11-04.
- D13. The org page has a "Set update policy" section ("per marketplace, for the whole fleet, or per user group through release channels") and a "Turn updates off for the whole fleet" section that delivers `CLAUDE_CODE_DISABLE_OFFICIAL_MARKETPLACE_AUTOINSTALL` through the managed `env` block. Source: https://code.claude.com/docs/en/plugins/org, read 2026-11-04. The exact per-marketplace key text was not retrieved (see Unknowns).

### Git — verifying a tag before fast-forward (free, built into git)

- G1. `git verify-tag` "Validates the gpg signature created by git tag in the tag objects listed on the command line." Options include `--raw` (raw gpg status to stderr) and `-v/--verbose`. Sources: https://git-scm.com/docs/git-verify-tag, read 2026-11-04; local `man git-verify-tag` (git 2.53.0).
- G2. `git merge --verify-signatures`: "Verify that the tip commit of the side branch being merged is signed with a valid key … If the tip commit … is not signed with a valid key, the merge is aborted." Config `merge.verifySignatures = true` is equivalent. Note: this checks the **commit** signature, not the annotated tag object's signature — so a signed tag on an unsigned commit passes `verify-tag` but fails `--verify-signatures`, and vice versa. Sources: local `man git-merge` lines 180-185 and 705-706 (git 2.53.0); https://git-scm.com/docs/git-merge opened 2026-11-04 (the option text was not surfaced from the fetched copy, so the local man page is the cited text).
- G3. `gpg.format` selects the signing format: default `openpgp`; other values `x509`, `ssh`. `gpg.ssh.program` defaults to `ssh-keygen`; `gpg.x509.program` defaults to `gpgsm`. Source: https://git-scm.com/docs/git-config (`gpg.format`, `gpg.<format>.program`), read 2026-11-04.
- G4. `gpg.minTrustLevel`: if unset, signature verification for merge operations requires at least `marginal` trust. Source: https://git-scm.com/docs/git-config, read 2026-11-04.
- G5. SSH signing key distribution — `gpg.ssh.allowedSignersFile`: a file of lines "principals followed by an ssh public key". SSH has no trust levels: a key present in the file gets trust `fully`, otherwise `undefined` "and git verify-commit/tag will fail". The file "can be set to a location outside of the repository and every developer maintains their own trust store", or be generated centrally, or — for a repo that allows only signed commits — stored **in the repository itself** using a path relative to the top level. SSH CA keys (`cert-authority`) are also valid. `gpg.ssh.revocationFile` (KRL or list of revoked keys) forces trust `never`. Source: https://git-scm.com/docs/git-config, read 2026-11-04.
- G6. Key distribution needed per method (derived from G1–G5, same sources):
  - OpenPGP (`gpg.format=openpgp`): every verifying machine must have `gpg` installed and the release public key imported into its keyring, with enough trust (G4).
  - x509: `gpgsm` plus the certificate chain on each machine (G3). Details of x509 trust setup not researched.
  - SSH (`gpg.format=ssh`): `ssh-keygen` (ships with OpenSSH) plus an allowed-signers file listing the release public key(s) (G5). No keyring import.
  - In all three cases the trusted key must reach the user by a channel other than the repo being verified; an allowed-signers file shipped inside the same repo is only as trustworthy as the first clone (G5 describes in-repo storage as an option, the trust caveat is our inference).

## Options this enables (no recommendation)

All options below are free (built into Claude Code or git).

1. **Pin the plugin in the marketplace entry** with `ref` (tag) and/or `sha` (commit) on a `github` source (D1), and/or set `version` in `plugin.json` (D2). Users then get only what the entry names; moving to a new release means changing the entry.
2. **Stop calling `claude plugin update` automatically** from `scripts/claude-plugin-sync.sh:54` and leave updates to the user, or keep it but rely on a pinned entry (option 1) so "latest" = the pinned version (D12).
3. **Document user-side switches** for people who want no automatic plugin updates: `DISABLE_AUTOUPDATER=1` / `DISABLE_UPDATES=1` (D5), or the per-marketplace auto-update toggle (D4).
4. **Document user-side hook control**: `disableAllHooks: true` (all hooks, not just Helix — D7/D8) or `claude plugin disable helix@<marketplace>` (removes the plugin's hooks with the rest of the plugin; D4 page "Manage plugins from your shell"). There is no per-hook switch (D7).
5. **Document org-side control** via managed settings: `allowManagedHooksOnly` + force-enable a vetted `plugin@marketplace` in managed `enabledPlugins` (D9); `strictKnownMarketplaces` with an exact `ref` (D10); `disableCommandPluginSources` (D11).
6. **Make the SessionStart updater opt-in or check-only** (e.g. report a newer release but do not move the clone) — a code change in `scripts/helix-auto-update.sh` / `hooks/session-start`; no doc constraint found against it.
7. **Verify before fast-forward** in `scripts/helix-auto-update.sh:163`: run `git verify-tag "$tag"` (signed tags) and/or `git merge --ff-only --verify-signatures "$tag"` (signed commits) and skip the update on failure (G1, G2). Choice of signing format:
   - SSH signing + an allowed-signers file distributed to users (G3, G5) — no gpg dependency.
   - OpenPGP signing + users import the release key (G4, G6).
8. **Stop force-updating local tags** (`+refs/tags/v*:refs/tags/v*` at `scripts/helix-auto-update.sh:135`) so a re-pointed remote tag cannot silently replace a local one — a code-level option; git behaviour of `+` refspecs was not re-read in this session.

## Unknowns

- U1. Whether `DISABLE_AUTOUPDATER` / `DISABLE_UPDATES` also blocks an explicit `claude plugin update <name>` command — not found in discover-plugins, plugins/loading, settings-reference, plugins/org pages read 2026-11-04.
- U2. The exact key/field name for turning auto-update on/off **per marketplace** in settings (the org page names the section "Set update policy" but the retrieved text stopped before the key) — not found in the retrieved chunks of https://code.claude.com/docs/en/plugins/org.
- U3. Which marketplace kinds have auto-update **off** by default (the discover-plugins list was cut after the "On by default" bullet in the retrieved text). Helix's own marketplace default is therefore unverified.
- U4. Whether the `sha` field is enforced as a check (refuse if the ref does not resolve to that sha) or only used as the checkout target — the marketplace reference shows the field and example only.
- U5. Whether Claude Code verifies any signature on marketplace or plugin git content — not found in the pages searched (marketplace-reference, plugins/loading, plugins-reference, discover-plugins, plugins/org, settings-reference, hooks).
- U6. Whether GitHub-side tag protection / immutable releases are available for free on the repo — not researched (out of this ticket's page budget).
- U7. Fetching the `.md` versions of the docs with `curl` failed locally with a TLS verify error (`curl: (60) … unable to get local issuer certificate`); all doc evidence here comes from the context-mode fetcher's copy of the HTML pages.
