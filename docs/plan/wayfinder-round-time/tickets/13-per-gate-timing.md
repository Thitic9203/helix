---
type: research
status: closed
assignee: research-agent (session 2026-10-07)
blocked_by: []
---

# Per-gate timing

## Question

Inside AGENT and EXEC time, how many minutes per round go to each gate or phase? The gates and phases to measure: Figma compare (Figma MCP or screenshot calls), MP4 capture and its re-captures, the reviewer subagent and self-review loops, the guard and pre-delivery gate, ticket/Confluence/Swagger reading, drafting the comment, and Jira comment edits and re-posts (84 edits across 110 retest runs). Also report which phases already run in parallel and which run serially. Source: the sessions already listed in the baseline raw data. Measure only those sessions, not every transcript on the machine.

## Resolution

The full tables are in [research/13-per-gate-timing.md](../research/13-per-gate-timing.md). The seven named gates make up only about 13–15% of AGENT + EXEC time. Their cost sits in the tail: MP4 re-captures (p75 7–9 min) and reviewer subagents (retest median 15 min when present). About 85% of the time is unattributed, which graduates to [Unattributed agent time](15-unattributed-agent-time.md). Comment edits follow a pattern: post, then fix rendering, media or tables within about 2 min (81 edits). That graduates to [Comment render check](16-comment-render-check.md).
