# QA evidence — re-recording delivered evidence

Split from [qa-evidence-gates.md](qa-evidence-gates.md) (core gate function, claim → evidence map, wording red flags). The 6-layer gate (R1–R6) for replacing evidence that was already delivered. Open this before any re-take of a delivered clip.

## Contents

- [Re-recording evidence that was already delivered — 6-layer gate (mandatory, fail-closed)](#re-recording-evidence-that-was-already-delivered--6-layer-gate-mandatory-fail-closed)
  - [Why R2 exists — the shape it keeps catching](#why-r2-exists--the-shape-it-keeps-catching)
  - [Fixture selection when the demonstration burns the fixture](#fixture-selection-when-the-demonstration-burns-the-fixture)
  - [Replacing the delivered file without breaking anything](#replacing-the-delivered-file-without-breaking-anything)

## Re-recording evidence that was already delivered — 6-layer gate (mandatory, fail-closed)

A clip that is **already in the customer's hands** is a different job from a fresh capture. The
result cell says PASSED, a frozen sheet links the file by id, and the reason it is being redone is
usually that **the old clip never actually proved its Expected Result**. Every layer below exists
because skipping it costs a whole take — and some takes cannot be repeated at all.

| # | Layer | Passes only when |
|:--:|---|---|
| **R1** | **Read the old run's own result artifact, not just the video** | The previous capture's machine-readable result (`*.result.json`, run log, manifest) has been opened and quoted. **A run that recorded its own failure and was delivered anyway is the normal case, not the exception** — if the old artifact already says the assertion was false, that is the finding, and it goes in the report. |
| **R2** | **Prove the ER is demonstrable in this environment before recording** | The mechanism behind the ER has been exercised **once, outside the recorder**, and observed to produce the change the ER describes. No probe = no take. A 3-minute clip of a counter that cannot move is not evidence, it is the old defect re-filmed. |
| **R3** | **Search the team's own stores before theorising** | The regression sheet's remark/comment columns and the bug rows have been searched for the behaviour in question. The answer is often already written there by whoever hit it first — reading it costs one query and replaces an hour of hypotheses. Cite the row. |
| **R4** | **Single-use demonstrations are budgeted before the take** | When the demonstration **consumes state** (a one-per-viewer counter, a one-shot flow, a token that burns on use), the fixtures are pre-selected and **verified fresh from a source that does not consume them**. Probing a fixture spends it. Enumerate the fresh ones, keep spares, and never open one "just to check". |
| **R5** | **The recorder asserts the ER and exits non-zero when it fails** | The capture script reads the outcome back **from the authoritative source** (API / DB read, not the rendered number it just showed) and compares before → after. Assertion false ⇒ non-zero exit ⇒ **nothing is delivered**. A clip is never judged by eye alone, and never shipped on "it looked right". |
| **R6** | **Replaced in place, then read back and compared** | The delivered file is replaced **by id** — same file id, same name, same folder — so a frozen sheet's `=HYPERLINK(...)` keeps resolving. Then the file is **downloaded again** and its checksum compared to the local artifact. Same-name-new-upload mints a new id and silently orphans the link. |

**Fail-closed:** any layer red ⇒ do not record, or do not deliver. R2 and R4 are the two that
actually save the day: without R2 the take is wasted, and without R4 the take **cannot be retried**
because the fixtures it needed are gone.

### Why R2 exists — the shape it keeps catching

Some Expected Results are only demonstrable under conditions the test environment does not
automatically provide. The pattern to look for before recording:

- **Counters that dedupe.** A "views increased" ER can be backed by a *distinct-viewer* counter keyed
  on the caller's IP — one IP adds at most one view to a given item, **ever**. Every machine behind
  one VPN egress shares that quota, so a counter that has already been incremented from that IP will
  never move again no matter how many times the flow is repeated. The clip then shows the flow
  working and the number frozen, which reads as a defect that is not there.
- **Endpoints that accept and do nothing.** The write can answer `204` and still change no state
  (already-counted), or answer `500` for specific records while working for their siblings. **Both
  look identical from the UI.** Watch the response, not the screen.
- **The same ER on a sibling entity can be routed elsewhere.** A per-entity counter can exist on one
  entity type and be broken or absent on another. Verify the exact entity type the case names.

**What to do when the ER is not demonstrable here:** that is a **BLOCKED** with the reason and the
measurement behind it — never a shorter clip, never a re-film of the same non-proof. State what
condition would make it demonstrable (a fixture nothing has viewed, a different egress, a fresh
record) and let the requester choose.

### Fixture selection when the demonstration burns the fixture

- **Enumerate from a list endpoint, not by opening things.** Reading a catalogue does not consume a
  fixture; opening one does.
- **Exclude, in this order, before ranking by suitability:** customer-owned content (see the
  hands-off rule for marker-tagged items), then **other lanes' fixtures** — titles that say
  *ห้ามเปิด* / *ยังไม่เคยเปิด* / *(temporary)* / a `TIE`-style pairing are someone's live test state,
  and bumping their counter can break a test that is mid-flight.
- **Prefer the entity type already proven to work** in the R2 probe over an untried one; a failed
  take burns every fixture that succeeded before the failing one.
- **Say so in the report when the only remaining fixture carries a QA-ish name.** The case measures
  the behaviour, not the fixture's title — but the requester decides whether that is acceptable in a
  customer-facing clip, and they can only decide if they are told.

### Replacing the delivered file without breaking anything

- **Update content by file id** (`files.update` with media) — id, name and parents are unchanged, so
  every link that already exists keeps working, and the platform keeps the old version in history.
- **Refuse on a name mismatch.** The tool that does the replacement asks for the expected file name
  and stops if the id resolves to anything else. A wrong id silently overwrites someone else's
  deliverable.
- **Never write to a frozen deliverable sheet to "point it at the new file".** If the link already
  resolves to the id that was replaced, there is nothing to update — verify the cell's formula and
  say so.
- **Verify by readback:** download the file again and compare size + checksum against the local
  artifact. "Upload returned 200" is not verification.
