# Spec — Helix skills use at least 50% fewer tokens with the same results

## Problem

User feedback (owner, 11/Nov/2026): Helix skills use a lot of tokens. Measured on `main` @ `3986651` (bytes / 4, script `graph.py`, findings in ols-qa-evidence `docs/helix-quality/wayfinder-token-diet/FINDINGS-2026-11-11.md`):

| Skill | Mandatory reads, direct call | Via `helix` router |
|---|---:|---:|
| catch-ai-workflow | 23,986 | 36,469 |
| create-bug-workflow | 13,818 | 39,910 |
| helix | 28,860 | — |
| retest-bug-workflow | 70,292 | 84,292 |
| tc-api-prep-workflow | 14,504 | 39,961 |
| tc-fe-prep-workflow | 41,812 | 67,269 |
| tc-review-workflow | 21,688 | 36,156 |
| testing-ticket-workflow | 49,399 | 70,900 |

Main causes: the router force-loads three gate references it never runs (`skills/helix/SKILL.md:130,139,141`, 25.4K); six stubs say "every step, gate, and reference" and phase files load up front (retest 19.5K, testing-ticket 11.0K, tc-fe 10.9K); `references/qa-evidence-gates.md` is one 12.1K file of which ≈7.1K is capture/MP4/re-record rules unused by catch-ai, tc-review and the router; per-stub reference lists (0.5–1.6K each) and repeated blocks.

Shared skills are edited in ols-qa and synced to helix (`chore(sync): pull shared skill updates from ols-qa`), so every text change lands in ols-qa first and reaches helix through the sync.

## Owner decisions (11/Nov/2026)

- Plan and fix, not plan only; fewest tokens possible in every skill while results stay as good as before.
- Target ≥ 50%, measured both on a direct call and via the router (G1).
- "Same results" = the existing eval items against after-10, per skill: with-skill expected items, `darwin_total` (median of 3), P0/P1 after verify — none lower than `evals/helix-skill-eval-2026-11-11-after10/GATE.md` (ols-qa-evidence).
- Session-start rule: every Helix skill calls `caveman` (lite) and `context-mode:context-mode` before any work; if one is missing, ask to install it and say what it saves and how that helps the user.
- When every step passes, deploy the new version to both helix and ols-qa.

## Rules

- R1. When the `helix` router runs, it must read only what it needs to pick and hand off a workflow; it must not force-load `customer-escape-prevention.md`, `qa-evidence-gates.md` or `result-quality-gate.md`. Each skill that runs those gates must keep loading them at the step that uses them. (Source: `skills/helix/SKILL.md:130,139,141`.)
- R2. When a skill stub hands off to its WORKFLOW.md, it must not say "every step, gate, and reference"; a reference or phase file must be opened when its step's trigger line says so, and the progress checklist must name each such file at its step so no gate is skipped. (Source: 6 stubs, `:23`–`:31`.)
- R3. `qa-evidence-gates.md` must be split into a core file and topic files (capture/MP4, re-record, coverage/pre-delivery); every skill must link only the parts it runs; no rule text may be dropped (the union of the parts equals the original rules); every existing anchor link must resolve.
- R4. Each skill stub must point to one shared reference index instead of its own long bullet list; each repeated block (relink step, priority/verdict table, source sweep, adoption count, evidence-per-row rule) must exist once and be linked from the other places.
- R5. When any Helix skill starts, the agent must first call `caveman` with level `lite` and `context-mode:context-mode`. If either is not in the session's skill list, the agent must ask once whether to install it, with a one-line reason for each (context-mode keeps large tool output in a sandbox so the context window fills slower and long runs stay accurate; caveman lite removes filler from replies so chats are shorter and cheaper, with full grammar and politeness kept). It must never install without a yes. On no, it continues and filters large output itself. The rule lives in one shared reference linked from every skill. On hosts without skills (Codex, Copilot, Cursor) it is skipped with one line.
- R6. A change must not remove or weaken any gate, approval step or evidence rule (global rule 7); moving text to where it is used is allowed.
- R7. Every change must pass `scripts/tests/run.sh`, `ci-check-portable-skills.sh`, `ci-check-skill-structure.sh` and `ci-check-doc-skill-lists.sh`.
- R8. Claude Code installs Helix only through the plugin `helix@helix-dev`; `install.sh`/`link-skills.sh` stop symlinking skills into the Claude skills folder and remove old Helix-owned symlinks there (owner G2, 11/Nov/2026; spec `docs/sdd/single-claude-install`).
- R9. Review rounds and lanes stay uncapped, but reviewers and lane subagents receive file paths, not pasted full text (owner G3, 11/Nov/2026).
- R10. Skill descriptions are cut to ≤ 500 bytes; the frozen trigger eval (160 queries) must not score lower than after-10 (owner G4, 11/Nov/2026).

## Edge cases

- A run that stops at an early gate never opens later phase files: allowed and intended (R2).
- A skill used without the router keeps every gate it runs today (R1, R6).
- The host has neither caveman nor context-mode and the user says no: the skill still runs (R5).
- Portable content: no machine paths, no customer names (`references/portable-content.md`).

## Done when

- `graph.py` on the new `main`: every skill's direct and routed mandatory reads ≤ 50% of the table above.
- An eval round on the new `main` with the after-10 exam: per skill, expected items, `darwin_total` and P0/P1 are not worse than after-10.
- All CI checks in R7 pass.
- The new version is released on helix and synced to ols-qa.

## Measurement decisions (owner popup, 11/Nov/2026)

- The two session-start skills (`caveman`, `context-mode:context-mode`) are **not** counted in the 50% target; their token cost is measured and reported on a separate line.
- A second measure is added so rewording cannot game `graph.py`: per skill, median tool calls and output bytes from the eval run files (line-1 timing header) must not rise against after-10.
