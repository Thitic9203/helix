# Tasks — link-skills-no-delete

Tests run offline in `scripts/tests/link-skills.test.sh` (sources `lib.sh`). Setup:
`R="$(copy_repo)"`, `H="$(mktemp -d)"`, `mkdir -p "$H/.claude/skills"`; pick `S` = one shipped
skill name (first line of `helix_linked_skills "$R"`). "Run" = `HOME="$H" bash
"$R/scripts/link-skills.sh" >"$H/out" 2>"$H/err"; echo $? >"$H/rc"`. "Snapshot" =
`find <path> -exec cksum {} +` plus `ls -la` of the skills folder.

| # | Task | Rule | Failing test first | Done when |
|---|------|------|--------------------|-----------|
| T1 | User folder survives | R1, R2, R6 | `mkdir "$H/.claude/skills/$S"; echo mine >"$H/.claude/skills/$S/SKILL.md"`; snapshot; run → snapshot equal, entry is not a symlink, `err` has 1 line with `$S`, the full path and `link-skills.sh` (fails today: `:44` deletes it) | passes |
| T2 | User file survives | R1 | same as T1 with a plain file `$S` → file intact, warned | passes |
| T3 | Foreign symlinks kept | R3 | `ln -s "$H/elsewhere" …/$S` (target exists) and, in a second fake home, a broken link to `$H/gone` → `readlink` text unchanged, warned (fails today: `:53` `ln -sfn` replaces it) | passes |
| T4 | Helix links refreshed | R4 | link `$S` to `$R/skills/does-not-exist/$S` (broken, inside clone) → after run it resolves to `$R/skills/…/$S/SKILL.md`, no warning | passes (green today; guards the classifier) |
| T5 | Run continues, exit 0 | R8, R10 | T1 setup → `rc` = 0; every other shipped skill linked; run with `>/dev/null` still shows the warning on stderr; summary line `1 skill(s) skipped` present | passes |
| T6 | Idempotent | R9 | T1 setup, run twice → snapshots equal after each run, `err` identical both times; clean home run twice → second run changes no `ls -la` output | passes; also record whether any link target under `~/.claude/plugins/cache/` appears in run output of a real install (input for spec Q2) |
| T7 | All folders, both modes | R7 | T1 clash in `~/.cursor/skills` (create `~/.cursor`); workspace `W` with `HELIX_LINK_WORKSPACE=$W` and a user folder `$W/.agents/skills/$S`, once without and once with `$W/skills/helix/SKILL.md` (relative mode) → intact + warned in each | passes |
| T8 | No delete left in script | R6 | `grep -n 'rm -r' scripts/link-skills.sh` empty (fails today: `:44`) | passes; `bash scripts/tests/run.sh` green |

Order: T1–T3 and T8 (the safety core), then T4–T7. Commits cite `Spec: docs/sdd/link-skills-no-delete R<n>`.
Owner questions Q1–Q3 in spec.md stay open; no task changes `install.sh`, `setup.sh` or `helix-doctor.sh`.
