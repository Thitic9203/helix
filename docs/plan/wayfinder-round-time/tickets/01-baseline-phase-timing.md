---
type: research
status: closed
assignee: main-thread (session 2026-10-07 c)
blocked_by: []
---

# Baseline phase timing

## Question

Across past real runs of retest-bug, testing-ticket (task and story), and smoke-test, where does the wall-clock time per round go? Classify each gap as HUMAN-WAIT (an AskUserQuestion or approval, until the next user turn), AGENT-WORK (reading, comparing, drafting, review loops), or EXECUTION (Playwright, API, MP4 capture, upload, posting). Report the median and maximum per phase, per flow, and the number of human touchpoints per round. Source: session transcripts (`~/.claude/projects/*/*.jsonl`, per-message `timestamp`). Raw data stays outside the repo; only a redacted summary table is committed.

## Resolution

The full tables are in [research/01-baseline.md](../research/01-baseline.md). Median active round time: retest 68 min, story 78 min, smoke 78 min; only 18 of 110 retest runs finished within 15 minutes. AI generation time (reading, drafting, review loops) is the largest active cost (retest median 39 min of AGENT time, against 5.5 min of EXEC). Human reply wait is second, and is largest in story runs (median 18 min). Retest shows a comment re-post/edit loop (84 edits across 110 runs). There is too little data to split task from story, and there is no per-gate cost breakdown.
