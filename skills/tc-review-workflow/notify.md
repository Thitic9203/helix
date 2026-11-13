# TC review — Step 5 notify

Part of [SKILL.md](SKILL.md) Step 5.

Every run sends the finished review to the TC-review notify channel **of the ticket's project**,
whoever invoked the skill, asked for a share or not; never post one project's review in
another project's channel. The channel comes from that project's
config: the project guide `references/{PROJECT}-guide.md` § *TC review notify* (channel,
thread rule, mention rule). The real ids and the webhook live in the local secrets folder
named there (one webhook file per thread, e.g. `discord_webhook_tc_review_<thread>`), never in the repo.

- **Project has a channel in config → NEVER ask which server, group, or channel** (config answers it).
  🔴 **CHECKPOINT —** Ask exactly one question: which thread of that channel to post in (the only exception is the missing mention id, item 1, when config has none). Offer the threads already used for this ticket or
  recorded in the config as options. The answer is the go-ahead to send. Put the item-5 preview (candidate threads, final text, character count) in that same message. Where the workspace carries
  `tools/ask-guard` (workspace-optional, see [dependencies.md](../../references/dependencies.md)), it
  blocks the channel question for such projects (state `fixed-destination`); without it, apply it
  by hand.
- **Project has no channel in config →** search conversation history and memory for that project's
  destination first. Found → use it, and ask in the same message whether to record it in that project's config; write only on a yes. Not found → ask once for that
  project's channel and thread, and whether to record them, so they are never asked again; write only on a yes.
- **User declines the send, or will not name a thread →** do not send — nothing goes out without the
  thread answer and the item-5 preview. Tell the user the send is part of this workflow
  (an owner decision), so the review is not complete. Record `notify not sent — user declined` in the QA
  closing checklist and the final report, then stop. Never skip the step silently or report the run as done-and-notified.

Then, in this order (items 1–6 every send; items 7 and 8 only when correcting a sent message):

1. **Identity for a mention:** take the exact id (Discord user id, Jira account id) from the project
   config § *TC review notify* — never ask the user for it. Only when the config has none for the person to
   mention, ask for the exact id rather than guessing one from a display name — a wrong id either pings nobody or pings the wrong person. The same
   holds for a channel or thread id: never invent one; it comes from config or from the user's answer.
2. Use the wording conventions in the project guide § *TC review notify* (above), e.g. a fixed term for
   "ticket". None there → keep the wording of the review shown in chat; never invent new terms.
3. **Fit the platform's message limit before sending** (Discord: 2,000 characters).
   If too long, tighten the wording. Do not drop findings the user saw in chat, and do not split unless the user asks.
   Still over after tightening → 🔴 **STOP —** show the character count, ask: split into numbered posts, or which findings to cut. Send nothing before the answer.
4. A thread is reached through a webhook plus `thread_id` (without it the message lands in the parent
   channel); on Discord also pass `wait=true`, or the send returns 204 with no body for item 6 to read.  **Webhook file for the chosen thread missing** from the secrets folder → ask the user for it
   once; handing it over is the yes to save it to that secrets folder under the per-thread file name above, and never write it into the
   repo or repeat it in chat; then continue from item 5.
5. 🔴 **GATE — before the external send:** show in chat the destination (channel + thread), the final text
   exactly as it will be sent (after any item-3 tightening) and its character count. The thread answer
   counts as the go-ahead only once that preview is visible (it arrives in the question message) and matches the chat review. Text changed
   (item 2/3) → 🔴 **STOP —** send only on the user's OK to this preview.
6. **Send, then read the response back** before telling the user it is done: confirm the destination
   (channel/thread id) matches what they asked for, and that a requested mention actually resolved.
   **Send returns non-2xx or times out** → do not retry blindly: report the status code and response
   body, keep the review in chat, and ask the user how to proceed (a 429 states the `retry_after` value
   it returned).
7. **Wrong destination → delete and resend** — a message cannot be moved between channels/threads by
   editing it. 🔴 **GATE —** first show both destinations and the item-5 preview; delete and resend
   only on the user's go-ahead. **Wrong content, correct destination → edit in place** — never delete and repost just to
   fix wording.
8. **Revising a review that is already posted** (new suggestions, a scope cut): edit the existing
   message in place (e.g. Discord webhook `PATCH …/messages/{id}`, plus `thread_id` in a thread). The edited text must still fit the item 3 limit. Do not post a second copy. Read back the edited message: id, destination,
   mentions, content.
   **Edit or delete returns non-2xx or times out** → no blind retry and no silent second copy:
   report the status code and body; keep the review in chat. A `404`
   (message already deleted) → ask the user before posting a fresh copy; a `401`/`403` (webhook rotated
   or revoked) → ask for the current webhook for that thread (item 4), then retry the same edit.

**Go back:** If the item-6 read-back shows the wrong destination, delete and resend (item 7); wrong content or an unresolved mention → edit in place (item 7 second rule; method and its failure branch in item 8) and read back again. The send is not done before a clean read-back.
