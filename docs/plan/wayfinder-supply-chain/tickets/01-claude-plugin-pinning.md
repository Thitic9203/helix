---
type: research
status: closed
assignee: main-thread (session 2026-11-04)
blocked_by: []
---

# Claude Code plugin pinning and update controls

## Question

What do the current Claude Code docs say about installing a plugin from a marketplace at a fixed version, tag or commit? Can `claude plugin update` be turned off or pinned, and can a SessionStart hook be limited or disabled by the user or an org policy (managed settings)? Cite each docs page with its URL and the date it was read. Also check what git offers for verifying a tag before a fast-forward (`git verify-tag`, `merge --verify-signatures`) and what it needs (key distribution). Free options only.

## Resolution

Full findings: [research/01-claude-plugin-pinning.md](../research/01-claude-plugin-pinning.md) (read 2026-11-04).

- **Pin plugin:** a pin is set only in the marketplace entry: a `github` source takes `ref` (a tag) and `sha` (a commit), and `version` in `plugin.json` pins the version. The CLI (2.1.312) has no `--version`, `--ref` or `--sha` flag on `claude plugin install` or `update`. The main thread re-checked this against the `--help` output on 2026-11-04.
- **Stop auto-update:** `DISABLE_AUTOUPDATER=1`, `DISABLE_UPDATES=1` or `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` turn it off, unless `FORCE_AUTOUPDATE_PLUGINS=1` is also set. There is also a per-marketplace toggle. Not found: whether these block a `claude plugin update` that a script runs on its own.
- **Hooks:** a user can turn off every hook with `disableAllHooks`, and there is no per-hook switch. An organisation can use `allowManagedHooksOnly`, `strictKnownMarketplaces` (which matches `ref` exactly), `blockedMarketplaces` and `disableCommandPluginSources`.
- **Verify a git tag:** `git verify-tag` checks the signature on the tag object. `merge --verify-signatures` checks the signature on the target commit, not on the tag. SSH signing needs an `allowedSignersFile` given to every user; OpenPGP needs the key imported and trusted. All options are free.
- **Open:** whether `sha` is enforced, and whether Claude Code verifies plugin content.
