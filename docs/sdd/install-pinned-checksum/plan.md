# Plan — install-pinned-checksum

Owner decisions of 2026-11-04 are applied (Q1 yes, Q2 link, Q3 option B); paths re-grepped on `origin/main` a3bfd92.

## Files

| File | Today (origin/main a3bfd92) | Change | Rule |
|------|-----------------------------|--------|------|
| `.github/workflows/version.yml` | `:143-171` "Create GitHub Release if tag missing": notes at `:157-167`, `gh release create "$TAG" --title … --notes-file …` at `:168-170`, no assets, no `--target` | before `gh release create`: `bash scripts/release-install-assets.sh "$DIST"` (`DIST="$(mktemp -d)"`); then `gh release create "$TAG" "$DIST/install.sh" "$DIST/install.sh.sha256" --target "$(git rev-parse HEAD)" --title … --notes-file …`; replace `:166` with the pinned block for `$TAG` | R1, R2, R5 |
| `scripts/release-install-assets.sh` (new) | — | `<out-dir>`: copies `scripts/install.sh` there and writes `install.sh.sha256` with `sha256sum`, falling back to `shasum -a 256`; then runs the same `-c` check on its own output and exits non-zero if it fails. Kept out of the YAML so the hashing is testable outside CI | R1, R9 |
| `scripts/install.sh` | usage `:4-9` is `curl … \| bash`; `:24-31` clones/pulls `main`; `:82` update hint already names `helix-auto-update.sh` (kept) | usage comment shows the pinned block; read `HELIX_TAG` (set by the block); clone with `--branch "$HELIX_TAG"` or, on an existing clone, `fetch` the tag and `merge --ff-only` to it, refusing on local changes or divergence; the `Update:` hint (`:82`) stays | R5–R8 |
| `README.md` | `:59` and `:203` `curl … \| bash`; `:217` "never ran `curl …/install.sh`" | one pinned block under "Install (one-time)" (`:54`); `:203` links to it; `:217` wording | R3, R5 |
| `docs/supported-agents.md` | `:8` `curl … \| bash` | link to README's install section (Q2: no copy) | R3, R5 |
| `docs/wiki/Home.md` | `:51` `curl … \| bash` | link to README's install section (Q2: no copy) | R3, R5 |
| `scripts/helix-doctor.sh` | `:24` "run: curl -sL .../install.sh \| bash" | point to README install section | R8 |
| `scripts/sync-version.sh` | `:65-81` rewrites the `**Version: X**` line only; `--check` reads it at `:38-43` | also rewrite the tag in the README install block, and fail `--check` (same style as `:39-40`) if it differs from VERSION (option B, decided Q3) | R3 |
| `scripts/tests/install-checksum.test.sh` (new) | — | extracts the install block from README, points its base URL at a `file://` fake release, runs it from a temp working dir with a throwaway `HOME` | R4, R10 |
| `scripts/tests/no-pipe-from-main.test.sh` (new, or a case in the test above) | — | `git grep` over README.md, `docs/` (minus `docs/sdd`, `docs/plan`), `scripts/`, `.github/` for `\| bash` with `/main/` must find nothing; the pattern is built from parts so the test file does not match itself | R5 |

## How the SHA-256 gets published

The release job already exists; no new workflow, no new trigger. Order in the `publish` job
(`.github/workflows/version.yml:70-171`, `ubuntu-latest`):

```
bump VERSION + README version line (:79-103, bump at :92, commit :96-97)
→ same checks as pr-check (:105-135) → push bump to main (:137-141)
→ "Create GitHub Release if tag missing" (:143-171):
     skip if release exists (:151-154)
     notes (:155-167)                       ← :166 becomes the pinned block for $TAG
     NEW: bash scripts/release-install-assets.sh "$DIST"
     gh release create "$TAG" "$DIST/install.sh" "$DIST/install.sh.sha256" \
       --target "$(git rev-parse HEAD)" --title … --notes-file …   (:168-170)
```

- `gh release create <tag> <files>…` uploads the files as release assets in the same call; `gh` is
  already used here (`:151`, `:168`) with the job's `GH_TOKEN` (`:144-145`). No new secret.
- `--target "$(git rev-parse HEAD)"` makes the tag point at the commit whose `scripts/install.sh`
  was hashed. Today the tag is created by `gh` with no `--target`, i.e. at the default branch tip,
  which can differ from the checked-out commit if another push lands between `:141` and `:168`.
