---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07 b)
blocked_by: []
---

# Intake persistence

## Question

What intake and context should persist between rounds, so that round N does not ask again or re-read from scratch? Candidates: per-project config (env, accounts, Jira format) in the workspace guide, and per-ticket state (case list, AC/EC list, Figma node refs, Swagger version, last-round results). Where does it live, what invalidates it (ticket edited, new build, design changed), and how is staleness detected?

Also covers the pre-answerable items found in [Approvals vs decisions](04-approvals-vs-decisions.md): retest first-time config (1b), transition names (8a), notify recipient field (Step 9), and testing results destination (G1/G2).

## Resolution

Decided with the user on 2026-10-07 (AskUserQuestion, one popup, three questions).

**Today:** per-project values already live in the workspace guide (`references/workspace-guide-discovery.md` §"When no guide is found" step 3 only *offers* to save). Per-ticket state has no home between rounds; the handoff file (`references/session-closing.md:50`, `references/handoff-file-template.md`) is written only when a run is long, blocked, or moving to a new chat.

**1. Per-project values → workspace guide, saved automatically.** Environment, account pool, Jira post format (v2/v3), transition names (retest 8a), notify recipient field (retest Step 9), results destination (testing G1/G2). The first time a value is asked, it is written to `references/{PROJECT}-{workflow}-guide.md` without a second "save this?" question. The existing rule stays: never store production passwords in a committed guide.

**2. Per-ticket state → the existing handoff file, written every round.** `references/helix-handoff-{KEY}.md` is written at the close of every round, not only on long or blocked runs. It holds the case list, the AC/EC list, Figma node refs, the Swagger version, the last round's results, and one fingerprint per source (below). Whether last-round results may be *reused* is not decided here; that is [Retest round-N reuse](06-retest-round-n-reuse.md). Login state stays with [Login reuse option](11-login-reuse-option.md).

**3. Staleness → fingerprint check every round.** At the start of round N, fetch each source's cheap fingerprint fresh in that session and compare it with the stored one: ticket `updated` timestamp (plus comment count), Figma file `lastModified`, Swagger spec hash, deployed build version where the project exposes one. A matching fingerprint skips the full re-read of that source; a changed or missing fingerprint re-reads that source only. This keeps `references/qa-evidence-gates.md:10` ("run fresh in this session"): the check itself is fresh every round; the stored state only saves the full read.

**Accepted cost (user, 2026-10-07):** the handoff file sits in the user's workspace `references/` and may be committed with ticket content. The user chose the existing location over a new gitignored one.

**Fog cleared:** "Picking the Jira post format late" — the format is now a guide value asked once and saved, so it is known at intake from round two on.
