---
type: grilling
status: closed
assignee:
blocked_by: []
---

# Scripted vs agent-driven execution

## Question

In retest, about 27% of AGENT + EXEC time goes to the agent driving the browser step by step through MCP and generating after every result ([research/15-unattributed-agent-time.md](../research/15-unattributed-agent-time.md)). Should case execution change from agent-driven browser steps to a Playwright script written once per round and run in one go, with the agent reading only the script result and its evidence? Two things need settling:

- what stays agent-driven: exploration, unknown UI, and investigating a non-pass;
- how this interacts with recording during execution ([MP4 evidence gate](08-mp4-evidence-gate.md)) and with parallel lanes.

## Resolution

Decided with the user on 2026-10-07. **Keep agent-driven browser execution** (the agent drives the browser step by step through MCP), not a scripted Playwright run. Accepted cost (user): the largest measured lever, about 27% of retest AGENT + EXEC ([research/15-unattributed-agent-time.md](../research/15-unattributed-agent-time.md)), stays in the round. The remaining route to the 15-minute cap therefore rests on [Agent fan-out for large scope](14-agent-fan-out.md) and the dedupe decisions. Recording during execution ([MP4 evidence gate](08-mp4-evidence-gate.md)) applies to the agent-driven session.
