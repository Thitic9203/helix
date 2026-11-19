# Can the ols-qa → Helix sync overwrite project-agnostic edits?

Type: `wayfinder:research` (AFK) · Status: closed · Blocked by: — · Assignee: Claude (main thread)

## Question

What produces the `chore(sync): pull shared skill updates from ols-qa` commits in Helix (script,
workflow, repo, trigger, frequency), which Helix paths it writes, and whether it covers
`test-data-prep-workflow` or any other Helix skill/reference. If it does, an edit made in Helix would be
overwritten and the owner's "fix at Helix upstream" answer needs revisiting.

## Resolution (2026-11-18, research subagent, re-verified by main thread)

**YES, it can overwrite.** `Thitic9203/ols-qa` `scripts/sync-skills-to-helix.sh` copies with
`cp -f "$SRC_DIR/$f" "$HELIX/$f"` (:215), commits `chore(sync): pull shared skill updates from ols-qa`
(:240) and `git push --quiet origin HEAD:main` (:257) — verified via `gh api`.
- Trigger: local `ols-qa/scripts/hooks/post-commit:22-24` on any ols-qa `main` commit touching
  `skills|references|commands/`; not scheduled; `HELIX_SYNC=0` skips one commit. PR mode exists
  (`sync-skills-pr-mode.sh`, `HELIX_SYNC_MODE=pr`).
- Writes: any file under `skills/`, `references/`, `commands/` changed in that ols-qa commit **and already
  in Helix**; new skills/commands only with `HELIX_SYNC_NEW=1`; never new references.
- test-data-prep's 3 files are byte-identical in both repos, so the next ols-qa commit touching them
  replaces a Helix edit. Direction is ols-qa → Helix only; no skip list.
- Existing practice: make the same edit in ols-qa first (`docs/sdd/token-diet/spec.md:20`).

Consequence: the owner's "fix at Helix upstream" answer must be revisited with this fact — see ticket 09.