- Asset URL users download: `https://github.com/<owner>/helix/releases/download/vX.Y.Z/install.sh`
  (and `…/install.sh.sha256`).

`install.sh.sha256` holds one line, `<64 hex>  install.sh`. GNU `sha256sum -c` and Perl
`shasum -a 256 -c` both read that format.

User (the documented block; shape, not final text):

```bash
HELIX_TAG=vX.Y.Z
base="https://github.com/<owner>/helix/releases/download/$HELIX_TAG"
curl -fsSLO "$base/install.sh" && curl -fsSLO "$base/install.sh.sha256" \
  && { if command -v sha256sum >/dev/null; then sha256sum -c install.sh.sha256; else shasum -a 256 -c install.sh.sha256; fi; } \
  && HELIX_TAG="$HELIX_TAG" bash install.sh
```

Every step is joined by `&&`, so a failed download or check stops before `bash install.sh`
(R4). `install.sh` then clones the same tag (R6).

## Libraries / cost

`curl`, `sha256sum` (GNU coreutils; not yet checked on the `ubuntu-latest` runner — T4's first CI
run confirms it, and the script falls back to `shasum`), `shasum` (ships with macOS; `README.md:270`
already lists it), `git`, `gh` (already used at `version.yml:151`, `:168`). GitHub release assets
are free for public repos. No new dependency, no paid service, no other repo touched. New cost: none.

## Options weighed

1. **Two-step download, review, run (no hash)** — ticket 04 option; leaves the check to the user's
   eyes. Rejected by the owner (ticket 04 "Resolution", `:14-16`).
2. **`claude plugin install` at a pinned version** — not possible: no `--version`/`--ref` flag
   (research 01 C1). Rejected.
3. **Hash file next to the installer (chosen, ticket 04)**. Sub-choices:
   - A. Docs name `releases/latest/download/…` — never stale, but not "a named release tag" (SPEC.md:7). Rejected.
   - B. Docs name `vX.Y.Z`, rewritten by `sync-version.sh` with VERSION (Q3, decided by the owner) — at most
     one release behind for the window below; `--check` stops drift.
   - C. Docs name a tag a person bumps by hand — fewer moving parts, but docs go stale.
4. **Hash printed in README instead of a release asset** — README is on `main`, the same place an
   attacker would edit; also the hash is only known after the release job runs. Rejected.

## What may break

- **Window between bump and release** (option B): README on `main` names `vX.Y.Z` from the bump
  commit (`version.yml:96-97`, pushed at `:141`); the release is created later in the same job
  (`:143-171`). If the job fails between, README names a tag with no release and the documented
  block fails at `curl -f` (safe: nothing runs). Mitigation: a failed publish job is already a red
  build the owner sees; the test only checks the block's shape.
- **Release already exists** (`:151-154` skips): a release made before this change, or a re-run,
  gets no assets. The docs must only name tags made after merge.
- **`--target` change**: the tag moves from "default branch tip" to "checked-out HEAD". On a normal
  run these are the same commit; they differ only when a push races the job.
- **Existing installs**: re-running the new `install.sh` on a clone that sits on `main` ahead of the
  tag would refuse (R7) instead of pulling. Users on a clone with local edits get a message, not a
  reset. Clones made by older installers keep working; nothing removes them.
- **Overlap with `docs/sdd/update-notify-only`**: its R13 also edits `scripts/install.sh:84` (and
  `:60`). Whichever lands second rebases; both point the hint at the same update command.
- **`scripts/tests/auto-update.test.sh`**: not touched by this change (it tests `helix-auto-update.sh`).
- **`scripts/tests/version.test.sh`**: has 0 lines mentioning README today (`grep -c README`); if
  `sync-version.sh` gains the README tag rewrite, add cases there for the install block (T5).
- **`helix-doctor.sh`**: only the hint text at `:24` changes; `scripts/tests/doctor-stale.test.sh`
  runs the doctor but does not assert on that line.
- **README / wiki / supported-agents**: the install snippet grows from one line to five. The block exists once (README); `docs/supported-agents.md` and `docs/wiki/Home.md` link to it (Q2). If `docs/wiki/` is also published to the GitHub wiki by hand, that copy gets the same link edit.
- **ols-qa**: none of these scripts are in ols-qa (SPEC.md follow-up note); helix-sync only if a
  shared `references/` or `skills/` file changes, which this plan does not.
- **CI workflow change** is on the "ask first" list (`CLAUDE.md:57`); the PR must say so.
