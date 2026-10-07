---
type: grilling
status: open
assignee:
blocked_by: []
---

# Scripted vs agent-driven execution

## Question

In retest, about 27% of AGENT + EXEC time goes to the agent driving the browser step by step through MCP and generating after every result ([research/15-unattributed-agent-time.md](../research/15-unattributed-agent-time.md)). Should case execution change from agent-driven browser steps to a Playwright script written once per round and run in one go, with the agent reading only the script result and its evidence? Two things need settling:

- what stays agent-driven: exploration, unknown UI, and investigating a non-pass;
- how this interacts with recording during execution ([MP4 evidence gate](08-mp4-evidence-gate.md)) and with parallel lanes.
