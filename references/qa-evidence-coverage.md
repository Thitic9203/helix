# QA evidence — coverage and pre-delivery gates

Split from [qa-evidence-gates.md](qa-evidence-gates.md). Open this before handing results to the requester.

## Contents

- [AC/EC & bug-detail coverage — 7-layer completeness defense gate (mandatory, fail-closed)](#acec--bug-detail-coverage--7-layer-completeness-defense-gate-mandatory-fail-closed)
  - [Coverage red flags — STOP, you are about to pass on partial coverage](#coverage-red-flags--stop-you-are-about-to-pass-on-partial-coverage)
- [Pre-delivery completeness — 7-layer defense gate (before handing results to the requester)](#pre-delivery-completeness--7-layer-defense-gate-before-handing-results-to-the-requester)
  - [Adversarial review pass — read your own deliverable as the reviewer hunting for the shortcut](#adversarial-review-pass--read-your-own-deliverable-as-the-reviewer-hunting-for-the-shortcut)

## AC/EC & bug-detail coverage — 7-layer completeness defense gate (mandatory, fail-closed)

**The scope of what must be tested is the ticket's own contract — every Acceptance Criteria, every
Expected Condition / Expected Result line, and (for a retest) every item of the bug's Expected Result
plus each bullet of the bug's own detail/steps. The job is not done until every one of those items is
tested AND appears as its own row in the results/verdict table with its own verdict + evidence.** A
point that was worth noticing is worth a row — it is **never** acceptable to mark a case PASSED on
partial coverage and mention the untested/failing item in a remark, a "หมายเหตุ", a note under the
table, or in chat. Coverage is proven by rows in the table, not by prose beside it.

Run all 7 layers per ticket. Layers 1–2 run **while building the test plan** (before the confirm gate
/ before execution); layers 3–5 run **during execution, per item**; layers 6–7 run **before any
summary, verdict, post, transition, or "done"**.

| # | Layer | Passes only when |
|:--:|---|---|
| **1** | **Enumerate the full scope** | Every testable item in the authoritative contract is extracted **char-exact** and given a stable id — the ticket's Acceptance Criteria (`AC1…`), every Expected Condition / Expected Result line (`EC1…` / `ER1…`), and for a **retest** every item of the bug's Expected Result field **plus** each bullet of the bug's detail/steps. **Extract assertions embedded in prose too**, not only bulleted lines — a paragraph "the user can X and the count updates" is two items. **Completeness self-check (the gate is only as strong as this layer):** re-read the AC/EC source **end-to-end** and confirm no testable assertion is missing from the list — under-enumeration here passes layer 6 silently because layer 6 only reconciles against what was enumerated. This numbered list is the coverage baseline: nothing tested-or-reported lives outside it, and no item in it is silently dropped. |
| **2** | **Map 1:1 to rows — no orphan, no bundling** | Every enumerated id maps to **≥1 row** in the test plan / verdict table (build the coverage matrix `id → row #`). An enumerated id with **no row** = a coverage gap → stop and add the row. A **compound** AC ("does A **and** B **and** C") splits into **one checkable row per clause** — never one row claiming three behaviours it only touched one of. **Retest-bug numbering (layers 1–2):** a retest's ids follow the bug ticket's own item numbering, so a compound Expected-Result item stays **one** `ER` id and **one** verdict-table row, quoted whole — the `Expected-result coverage` denominator equals the ticket's item count. Each clause is still its own Step 2c case and is checked inside that row; the row is PASSED only when every clause was exercised and met (`retest-bug-workflow/WORKFLOW.md` § Step 2). |
| **3** | **Execute each on its real surface** | Every enumerated id is **actually exercised and observed** — never inferred from a sibling item, never assumed-covered because "the happy path passed". An id you could not reach is an **explicit BLOCKED row** with the reason + who/what is needed — never quietly left off the table. |
| **4** | **Row, never a remark (anti-footnote)** | Every enumerated id's result is its **own table row** carrying a verdict + evidence cell. It is **forbidden** to record an AC/EC/bug-detail observation **only** in a remark / "หมายเหตุ" / note below-or-beside the table / a trailing paragraph / chat-only. A remark can add context **to** a row; it is **never** the sole place an AC/EC item is recorded. If it deserves a mention, it deserves a row. |
| **5** | **Verdict integrity — partial coverage ≠ PASS** | A case/scenario/retest is **PASSED only when every id it covers met its expected** (char-exact where wording is specified). A covered id **not yet observed / not reached** cannot make the case PASS — its honest status is **BLOCKED** (or go re-test it), **never a product FAILED**: an untested item is a coverage gap, not a defect ([Bug Priority & Severity Matrix](bug-priority-matrix.md)). A covered id **observed to differ** from its expected = a **FAILED / PWMI row for that point**, severity judged only by the [matrix](bug-priority-matrix.md) — never a PASS with the exception hidden in a remark. Either way, "works except one point" is a **row**, not a footnote on a green case. |
| **6** | **Reconcile the count before "done"** | Before any summary / verdict / post / external write: `enumerated in-scope ids == rows carrying a verdict + evidence (or an explicit BLOCKED reason)`. **Every id appears as a row; no id lives only in a remark; no row is verdict-less; no id is left `NOT TESTED`.** The **only** id allowed off the table is one **explicitly excluded from scope at the confirm gate** — and it is listed in a visible **Out-of-scope** block, never silently dropped. Any other shortfall fails the gate. |
| **7** | **Fail-closed = not complete** | Layer 6 not green ⇒ the story/retest is **NOT complete**: do **not** report "PASSED" / "100%" / "complete", do **not** proceed to the external results update / Jira transition / notify, do **not** close the session. Return to the first unmet layer — add the missing row, run the untested id, re-verdict the partial case — then re-run from layer 1. Partial AC/EC coverage is a **stop condition**, not a remark. **Unattended / bot mode:** resolve instead of halting — an unrun or unreachable id becomes a **BLOCKED row** with its reason, and the case/story is reported **incomplete / not-all-passed**; a bot **never** silently marks it PASSED or drops the id. |

**Fail-closed:** any layer red ⇒ close the gap and re-run the gate. A case reported PASSED whose AC/EC
list is only partially rowed-and-verdicted is treated as **not done**, no matter how the untested item
was footnoted.

### Coverage red flags — STOP, you are about to pass on partial coverage

- "The main flow passed, this one AC is edge-casey" → it is still a row. Test it or BLOCK it, don't drop it.
- "I'll just note the remaining point in the remark / หมายเหตุ" → the point is a **row**, not a note.
- "AC says A and B and C; I checked A, close enough" → one row per clause; B and C are untested until rowed.
- "It's covered by another case" → then cite that case's row; an id with no row anywhere is uncovered.
- "PASSED with a minor caveat below the table" → partial coverage/deviation is a FAILED/PWMI row, not a caveat.
- "Enumerated 9 items, table has 6 rows, but the summary reads complete" → 6 ≠ 9 → not done. Reconcile first.

**All of these mean: add the row (or a BLOCKED row), give it a verdict + evidence, then re-run layer 6.**

## Pre-delivery completeness — 7-layer defense gate (before handing results to the requester)

**The last gate. It runs after the other gates, immediately before anything leaves your hands** — the
Jira comment, the results sheet write, the Discord notify, or simply telling the requester the round is
done. Its job is one question: *is what I am about to hand over actually complete, or does it merely
look complete?*

**The bar is an adversarial reviewer, not a friendly one.** Judge the deliverable as if a second QA —
or another AI given the ticket, the deliverable and nothing else — has been told: *"find where this
was cut short."* Every layer below therefore names the attack it must survive. A layer is green only
when the attack **fails against the artifacts as delivered** — not when you personally remember doing
the work. **Fail-closed: any layer red means nothing is delivered yet.**

**Document review / audit (tc-review, catch-ai):** that skill's SKILL.md maps these layers; layer 6's
Out-of-scope block never names an item that skill says to leave unmentioned.

| # | Layer | Passes only when | Reviewer attack it must survive |
|:--:|---|---|---|
| **1** | **Recount the scope from the source, this round** | Reopen the ticket / case / bug **now** and re-extract the three lists (roles · steps · AC-EC-ER ids) plus the case list itself. **`capture/evidence_plan.py <KEY>` does this mechanically** — it reads the bug's own content fields (a tracker may keep them in custom fields and leave `description` empty, so a reader that looks only there enumerates nothing); tool missing → recount by hand and say so in the record ([dependencies.md](dependencies.md)), resolves roles from the reviewed `role_lexicon.json`, and writes the filename of every clip and still that must exist. A ticket whose text matches no role term is reported `unresolved` rather than guessed. The deliverable is measured against **that** list, not against the plan written earlier in the session — a plan can be stale, the ticket cannot. Any item present in the source and absent from the deliverable is a gap, not a judgement call. | *"I read the ticket and counted 9 testable items; your table has 7. Which two are missing and why?"* — you must be able to answer with the same count they get. |
| **2** | **Role × case matrix is full** | Every (role, case) pair required by layer 1 carries a row with its own verdict. The plan's `requiredFiles` is that matrix in file form. **No empty cell, no cell inheriting another role's result**, no role quietly dropped. A pair that could not be run is a **BLOCKED row naming the role and the blocker** — visible in the deliverable, not in chat. | *"The ticket names 5 roles. Show me the 5 evidence sets. If one is missing, show me the BLOCKED row that says so."* |
| **3** | **Open every evidence file, not a sample** | **`capture/evidence_reconcile.py <KEY>_evidence_plan.json --dir out/ [--jira]`** does exactly this: it diffs the plan against what was captured, opens and measures every file (`verify_video.py` for a clip, `verify_shot.py` for a still), and with `--jira` fetches each attachment from the ticket so "the link resolves" stops being a claim. It prints the handover line below and exits non-zero when anything is missing. For each row that carries evidence — a BLOCKED row carries a reason instead, and is exempt: the link resolves, the MP4 plays and is non-blank, it is **that case and that role**, and the ER moment is **visibly in it**. Counting files is not this layer; opening them is. **Passing it must leave a trace** — mark each row as checked (`✔ opened <date>` in its evidence cell, or the verifier's output kept with the run) — because a layer whose only record is your memory is the one that gets marked green from memory. | *"I opened row 4's clip. It ends before the panel is on screen. Where is the ER?"* — a clip that stops short is caught by whoever opens it, so open it first. |
| **4** | **Every claim points at a row** | Each result sentence in the summary/comment names the row or file behind it. Anything you cannot point at is deleted or demoted to an explicit open question — never smoothed into the narrative. Hedging words (`should`, `seems`, `likely`, `น่าจะ`) in a delivered result = layer red. | *"You wrote 'works on all roles'. Point at the rows. All of them."* |
| **5** | **Verdict ↔ bug ↔ priority ↔ remark all agree** | Verdict wording follows the rubric; a minor-issue verdict carries a linked Lowest/Low/Medium bug with its Priority stated; FAILED carries a High/Highest bug; priority comes only from the Bug Priority & Severity Matrix ([bug-priority-matrix.md](bug-priority-matrix.md)); no remark contradicts the status it sits beside. | *"This row says PASSED and its remark says the count was wrong. Which one is true?"* |
| **6** | **Nothing lives only in prose** | The anti-footnote rule of the AC/EC gate (layer 4) applied to the finished deliverable: no role, step, AC/EC item or observed deviation exists **only** in a remark / "หมายเหตุ" / note under the table / chat message, and anything deliberately excluded appears in a visible **Out-of-scope** block agreed at the confirm gate. | *"Your note mentions a second entry point. There is no row for it. Was it tested?"* |
| **7** | **Adversarial pass, then fail-closed handover** | Run the adversarial pass below and answer **every** question with a pointer. Only then: post / write the sheet / notify / say "done". Any red: close the gap and re-run from layer 1. If an item genuinely cannot be completed, deliver everything else **and state plainly what is missing and why** — an incomplete result reported honestly is deliverable; a complete-looking result with a silent hole is not. **Unattended / bot mode:** resolve instead of halting, exactly as the AC/EC gate's layer 7 does — an unrun or unverifiable item becomes a **BLOCKED row** with its reason and the run is reported **incomplete / not-all-passed**; a bot never emits nothing, and never silently marks it PASSED. | *"What did you not test, and where does the deliverable say so?"* — the honest answer must already be written down, not produced when asked. |

### Adversarial review pass — read your own deliverable as the reviewer hunting for the shortcut

Before layer 7 signs off, re-read the deliverable **as artifacts only** — the table, the files, the
comment — with the working memory of what you did set aside; the reviewer does not have it. Answer
each question by **pointing at something**, not by recalling. **One unanswerable question = layer 7 red.**

1. Pick the row whose evidence you are **least** sure about. Open it. Does it show that case, that role, that ER?
2. Which clip is the **shortest**? Open it — did the flow reach the target, or did the recording stop early?
3. Which verified value is the **hardest to read** on screen? Is there a still that makes it legible?
4. If the reviewer replaced you and had only these artifacts — could they reproduce every verdict without asking you a single question? What did you **not** test, and where does the deliverable say so?

**Report line to the requester** — the handover states, in one line each: cases run / total, roles
covered / roles named, evidence files opened-and-verified this round, and every BLOCKED item with its
reason. A handover with none of those numbers has not passed layer 7.
