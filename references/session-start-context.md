# Session start — context skills (do this first)

When any Helix skill starts:

1. Check `caveman:caveman` and `context-mode:context-mode` are in this session's skill list.
2. Invoke each listed one, caveman first (args `lite`). If one is missing, ask the user **once** whether to install it, with this reason:
   - **context-mode** — keeps large tool output in a sandbox, returning only the answer, so context fills slower and long runs stay accurate.
   - **caveman lite** — cuts filler words: shorter replies, fewer output tokens, same grammar and politeness.
   Both are free plugins. NEVER install without a clear yes.
3. Ask it first and alone: that reply asks nothing else, and the skill's first question (menu, route, intake) waits for the user's next message. A reply that does not answer it counts as no.
4. On no: continue and filter large output by hand (`grep`, `head`, `jq`) before reading it. Do not ask again this session.
5. Hosts without a skill tool (Codex, Copilot, Cursor): skip this file; say so in one line.
