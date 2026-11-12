# Spec — session start only notifies; updates run from a command the user starts

## Problem

Today every SessionStart (Claude Code and Cursor) runs `scripts/helix-auto-update.sh`, which
fetches from origin, fast-forwards `~/.helix/tc-fe-prep` to the newest release tag, and then runs
the **just-fetched** `link-skills.sh` and `claude-plugin-sync.sh`. The only gate is "the tag is an
ancestor of `origin/main`" (research 02, rows 32–36). The owner decided on 2026-11-04: **notify
only** (`docs/plan/wayfinder-supply-chain/SPEC.md` R2, ticket 03 "Resolution").

Evidence (worktree at `origin/main` 5eb2bb9, read 2026-11-04):

| Place | What it does today |
|-------|--------------------|
| `hooks/session-start:9-15` | runs `helix-auto-update.sh` (plugin copy first, else `~/.helix/tc-fe-prep/scripts/`), `HELIX_QUIET=1`, errors dropped (`2>/dev/null \|\| true`) |
| `hooks/hooks.json:3-10`, `hooks/hooks-cursor.json:4-8` | both agents run the same `hooks/session-start`; Claude Code runs it synchronously (`"async": false`) on `startup\|clear\|compact` |
| `hooks/session-start:17-23` | if `~/.helix/last-update-error` is non-empty, adds "Helix auto-update problem" + a manual-run command to the context |
| `scripts/helix-auto-update.sh:43-48, :191-193` | `HELIX_AUTO_UPDATE=0/false/no/off` → exit 0, nothing runs |
| `scripts/helix-auto-update.sh:50-67` | `HELIX_FORCE_UPDATE` set → always run; else run when the stamp is missing, older than `HELIX_AUTO_UPDATE_INTERVAL_SEC` (default 14400, `:22`), or `git ls-remote` names a newer release (`:66`, `:73-84`) |
| `scripts/helix-auto-update.sh:135` | `git fetch origin main '+refs/tags/v*:refs/tags/v*'` (network write into the clone) |
| `scripts/helix-auto-update.sh:140-166` | picks the highest `vX.Y.Z` tag on `origin/main`, never moves back, `git merge --ff-only` |
| `scripts/helix-auto-update.sh:103-109, :155` | cache symlink `~/.claude/plugins/cache/helix-dev/helix/<VERSION>` → clone, also when nothing moved |
| `scripts/helix-auto-update.sh:111-122` | runs the newly fetched `link-skills.sh` and `claude-plugin-sync.sh` |
| `scripts/helix-auto-update.sh:214-220, :172-188` | no clone: `curl` raw `VERSION` from `main` (`:23`, `:91-93`), then runs `claude-plugin-sync.sh` |
| `scripts/helix-auto-update.sh:223-228` | devenv re-sync — removed by `docs/sdd/retire-devenv/` R10 |
| `scripts/helix-auto-update.sh:231-233` | a run with no step failure deletes `last-update-error` |
| `scripts/helix-doctor.sh:143-158` | warns when `.last-auto-update-check` is missing or older than `HELIX_DOCTOR_STALE_SEC` (86400) |
| `README.md:173`, `docs/wiki/Home.md:136` | the documented manual run: `HELIX_FORCE_UPDATE=1 [HELIX_AUTO_UPDATE_VERBOSE=1] bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh` |
| `README.md:177` | "offline → skip (no error)" — but `helix-auto-update.sh:136` records an error when the fetch fails |

## Scope

In: `hooks/session-start:9-23`; `scripts/helix-auto-update.sh` (all of it except `:223-228`, owned
by retire-devenv); `scripts/tests/auto-update.test.sh`; a new hook test; the docs listed in R13.

Out: `SECURITY-NOTICE.md` (Q4); `scripts/helix-setup-devenv.sh` and the devenv tip (`docs/sdd/retire-devenv/`); install path
(SPEC R1); `link-skills.sh` clash handling (SPEC R4); Claude Code's **own** marketplace auto-update
of the plugin (research 01 D4–D6 — a Claude Code setting, not Helix code); the git `post-merge`
hook (`scripts/hooks/post-merge`, runs only on a `git pull` the user types); signed tags (SPEC
follow-up); the team notice (SPEC R5).

## Roles

- **SessionStart hook** — `hooks/session-start`, run by the agent, not by the user.
- **Update command** — a run the user types in a terminal (or asks the agent to run).
- **Installed release** — `VERSION` in `HELIX_REPO_DIR` (default `~/.helix/tc-fe-prep`); with no
  clone, `VERSION` next to the running script's repo root.

## Rules

