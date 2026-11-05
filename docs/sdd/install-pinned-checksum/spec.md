# Spec — pin the installer to a release tag and check its SHA-256

## Problem

The only documented install pipes the installer from `main` straight into bash. Nothing is pinned
and nothing is checked, so whatever `main` holds at that second runs on the user's machine.

Evidence (state of `origin/main` at a3bfd92, re-grepped 2026-11-05 with
`git grep -n '| *bash' -- README.md docs scripts .github`, `docs/sdd` and `docs/plan` left out):

| Place | What it says today | Problem |
|-------|--------------------|---------|
| `scripts/install.sh:5`, `:8` | usage `curl -sL https://raw.githubusercontent.com/<owner>/helix/main/scripts/install.sh \| bash` | runs `main`, no pin, no check |
| `README.md:59`, `:203` | same `curl … \| bash` line | same |
| `docs/supported-agents.md:8`, `docs/wiki/Home.md:51` | same line | same |
| `.github/workflows/version.yml:166` | every release's notes print the same `curl … \| bash` line | each release advertises the unpinned path |
| `.github/workflows/version.yml:168-170` | `gh release create "$TAG" --title … --notes-file …` | no files attached, so no SHA-256 is published |
| `scripts/install.sh:24-31` | existing clone: `git pull origin main`; new clone: default branch | even a checked installer installs `main`, not the release |
| `scripts/install.sh:82` | the `Update:` hint already names `helix-auto-update.sh` (done by `docs/sdd/update-notify-only`); no `git pull` hint is left | nothing to change |
| `scripts/helix-doctor.sh:24` | "run: curl -sL .../install.sh \| bash" (unchanged on `a3bfd92`) | points users back to the unpinned path |
| `install.sh`, `setup.sh` | a search for sha256, checksum or shasum returned 0 hits (MAP.md:15) | no check exists |

Decision: SPEC.md R1 (`docs/plan/wayfinder-supply-chain/SPEC.md:7-8`) and
[ticket 04](../../plan/wayfinder-supply-chain/tickets/04-install-path.md) "Resolution" (`:14-16`),
owner, 2026-11-04 — pinned release tag plus SHA-256; `curl … | bash` from `main` removed.

## Scope

In: `scripts/install.sh`, `.github/workflows/version.yml` (publish job, release step `:143-171`),
`scripts/sync-version.sh` (rewrites the tag named in the README install block, Q3 = B), `README.md`,
`docs/supported-agents.md`, `docs/wiki/Home.md`, `scripts/helix-doctor.sh:24`, a new
`scripts/release-install-assets.sh`, new tests under `scripts/tests/`.

Out: `helix-auto-update.sh` and `hooks/` (that is `docs/sdd/update-notify-only`), signed tags or
signed artifacts (SPEC.md:31 follow-up "Release integrity"), `link-skills.sh` (SPEC R4),
`helix-setup-devenv.sh` (SPEC R3), the plugin-cache link handling at `install.sh:45-48`
(already changed by `docs/sdd/link-skills-no-delete`), Claude Code's own marketplace install
(`claude plugin install` has no version flag — research 01 C1).

Both `install.sh` and `.github/workflows/` are on the repo's "ask first" list (`CLAUDE.md:56-57`).
The owner's SPEC.md approval covers the change in principle; this spec, plan and tasks are what the
owner reviews before code starts (global rule 27).

## Roles

- **User** — runs the documented install on macOS or Linux.
- **Release job** — `publish` job in `.github/workflows/version.yml:70-171`, the only place that
  creates `vX.Y.Z` releases (`:4` "no manual `gh release create`").
- **Contributor** — clones by hand (README "Manual install (contributors)", `README.md:226`); not
  changed here.

## Rules

- **R1** — When the release job creates a release, it must attach that commit's `scripts/install.sh`
  and a file `install.sh.sha256` holding the SHA-256 of that same file, as one line
  `<64 hex>  install.sh`. Source: SPEC.md:7 ("the SHA-256 published with that release");
  `version.yml:168-170` attaches nothing today.
- **R2** — When the release job writes release notes, it must print the pinned install of that
  release and must not print a `curl … | bash` line. Source: SPEC.md:7; `version.yml:166`.
- **R3** — When a user follows the documented install (the single block in README.md; `docs/supported-agents.md`
  and `docs/wiki/Home.md` link to it and do not copy it, Q2), the steps must name one release tag, download `install.sh` and
  `install.sh.sha256` of that tag, check the hash, and run the installer only if the check passed.
  Source: SPEC.md:7; the doc lines in the table above.
