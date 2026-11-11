# Session start — context skills (do this first)

When any Helix skill starts, before step 1:

1. Invoke the skill `caveman:caveman` with args `lite`, then the skill `context-mode:context-mode`.
2. Check each one is in this session's skill list. If one is missing, ask the user **once** whether to install it, with this reason:
   - **context-mode** — keeps large tool output (logs, test results, pages) in a sandbox and returns only the answer, so the context window fills slower and long QA runs stay accurate.
   - **caveman lite** — removes filler words from replies: shorter chats and fewer output tokens, while full grammar and politeness stay.
   Both are free plugins. NEVER install without a clear yes.
3. On no (or no answer): continue the workflow and filter large output by hand (`grep`, `head`, `jq`) before it enters context. Do not ask again this session.
4. Hosts without a skill tool (Codex, Copilot, Cursor): skip this file with one line, e.g. "Context skills not available on this host — filtering output by hand."
