# Spec — retire helix-setup-devenv, with a full undo

## Problem

`scripts/helix-setup-devenv.sh` changes the user's **global** Claude Code setup: it merges 45 Bash
allowlist rules into `~/.claude/settings.json`, sets `defaultMode: acceptEdits` if none is set, and
writes a "Bias toward action — do, ask less" block into `~/.claude/CLAUDE.md`. Once a user opts in,
`helix-auto-update.sh` re-runs the newly fetched copy of the script after every update. The owner
decided on 2026-11-04 to retire it and to give opted-in machines a full undo
(`docs/plan/wayfinder-supply-chain/SPEC.md` R3, ticket 05).

Evidence (worktree at `origin/main` e9955a9, re-checked 2026-11-04):

| Place | What it does today |
|-------|--------------------|
| `scripts/helix-setup-devenv.sh:29-43` | the allowlist: 45 `Bash(...)` rules, including `Bash(npx *)`, `Bash(node *)`, `Bash(python3 *)`, `Bash(gh api *)`, `Bash(bash scripts/*)` |
| `scripts/helix-setup-devenv.sh:88-92` | merge: `defaultMode = (defaultMode // "acceptEdits")`; `allow = (allow + rules \| unique)` — `unique` also sorts and dedupes the user's own rules |
| `scripts/helix-setup-devenv.sh:74-79, :85, :112` | a timestamped backup `<file>.helix-bak.<YYYYmmddHHMMSS>` before every write |
| `scripts/helix-setup-devenv.sh:84, :111` | creates `settings.json` as `{}` / an empty `CLAUDE.md` if missing, **before** the backup |
| `scripts/helix-setup-devenv.sh:96-107, :160-167` | `--uninstall`: removes the 45 rules and the block, deletes the marker; leaves `defaultMode` (:106, :166) |
| `scripts/helix-setup-devenv.sh:172` | marker `~/.helix/.devenv-opted-in` holds only an epoch time — nothing records whether Helix set `defaultMode` |
| `scripts/helix-auto-update.sh:223-228` | after an update, if the marker exists, runs the just-fetched `helix-setup-devenv.sh` |
| `hooks/session-start:25-41` (+ `${devenv_tip}` at :56) | tells the agent to suggest running the script, first 3 sessions, on every machine not opted in |

Every allowlist rule any Helix version shipped: `git log --all --follow -- scripts/helix-setup-devenv.sh`
lists one commit, 8894507 (2026-05-31); the file's blob at 8894507 and at e9955a9 is the same
(`git rev-parse <rev>:scripts/helix-setup-devenv.sh` = c925107 for both). So the 45 rules at `:29-43` are the complete list ever shipped (123 release tags contain
8894507). `git log --all -S'permissions.allow'` finds no other script that wrote user allowlist rules.

## Scope

In: `scripts/helix-setup-devenv.sh`, `scripts/helix-auto-update.sh:223-228`, `hooks/session-start:25-41, :56`,
a new test under `scripts/tests/`, a test fixture, and the docs that tell people to run the script:
`README.md:241-242, :300`, `docs/CONTRIBUTING.md:15-31`, `docs/wiki/Home.md:182`.

Out: the repo's own `.claude/settings.json` ("Layer 1", project-scoped, applies only inside a Helix
clone — not a global write); the rest of the auto-update redesign (SPEC R2, its own SDD); the team
notice (SPEC R5); deleting `*.helix-bak.*` backups.

## Roles

- **Opted-in user** — has the marker and/or Helix rules, block or `defaultMode` from an earlier run.
- **Partly undone user** — ran today's `--uninstall`: marker gone, `defaultMode` still `acceptEdits`.
- **Never opted in** — must see no change at all.

## Rules

- **R1** — When `helix-setup-devenv.sh` runs without `--uninstall`, it must not add any allowlist
  rule, must not set `defaultMode`, must not write `~/.claude/CLAUDE.md`, and must not create the
  marker. It prints that the script is retired and how to undo, then exits 0. Source: SPEC R3
  ("no longer adds anything").
- **R2** — When the undo (`--uninstall`) runs, it must remove from `permissions.allow` every rule in
  the shipped list (`:29-43`, the only list ever shipped — see Evidence) that Helix added. A rule
  counts as "added by Helix" unless it is already in the oldest `settings.json.helix-bak.*`
  (the state before the first opt-in). It prints each listed rule it keeps for that reason.
  Source: SPEC R3 bullet 1; `:85` backup runs before the merge.
- **R3** — The undo must not remove, add or change any other key or any allowlist entry not covered
  by R2. Source: SPEC R3 Done-when ("byte-equal to the pre-opt-in state"); `:102` comment
  ("leave user's own rules and other settings intact").
- **R4** — When, after R2 and R5, the settings are equal to the oldest backup (compared with
  `jq -S`, allow compared as a sorted set because `:91` sorted it), the undo must write the oldest
  backup's bytes back, so order and formatting return exactly. Otherwise it edits in place with
  `jq` and prints that formatting/order of the user's own rules could not be restored.
  Source: SPEC R3 Done-when (byte-equal); `:91` (`unique` sorts).
- **R5** — The undo must remove `permissions.defaultMode` only when Helix set it: the current value
  is `"acceptEdits"` **and** the oldest settings backup has no `permissions.defaultMode`. If there is
  no backup, it must leave `defaultMode` alone and print one line saying how to check it by hand.
  Source: SPEC R3 bullet 3; `:90` sets it only when unset; `:172` records nothing — see Q1.
