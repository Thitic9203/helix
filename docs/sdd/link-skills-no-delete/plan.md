# Plan — link-skills-no-delete

Spec: [spec.md](spec.md). Base: `origin/main` 56def8b.

## Files touched

| File | Change | Rules |
|------|--------|-------|
| `scripts/link-skills.sh:10` | add `REPO_P="$(cd "$REPO" && pwd -P)"` next to the logical `REPO` (both prefixes count as the clone) | R4 |
| `scripts/link-skills.sh:12-56` (`link_into`) | replace `:43-45` with a classifier `is_helix_link <target> <name> <relative>`; branch: no entry → link (R5); Helix link → `ln -sfn` (R4); else → `warn_clash` + `continue` (R1, R3) | R1, R3–R6 |
| `scripts/link-skills.sh` (new helper) | `warn_clash <label> <name> <path> <kind>` → stderr: `skip (<label>) <name>: <path> is your own <folder\|file\|symlink -> X>, not a Helix link. Rename or remove it, then run: bash <REPO>/scripts/link-skills.sh`; increment a counter | R2, R10 |
| `scripts/link-skills.sh:107-109` | when the counter > 0, print `N skill(s) skipped because of name clashes (see above)` to stderr; exit 0 | R8 |
| `scripts/lib/helix-owned.sh` (new) | `helix_is_skill_link`, `helix_link_plugin_cache` | R3, R4, R11, R12 |
| `scripts/install.sh:45-50`, `scripts/setup.sh:21-26` | replace the `rm -rf` loop and `ln -sfn` with `helix_link_plugin_cache` | R11, R12 |
| `scripts/helix-doctor.sh` `check_dest` | warn per clash using `helix_is_skill_link`; a clash is not counted as linked | R13 |
| `scripts/tests/link-skills.test.sh` | add clash, symlink, broken-link, idempotence, workspace and exit-code cases (tasks T1–T7) | R1–R10 |
| `scripts/tests/plugin-cache.test.sh` (new), `scripts/tests/doctor-clash.test.sh` (new) | tasks T9, T10 | R11–R13 |

The counter must survive the `find … | while` pipe at `:33-37` (a subshell). Write clash lines
to a temp file (`mktemp`, removed by `trap`) or switch the loop to `while … done < <(find …)`
(bash process substitution, already used in `helix-doctor.sh:50`). Choice: process substitution
— no temp file, same pattern the repo already uses.

## Classifier (raw target, never resolved)

```
t="$(readlink "$target")"            # works on broken links
relative=1 → helix iff t == "../../skills/$name"
any mode   → helix iff t == "$REPO"/skills/* or t == "$REPO_P"/skills/*, and basename(t) == name
```

The classifier lives in a new shared file `scripts/lib/helix-owned.sh` (`helix_is_skill_link`),
sourced by `link-skills.sh` and `helix-doctor.sh` so both decide "Helix link" the same way. The same
file holds `helix_link_plugin_cache <cache_base> <version> <clone>` used by `install.sh` and
`setup.sh` (R11, R12): for each entry under `<cache_base>`, `rm -f` it only if it is a symlink whose
raw target is `<clone>` or its `pwd -P`; otherwise warn on stderr. Then link `<version>` only when
that path is free. The old loop `for e in "$CACHE_BASE"/*/; rm -rf "$e"` also followed a version
symlink's trailing `/`, which can delete through the link into the clone; `rm -f` on the link path
without a slash cannot.

`readlink -f` (`:22`) is not used for entries: it fails on broken links and differs between
BSD and GNU. Plain `readlink` exists on macOS and Linux.

## Options weighed

| Option | For | Against | Pick |
|--------|-----|---------|------|
| Skip + warn | owner decision (ticket 07); never loses data | user skill shadows Helix skill until resolved | **yes** |
| Move to `<name>.helix-bak.<ts>` | Helix skill gets linked | owner rejected (ticket 07 offered it); still mutates user data | no |
| Abort install | loud | owner rejected; one clash blocks all agents | no |
| Classify by resolved path (`readlink -f`) | handles `..` in targets | broken Helix links look foreign; BSD/GNU differences | no |
| Ownership marker file next to each link | exact | a new file in user folders; old links have none | no |

## Free tools only

bash, coreutils `readlink`, `find`, `ln`, `cksum`/`shasum` in tests. No new dependency.

## What might break

- Links made through a cache-version or older clone path stop refreshing and start warning (spec Q2). T6 checks whether today's links ever carry such a target before release.
- Any caller grepping link-skills stdout for `linked (` keeps working; new lines are on stderr only.
- `helix-doctor.sh:166` hides link-skills stderr during a fix; the doctor's own `check_dest` now reports clashes (R13), so they stay visible.
- `install.sh` sources `scripts/lib/helix-owned.sh` from the clone after clone/pull, so the lib is always the same version as the clone.
- `helix-auto-update.sh:115` appends both streams to `auto-update.log`: clash lines will show there on each update — expected (R9).
- `ci-check-doc-skill-lists.sh` and `helix-doctor.sh:43-56` read the skill list, not the link loop — unaffected.
- Install no longer replaces a user's same-named skill: that agent keeps the user's skill. Covered by the team notice (SPEC R5).
