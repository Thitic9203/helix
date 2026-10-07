---
type: research
status: open
assignee:
blocked_by: []
---

# Baseline phase timing

## Question

Across past real runs of retest-bug, testing-ticket (task and story), and smoke-test, where does the wall-clock time per round go? Classify each gap as HUMAN-WAIT (an AskUserQuestion or approval, until the next user turn), AGENT-WORK (reading, comparing, drafting, review loops), or EXECUTION (Playwright, API, MP4 capture, upload, posting). Report the median and maximum per phase, per flow, and the number of human touchpoints per round. Source: session transcripts (`~/.claude/projects/*/*.jsonl`, per-message `timestamp`). Raw data stays outside the repo; only a redacted summary table is committed.