- **R6** — The undo must remove the `HELIX-DEVENV:START…END` block from `~/.claude/CLAUDE.md` and
  leave every other byte as it was before opt-in; when the rest equals the oldest
  `CLAUDE.md.helix-bak.*` after trimming the newlines `:129-130` added, it writes that backup's bytes.
  Source: SPEC R3 bullet 2; `:26-27` markers; `:129-130` separator logic.
- **R7** — The undo must delete `~/.helix/.devenv-opted-in`. Source: SPEC R3 bullet 4; `:25`, `:165`.
- **R8** — The undo must work without the marker (partly undone users) and must be safe to run
  twice: a second run writes no file at all (no edit, no new backup). Source: research 02:58 (today's `--uninstall` leaves
  `defaultMode`); `:5` "idempotent".
- **R9** — Before any write, the undo must back up the file it changes (as `:74-79` does today) and
  must not delete existing backups. Source: `:166` ("backups kept").
- **R10** — When an update finishes, `helix-auto-update.sh` must not run `helix-setup-devenv.sh`.
  Source: SPEC R3; `helix-auto-update.sh:223-228`.
- **R11** — When the SessionStart hook runs, its output must not contain `helix-setup-devenv`.
  Source: SPEC R3 Done-when; `hooks/session-start:25-41`.
- **R12** — README, CONTRIBUTING and the wiki must not tell anyone to opt in; they show only the undo
  command. Source: SPEC R3 (retired); `README.md:241-242, :300`, `docs/CONTRIBUTING.md:15-31`,
  `docs/wiki/Home.md:182`.

## Edge cases

- `settings.json` or `CLAUDE.md` did not exist before opt-in: `:84`/`:111` created it, then backed it
  up, so the oldest backup is `{}` / empty. R4/R6 restore those bytes; the file is not deleted (we
  cannot tell "missing" from "empty").
- The user had one of the 45 rules before opt-in (for example `Bash(git status)`): it is in the oldest
  backup, so R2 keeps it.
- The user changed settings after opt-in (new rule, other key): R4 falls back to an in-place edit;
  their change stays.
- The user set `defaultMode` themselves after opt-in to `acceptEdits`: indistinguishable from Helix's
  value when the backup has none — R5 removes it (accepted limit, see Q1).
- No backups (user deleted them): R2 removes all 45 and prints each removed rule; R5 leaves
  `defaultMode`; R6 removes only the block.
- `CLAUDE_CONFIG_DIR` / `HELIX_STATE_DIR` set (`:21, :24`): the undo uses the same overrides.
- `jq` missing: the undo stops with the existing message (`:66-72`) and changes nothing.
- Two runs of the old script in the same second: `:77` names the backup by second, so the second
  `cp` overwrites the first backup with an already-merged file. The "oldest backup" then already
  holds the 45 rules, and R2 would keep them. Cannot be detected from disk; R2 prints the rules it
  kept because they were in the backup, so the user can see it.
- Opted in, ran today's `--uninstall`, opted in again later: the oldest backup is from before the
  first opt-in and may be stale. R4 then falls back to an in-place edit; R2/R5 still use it.
- The user added one of the 45 rules themselves after opt-in: indistinguishable from Helix's copy;
  R2 removes it and prints it (same limit as Q1).
- `SECURITY-NOTICE.md:41` already tells opted-in users to run `--uninstall`. Anyone who runs it
  before this change ships gets today's partial undo (`defaultMode` kept). R8 lets them run the new
  undo again — see Q5.
- Machines still on an old `helix-auto-update.sh`: after fetching the release with this change, the old
  updater runs the new script with **no arguments** (`:227`). By R1 that call changes nothing — see Q2.

## Open questions for the owner

- **Q1** — `defaultMode`: the current script records nothing about who set it (`:90`, `:172`). Is the
  backup-based check in R5 acceptable, including its limit (a user who set `acceptEdits` themselves
  after opt-in, with no `defaultMode` before, loses it)? No better signal exists on disk today.
- **Q2** — Should opted-in machines be undone automatically? Option A (this draft): R1 makes a no-arg
  run a no-op, so nothing changes until the user runs `--uninstall` (told by the team notice, SPEC R5).
  Option B: a no-arg run performs the undo; then the old updater (`:227`) undoes every opted-in
  machine at its next update with no prompt.
- **Q3** — Should the undo also delete `~/.helix/.devenv-notice-count` (written by
  `hooks/session-start:38-39`)? It is Helix state, not named in SPEC R3. Draft: leave it.

- **Q4** — `scripts/helix-doctor.sh` has no devenv check today (`grep -n -i devenv` → 0 lines).
  Should doctor warn when it finds devenv residue (marker, block, or Helix rules) and print the undo
  command? Draft: no change (adding is outside SPEC R3).
- **Q5** — `SECURITY-NOTICE.md:41` asks users to run `--uninstall` now. Should it say to update
  Helix first (to the release with this change), or to run it again after updating?

## Done when

- `hooks/session-start` output, run on a fake `$HOME`, contains no `helix-setup-devenv`.
- On a fake `$HOME` with the old opt-in applied (no later edits), `--uninstall` leaves `settings.json` and `CLAUDE.md` byte-equal to their pre-opt-in copies and the marker gone.
- A pre-existing user rule that is also in the list survives the undo.
- `defaultMode` set by the user before opt-in survives; one set by Helix is removed.
- A no-arg run on a clean fake `$HOME` creates no file under `.claude/` or `.helix/`.
- `grep -n devenv scripts/helix-auto-update.sh` returns nothing.
- With no backups, the undo removes all 45 rules, leaves `defaultMode`, and prints both facts.
- A second `--uninstall` run leaves every file under the fake `$HOME` byte-equal and creates none.
- `bash scripts/tests/run.sh` passes.
