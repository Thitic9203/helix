# Pyrite test data prep (skeleton: no recipe yet)

Governs **test-data-prep-workflow** when the project is **Pyrite** (Jira key `PYR`). The workflow today is written
for OLS (it reads `ols-data-prep.md` in the private evidence repo); that recipe does not apply to Pyrite.

**Status: skeleton.** Pyrite's project guide marks the items below *not configured*, and nothing in this repo or the
Pyrite workspace says how Pyrite test data is made. Nothing here may be guessed. Until the owner supplies each source,
the agent must stop at Gate 0 and ask once (one concrete request), not invent a recipe, tool, account or URL.

## What is already decided (source: pluton-ai-agent `docs/sdd/pyrite-test-flows/spec.md`, owner 12 Nov 2026)

- Environment: `dev` only. Staging and production are never touched (spec C3, Q1). The host is read from
  `~/.pyrite-qa-secrets/` and is never printed to a log, a Slack post or a repo.
- Machine: the company VM runs the steps that reach the app (spec C4, Q2).
- Login: a saved session the owner logged in; the agent never reads or types a password (spec C5, Q8).
- Scope: create only what an approved test case needs, listed in `data-plan.json` per case (`id`, `needs`, `role`,
  `create`, `verify`); label every created item with the job key `PYR-<n>`; read every item back; keep the created ids
  and never create twice (spec D2, D3, D3a, D4).

## What is missing (each needs an owner answer and its source before this file can be filled)

| Needed | Why it blocks | Where it must be recorded |
|---|---|---|
| How Pyrite test data is created (UI path, API, or a tool) | Gate 0 and the create step have no recipe | this file |
| Which roles and test accounts exist, and how they sign in | Data is made as a role | Pyrite project guide, *Auth* |
| The DEV host (`{PYR_DEV_URL}`) | Nothing can be created or verified without it | `~/.pyrite-qa-secrets/` and the guide |
| The data types Pyrite needs (for example users, courses, enrolments) | `needs` in `data-plan.json` has no vocabulary | this file |
| The read-back check per data type | Gate GD needs a way to verify each item | this file |
| Clean-up or reuse policy | Decides whether ids are reused across jobs | this file |

## Not covered here

OLS media and cover rules (Draw Things, Gate 0.2–0.4 of the OLS recipe) do not apply to Pyrite. Do not copy them.