- **R1** — When the SessionStart hook runs, the system must not run `git fetch`, `git merge`,
  `git pull`, `git reset` or `git checkout` in the clone, and must not change the clone's `HEAD`,
  refs, index or working tree.
  Source: SPEC R2; ticket 03 "No new code is fetched or run inside the session-start hook";
  today `helix-auto-update.sh:135, :163`.
- **R2** — When the SessionStart hook runs, the system must not run `link-skills.sh`,
  `claude-plugin-sync.sh`, `helix-setup-devenv.sh` or any `claude plugin …` command, and must not
  create, rename or remove anything under `~/.claude/skills`, other agents' skill dirs, or
  `~/.claude/plugins/cache/helix-dev/helix/` (including the cache symlink).
  Source: SPEC R2; today `helix-auto-update.sh:111-122, :155, :172-188, :223-228`.
- **R3** — When the SessionStart hook runs and the update check is on (R8), the system must read
  the newest release `vX.Y.Z` with one read-only `git ls-remote --tags --refs` and compare it with
  the installed release using the same order as today.
  Source: SPEC R2 "compares the installed release with the newest release tag";
  today `helix-auto-update.sh:69-84`.
- **R4** — When there is no clone, the check must read the release tags with `git ls-remote` on the
  Helix repository URL, and must not `curl` `VERSION` from `main`.
  Source: SPEC R2 ("newest release **tag**", `main` is not a release); today `:23, :91-93, :215`.
- **R5** — When the newest release is greater than the installed release, the hook output must
  contain exactly one notice line naming both versions and the update command (R6). When it is
  equal or lower, or the check fails, the output must contain no notice line. The output must stay
  one valid JSON object (today's contract, `auto-update.test.sh:39`).
  Source: SPEC R2 "prints one line when a newer one exists"; `hooks/session-start:56-64`.
- **R6** — The update command is
  `bash ~/.helix/tc-fe-prep/scripts/helix-auto-update.sh` with no arguments. When the user runs it,
  the system must do what the script does today minus the devenv block: fetch, pick the newest
  release on `origin/main`, never move back, fast-forward, refresh the cache symlink, run
  `link-skills.sh` and `claude-plugin-sync.sh`, and record failures in `last-update-error`.
  Source: SPEC R2 "run only from an update command the user starts"; the command is already the
  documented manual run (`README.md:173`, `docs/wiki/Home.md:136`); behaviour `:124-170`;
  devenv removal per retire-devenv R10.
- **R7** — The SessionStart hook must call the script in a check-only mode that the script refuses
  to leave: in that mode no code path reaches R1/R2 actions, whatever env vars are set
  (`HELIX_FORCE_UPDATE` included).
  Source: SPEC R2 Done-when (state unchanged after the hook); today FORCE bypasses every gate (`:51`).
- **R8** — `HELIX_AUTO_UPDATE=0` (and `false/FALSE/no/NO/off/OFF`) must turn the session-start
  check off: no `ls-remote`, no notice. It must not block the update command the user starts.
  Source: today's values `:44-46`; SECURITY-NOTICE.md:36 tells teammates to set it; R6 (a user-started
  command is the point of R2).
- **R9** — `HELIX_FORCE_UPDATE` must have no effect on the session-start check (R7) and must be
  accepted and ignored by the update command, which always fetches.
  Source: today `:50-53` only bypasses the interval; R6 has no interval.
