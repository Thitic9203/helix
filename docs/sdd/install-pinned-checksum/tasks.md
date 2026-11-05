# Tasks — install-pinned-checksum

Existing test files named below were checked on origin/main a3bfd92 (`ls scripts/tests/`):
`run.sh`, `lib.sh`, `version.test.sh`, `doctor-stale.test.sh`, `auto-update.test.sh` exist;
`install-checksum.test.sh`, `no-pipe-from-main.test.sh` and `scripts/release-install-assets.sh`
are new. `scripts/helix-regression-check.sh` exists.

| # | Task | Rule | Failing test first | Done when |
|---|------|------|--------------------|-----------|
| T1 | New `scripts/tests/install-checksum.test.sh`: build a fake release dir (`install.sh` + `install.sh.sha256`), extract README's install block, swap its base URL for `file://<dir>`, run it from a temp working dir with an empty throwaway `HOME` | R4, R10 | the test itself fails today: README has no pinned block to extract | test file is picked up by `scripts/tests/run.sh` and fails for that reason only |
| T2 | Pinned block in README "Install (one-time)" (`README.md:54`) | R3, R4 | T1 cases: tampered `install.sh` → exit ≠ 0 and `HOME` still empty; missing `.sha256` → exit ≠ 0; `.sha256` with CRLF or a wrong file name → exit ≠ 0; untouched → check passes | T1 green for every case, once with `sha256sum` and once with only `shasum` on `PATH` |
| T3 | No `\| bash` from `main` anywhere in scope | R5 | new `no-pipe-from-main.test.sh` (or a T1 case): `git grep` for `/main/` + `\| bash` in README.md, `docs/` (minus `docs/sdd`, `docs/plan`), `scripts/`, `.github/` → finds `README.md:59` today | grep finds nothing; `README.md:203`, `:217`, `docs/supported-agents.md:8`, `docs/wiki/Home.md:51`, `install.sh:5`, `:8`, `version.yml:166` updated |
| T4 | New `scripts/release-install-assets.sh`; release step calls it and attaches both files with `--target "$(git rev-parse HEAD)"`; notes print the pinned block | R1, R2, R9 | test (in T1 file): run `release-install-assets.sh` on a temp dir → `-c` check passes; flip one byte of the copied `install.sh` → check fails | first release after merge lists both assets; `shasum -a 256 -c install.sh.sha256` passes on the downloaded pair |
| T5 | `sync-version.sh` rewrites the tag in the README block; `--check` fails on mismatch (Q3 = B, decided) | R3 | new case in `version.test.sh`: README block names `v0.0.1` while VERSION is `1.0.0` → `sync-version.sh --check` exits 1 | `--check` passes on the branch after sync; existing `version.test.sh` cases still green |
| T6 | `install.sh` clones / fast-forwards to `HELIX_TAG`, refuses on local changes or divergence (Q1 = yes, decided) | R6, R7 | test (in T1 file): local bare origin with `v1.0.0` and a later unreleased commit on `main` → clone ends at `v1.0.0`; clone with a local commit → exit ≠ 0, commit still there; clone with an uncommitted edit → exit ≠ 0, edit still there | all three cases green |
| T7 | Hints: `helix-doctor.sh:24` (the `install.sh:82` update hint already names the update command and stays) | R8 | test: grep `helix-doctor.sh` and `install.sh` for `curl` + `\| bash` and for `git pull` → finds the doctor line today | hint points to README install; `doctor-stale.test.sh` still green |
| T8 | Full suite | all | — | `bash scripts/tests/run.sh` and `bash scripts/helix-regression-check.sh` exit 0 on the branch |

Commits reference `Spec: docs/sdd/install-pinned-checksum R<n>`. Branch: `fix/install-pinned-checksum`.
T4 touches `.github/workflows/` and T6 touches `install.sh`: both are "ask first" (`CLAUDE.md:56-57`);
start them only after the owner approves this plan.
