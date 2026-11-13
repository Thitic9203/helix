---
name: qa-project-flow
description: Project-aware QA flow for OLS and Pyrite (PYR) — create test cases, review test cases, execute tests — applying each project's own TC rules, targets and format on top of the Helix workflows. Use when the user gives an OLS-xxx or PYR-xxx ticket and asks to write TCs, review TCs, run/execute the tests, or says /qa-project-flow, "เขียน TC", "รีวิว TC", "เทสตาม TC", "updateTCSheet". Do NOT use for filing bugs, retesting a dev fix, or test data prep — those go straight to their Helix workflow.
metadata:
  proactive_triggers:
    - /qa-project-flow
    - เขียน TC
    - รีวิว TC
    - เทสตาม TC
    - updateTCSheet
    - write test cases PYR
    - write test cases OLS
---

# QA project flow (OLS + PYR)

One entry point for the three daily jobs — **create TCs, review TCs, execute tests** — that picks the right project rules automatically. It does not replace the Helix workflows; it chooses the project profile and wraps them.

**Session start:** before anything else, follow [session-start-context.md](../../references/session-start-context.md).

## Step 1 — Detect the project

| Signal | Project | Read |
|---|---|---|
| Ticket key `PYR-xxx`, Qase project Pyrite, Pyrite Drive folder | Pyrite | [references/pyr.md](references/pyr.md) |
| Ticket key `OLS-xxx`, OLS release folder / template | OLS | [references/ols.md](references/ols.md) |
| No key, or key from another project | — | Ask for the ticket key (one question). Never guess the project. |

Read only the profile file for the detected project. Its rules override the generic Helix defaults wherever they differ.

## Step 2 — Detect the job

| User wants | Job | Delegate to |
|---|---|---|
| Write / prepare TCs from AC/EC | **Create** | `tc-fe-prep-workflow` (UI story) or `tc-api-prep-workflow` (API/Swagger) |
| Review an existing TC sheet / document | **Review** | `tc-review-workflow` |
| Run the tests (manual, from the TC sheet) | **Execute** | [references/execute.md](references/execute.md) |
| Change TC sheet to the release template | Format | `tc-change-format-workflow` (OLS) |
| A found defect / dev fix | — | `create-bug-workflow` / `retest-bug-workflow` directly |

If the message names the job, announce the route in one line and go. If not, ask one question: create, review, or execute.

## Step 3 — Run with the project overlay

1. Announce: `Using **qa-project-flow** → {project} · {job} → {workflow}.`
2. Load the delegated workflow and follow it completely.
3. Apply the project profile as an overlay: targets (Qase / Drive / sheet), Test Case Type values, ID format, glossary, ordering, definition of done. Where profile and workflow disagree, the profile wins — say so in one line when it changes the output.
4. Before writing anything, check whether this ticket already has a sheet / folder / Qase suite (see the profile's reuse rule). Update in place; never duplicate.
5. Stop at the project's definition of done. Do not add extra posts (e.g. Jira comment) the profile excludes.

## Rules

- MUST confirm the project from the ticket key before applying any profile. OLS and PYR rules are not interchangeable (Test Case Type values, ID format and glossary differ).
- MUST keep Qase, the Drive sheet and any other artifact of one ticket identical.
- MUST NOT write secrets (Qase token, passwords, account credentials) into the sheet, Qase, Jira, repo or chat. Tokens stay in the local secrets file named in the profile.
- MUST NOT invent a rule that is not in the profile. If the profile is silent on something that changes the output, ask once and propose the answer for the team to add to the profile.
- Automation (Playwright) is not part of this flow yet: do not offer to write or run Playwright for TC execution unless the user asks.

## Communication (shortest possible)

Goal: fewest tokens in every message of this skill.

- Ask one question per turn, one line, with the options inline when there are a few (e.g. `สร้าง / รีวิว / เทส?`). No preamble, no explanation of why you ask.
- Never ask for something the profile, the ticket or an earlier answer already gives.
- Announce the route in one short line. Do not recite rules, steps or the plan back to the user.
- Report results in a few lines: what was done, counts, links, open issues. No recap of the input, no step-by-step narration, no offers of follow-up work.
- Show tables only when the user must decide something from them (e.g. a confirmation gate); otherwise a one-line summary.
- Write tool output and files in full as the workflow requires; the brevity rule applies to chat messages, not to the TC content itself.

## Refusal-first (precondition gate)

Refuse, say why in one line, and route instead when:

| Request | Do |
|---|---|
| File a bug, retest a dev fix, prepare test data | Not this skill — route to `create-bug-workflow`, `retest-bug-workflow` or `test-data-prep-workflow`. |
| Post a Jira comment for a PYR ticket | Refuse; the PYR definition of done excludes it unless the user explicitly asks. |
| Apply a profile when the project is not confirmed from the ticket key | Refuse; ask for the key first. |

## QA closing (mandatory before "done")

Follow [qa-closing-shared.md](../../references/qa-closing-shared.md), plus:

- [ ] Project confirmed from the ticket key and its profile was read.
- [ ] Output follows the profile (Type values, ID format, wording, ordering).
- [ ] Qase, sheet and any other artifact of the ticket match each other.
- [ ] Nothing posted outside the profile's definition of done; no secret written anywhere.