- **R10** — `HELIX_AUTO_UPDATE_INTERVAL_SEC` must be accepted and ignored: the check runs on every
  session, as today's tag probe does.
  Source: `helix-auto-update.sh:63-66` (a release must reach the next session; "1.5.105 … stayed
  invisible for 4 hours"); `auto-update.test.sh:65-67`.
- **R11** — After a check that read the tag list, the system must write the stamp
  `~/.helix/.last-auto-update-check` (state only, no code), so `helix-doctor.sh:143-158` keeps
  meaning "the hook ran its check".
  Source: `helix-doctor.sh:145-146`; `doctor-stale.test.sh`.
- **R12** — A failed check (offline, proxy, TLS) must not write `last-update-error`; it only logs
  to `auto-update.log`. Only the update command writes or clears `last-update-error`. The hook still
  surfaces a recorded error, and its text must point to the R6 command.
  Source: `README.md:177` "offline → skip (no error)"; `hooks/session-start:17-23`; `:36-41, :231-233`.
- **R13** — Docs must describe notify-only: `README.md:146-178` (section, trigger table, steps,
  env table, manual command, notes), `README.md:193`, `README.md:211`, `README.md:291`,
  `docs/wiki/Home.md:59`, `docs/wiki/Home.md:110-137`, `docs/wiki/Home.md:175`,
  `docs/DOC-MAP.md:9, :32`, `scripts/install.sh:58, :82`, `scripts/helix-doctor.sh:150-163, :222`,
  `scripts/helix-auto-update.sh:2-11` (header). `SECURITY-NOTICE.md` is not edited here (Q4).
  Source: grep `helix-auto-update|HELIX_AUTO_UPDATE|HELIX_FORCE_UPDATE|INTERVAL_SEC` at 7a56f60
  (line numbers re-read there; the devenv block and tip are already gone, so R2/R14 cites to
  `:223-228` are history only).
- **R14** — Migration: a machine still on the old updater gets the release that carries this change
  through its old session-start run (old code fetches it and runs its `link-skills.sh` /
  `claude-plugin-sync.sh` once). From the next session on, only R3–R5 run. The new release must not
  need any manual step on such a machine. A machine with `HELIX_AUTO_UPDATE=0` stays where it is
  until the user runs R6.
  Source: today `:111-122` (old code runs the new release's scripts); `hooks/session-start:10-12`
  (the hook comes from the plugin root, which the cache symlink points at the clone, `:103-109`).

- **R15** — (owner 12/Nov/2026) When the notice (R5) is in the hook output, it must also tell the
  agent to ask the user once whether to update to the newer release, and to run the update command
  (R6) only after the user answers yes; on no or no answer it must run nothing. The hook itself still
  runs nothing new (R1, R2, R7): the update is the user-started command of R6, run by the agent on
  the user's yes ("Roles: Update command").
  Source: owner request 12/Nov/2026 "ถามว่าจะอัปเดตเวอร์ชันใหม่ แล้วถ้าผู้ใช้ตอบว่า ใช่ ก็ติดตั้งอัปเดตให้เลย";
  keeps SPEC R2 "run only from an update command the user starts"; `hooks/session-start:22-24`.
  Done when: hook output contains the ask-then-run instruction and the update command; hook still
  changes nothing (T1 snapshot test).

## Edge cases

- Clone ahead of the newest release (dev checkout) → no notice (R5, "equal or lower"; today `:158-161`).
- No release tag on the remote, or a tag that is not `vX.Y.Z` → no notice (R5; today `:75`).
- `ls-remote` hangs: the hook is synchronous (`hooks.json:10`). Same exposure as today's probe (`:66`);
  a timeout is a plan item, not a new rule.
- Local tags older or forced elsewhere do not matter to the check: it reads remote tags only (R3).
- Plugin cache is a real copy made by `claude plugin update` instead of the symlink
  (`scripts/hooks/post-merge:23-24`): the hook runs that copy's script; R1–R2 hold for it too once it
  is on this release.

## Decisions (owner, 2026-11-04, `docs/plan/wayfinder-supply-chain/owner-decisions-2026-11-04.md`)

- Q1 — Keep the `HELIX_AUTO_UPDATE*` variable names (R8–R10). No rename.
- Q2 — No `/helix-update` slash command. The update command is the existing documented bash command (R6).
- Q3 — The notice line appears in the agent's context only (the hook's additional context), nowhere else.
- Q4 — `SECURITY-NOTICE.md` is updated later, with the fixed release (SPEC R5). This change does not edit it.

## Done when

- A test builds a local bare remote with `v1.0.0` and a newer `v1.0.1` (whose `scripts/link-skills.sh`
  and `scripts/claude-plugin-sync.sh` are stubs that write a sentinel, plus a `claude` stub on `PATH`),
  clones at `v1.0.0`, runs `hooks/session-start` with a fake `$HOME`, and proves: clone `HEAD`, refs
  and `git status` unchanged; the skill-dir listing and the plugin-cache listing byte-equal to before;
  no sentinel; output is valid JSON with exactly one notice line naming `1.0.1`.
- Same test with `HELIX_FORCE_UPDATE=1` and `HELIX_AUTO_UPDATE_INTERVAL_SEC=0` set: same result.
- Same test with the clone at `v1.0.1`: no notice line.
- Same test with `HELIX_AUTO_UPDATE=0`: no notice, no `ls-remote` line in the log, no stamp written.
- Same test with an unreachable remote: no notice, no `last-update-error`, valid JSON.
- No-clone case: `ls-remote` on a local URL finds the newer tag; no `curl` call (stub on `PATH` writes a sentinel).
- Running the update command in the same setup moves the clone to `v1.0.1` and runs both stubs once.
- `auto-update.test.sh` existing checks for the update command (`:21-55`) still pass; `:57-67` now
  assert "session does not move, prints the notice; update command moves".
- `doctor-stale.test.sh` passes; README / wiki / DOC-MAP / install.sh / doctor text say notify-only and
  name the R6 command (grep: no "updates the next session", no "auto-update hooks").