- **R4** — When the hash check fails, or the hash file is missing or fails to download, the install
  must stop with a non-zero exit before `install.sh` runs and must write nothing under `$HOME`
  (the two downloaded files land in the working directory only). Source: SPEC.md:8 Done when
  ("a tampered file … non-zero exit with nothing written").
- **R5** — When anyone greps README.md, `docs/` (outside `docs/sdd/` and `docs/plan/`, which quote
  the old line as evidence), `scripts/`, `.github/` or the release notes, they must find no
  `| bash` line that reads from `main`. Source: SPEC.md:7-8 ("README has no `| bash` from `main`").
- **R6** — When `install.sh` runs with a release tag, it must clone, or move the existing clone,
  to that tag, not to `main`. Source: SPEC.md:7 title ("Install is pinned"); `install.sh:24-31`
  installs `main` today. Owner decision Q1 = yes (2026-11-04). When `HELIX_TAG` is unset, `install.sh` does not guess a tag: with no clone it stops and points to the README block; with an existing clone it re-links that clone as it is and runs no git move. A `HELIX_TAG` that is not `vN.N.N` is refused.
- **R7** — When `install.sh` runs on an existing clone that has local changes or sits on a commit
  that is not an ancestor of the tag, it must stop and print why; it must not reset, stash or
  discard anything. Source: global rule 5 (never damage existing work);
  `helix-auto-update.sh:163-164` already refuses a diverged clone the same way. Applies because Q1 = yes.
- **R8** — When `install.sh` or `helix-doctor.sh` prints how to install or update, it must not print
  a `curl … | bash` hint or a `git pull` of `main`. Source: `helix-doctor.sh:24`, `install.sh:5`, `:8`;
  SPEC.md:7. The update hint (`install.sh:82`) already names the update command of
  `docs/sdd/update-notify-only` R6 and stays.
- **R9** — When the check runs, it must use only tools already on macOS and Linux (`shasum -a 256`
  or `sha256sum`) and GitHub release downloads; no new dependency and no paid service. Source:
  global rule 3; SPEC.md:35 "Cost and repos"; `README.md:270` already lists `shasum`.
- **R10** — When the suite runs, a test under `scripts/tests/` must run the documented install block
  against a local fake release and prove a tampered `install.sh` gives a non-zero exit with nothing
  written, and an untouched one passes the check. Source: SPEC.md:8 Done when;
  `docs/CONTRIBUTING.md:133` (add a `*.test.sh` when you change a script).

## Edge cases

- Releases created before this change have no assets. The docs must name a tag created after it
  (R3). The first such tag only exists after the publish job runs on the merge commit.
- README's version line is bumped and pushed to `main` (`version.yml:92-97`, push `:137-141`) before
  the release exists (`:143-171`). If the install block names the tag, there is a window where
  README names a tag whose release is not created yet. See plan "What may break".
- The release step exits early when the release already exists (`version.yml:151-154`); a re-run
  never adds assets to an old release.
- `shasum` exists but `sha256sum` does not (default macOS), and the reverse (minimal Linux). The
  check must work with either (R9).
- A `.sha256` file holding a different file name, extra lines or CRLF must fail, not pass (R4).
- The download itself fails (offline, 404): `curl -f` must make the block stop before the check
  (R4).
- Accepted limit: the hash sits next to the code on GitHub; it catches a wrong or altered file, not
  a compromised upstream (SPEC.md:24 "Accepted limits", research 01). The repo that `install.sh`
  then clones is pinned by tag (R6), not hashed.

## Owner decisions (2026-11-04, `docs/plan/wayfinder-supply-chain/owner-decisions-2026-11-04.md`)

- **Q1 = yes** — `install.sh` checks out the named tag instead of `main` (R6, R7).
- **Q2 = link** — the install block lives only in README; `docs/supported-agents.md` and
  `docs/wiki/Home.md` link to it.
- **Q3 = B** — `sync-version.sh` rewrites the tag named in README's install block on every release,
  and `--check` fails when it does not match VERSION.

## Done when

- `git grep -n '| *bash' -- README.md docs scripts .github ':!docs/sdd' ':!docs/plan'` shows no line reading from `main`.
- A release created after merge lists `install.sh` and `install.sh.sha256`, and `shasum -a 256 -c install.sh.sha256` passes on the downloaded pair.
- The new test exits 1 on a tampered `install.sh` with an empty fake `$HOME`, and 0 on the real one.
- `bash scripts/tests/run.sh` and `bash scripts/helix-regression-check.sh` pass on the branch.
