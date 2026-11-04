# Owner decisions on the four SDDs (2026-11-04)

These are the owner's answers to the open questions in `docs/sdd/{install-pinned-checksum,update-notify-only,retire-devenv,link-skills-no-delete}/`. Each answer replaces the draft default in that SDD.

| SDD | Question | Decision |
|---|---|---|
| install-pinned-checksum | Q1: should `install.sh` check out the named tag instead of `main`? | **Yes, check out the tag.** |
| install-pinned-checksum | Q2: should the install block in supported-agents and the wiki link to README, or copy it? | **Link to README's block.** |
| install-pinned-checksum | Q3: who bumps the tag named in the docs? | **`sync-version.sh` bumps it on every release (option B), with `--check`.** |
| update-notify-only | Q1: keep the `HELIX_AUTO_UPDATE*` variable names? | **Keep them.** |
| update-notify-only | Q2: add a `/helix-update` slash command? | **No.** |
| update-notify-only | Q3: where does the "new version" line show? | **In the agent's context only.** |
| update-notify-only Q4 + retire-devenv Q5 | When is `SECURITY-NOTICE.md` updated? | **With the fixed release (SPEC R5).** |
| retire-devenv | Q1: how is `defaultMode` restored? | **Option A, from the backup:** remove it only if the pre-opt-in backup had no `defaultMode`. |
| retire-devenv | Q2: does a no-argument run (the old updater's last call) undo automatically? | **Yes, undo automatically.** |
| retire-devenv | Q3: delete `~/.helix/.devenv-notice-count`? | **Yes.** |
| retire-devenv Q4 + link-skills-no-delete Q3 | What should `helix-doctor` warn about? | **Both:** devenv leftovers and skill-name clashes. |
| link-skills-no-delete | Q1: are the plugin-cache `rm -rf` lines (`install.sh:45-49`, `setup.sh:21-25`) in scope? | **Yes.** |
| link-skills-no-delete | Q2: does a link into an old cache or old clone count as Helix-owned? | **No. Leave it and warn.** |

Next gate (ADLC step 3): the owner approves the plan before any code changes.
