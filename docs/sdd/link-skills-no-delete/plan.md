# Plan — link-skills-no-delete

Spec: [spec.md](spec.md). Base: `origin/main` 56def8b.

## Files touched

| File | Change | Rules |
|------|--------|-------|
| `scripts/link-skills.sh:10` | add `REPO_P="$(cd "$REPO" && pwd -P)"` next to the logical `REPO` (both prefixes count as the clone) | R4 |
| `scripts/link-skills.sh:12-56` (`link_into`) | replace `:43-45` with a classifier `is_helix_link <target> <name> <relative>`; branch: no entry → link (R5); Helix link → `ln -sfn` (R4); else → `warn_clash` + `continue` (R1, R3) | R1, R3–R6 |
| `scripts/link-skills.sh` (new helper) | `warn_clash <label> <name> <path> <kind>` → stderr: `skip (<label>) <name>: <path> is your own <folder\|file\|symlink -> X>, not a Helix link. Rename or remove it, then run: bash <REPO>/scripts/link-skills.sh`; increment a counter | R2, R10 |
| `scripts/link-skills.sh:107-109` | when the counter > 0, print `N skill(s) skipped because of name clashes (see above)` to stderr; exit 0 | R8 |
| `scripts/tests/link-skills.test.sh` | add clash, symlink, broken-link, idempotence, workspace and exit-code cases (tasks T1–T7) | all |

The counter must survive the `find … | while` pipe at `:33-37` (a subshell). Write clash lines
to a temp file (`mktemp`, removed by `trap`) or switch the loop to `while … done < <(find …)`
(bash process substitution, already used in `helix-doctor.sh:50`). Choice: process substitution
— no temp file, same pattern the repo already uses.

## Classifier (raw target, never resolved)

```
t="$(readlink "$target")"            # works on broken links
relative=1 → helix iff t == "../../skills/$name"
otherwise  → helix iff t == "$REPO"/skills/* or t == "$REPO_P"/skills/*, and basename(t) == name
```

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
- `helix-doctor.sh:166` hides stderr, so a doctor fix stays silent on clashes (spec Q3).
- `helix-auto-update.sh:115` appends both streams to `auto-update.log`: clash lines will show there on each update — expected (R9).
- `ci-check-doc-skill-lists.sh` and `helix-doctor.sh:43-56` read the skill list, not the link loop — unaffected.
- Install no longer replaces a user's same-named skill: that agent keeps the user's skill. Covered by the team notice (SPEC R5).
