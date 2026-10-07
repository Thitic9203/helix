---
type: research
status: closed
assignee: research-agent (session 2026-10-07)
blocked_by: []
---

# Unattributed agent time

## Question

About 85% of AGENT + EXEC time is not in any named gate. What is it? The breakdown should cover:

- generation gaps after which tool, or with no tool (pure thinking or writing);
- the long single turns (in retest, turns over 10 min total 1,174 min);
- how much is test execution, login, API and local tools;
- how much is the main thread waiting on its own subagents;
- how much is repeated work (re-reading the same file or ticket, re-running the same command).

The answer needs the top 5 buckets with minutes per round, per flow.

## Resolution

The full tables are in [research/15-unattributed-agent-time.md](../research/15-unattributed-agent-time.md). Generation is 56–61% of AGENT + EXEC, almost all of it right after a tool result. In retest, driving the browser step by step through MCP (generation after browser results plus browser tool time) takes about 27%, which is the largest single lever. Testing loses time to multi-part turns and to waiting on background agents. Repeated work is under 1%. Interrupted turns are counted as HUMAN in the baseline, so they do not inflate AGENT time. This graduates [Scripted vs agent-driven execution](17-scripted-execution.md).
