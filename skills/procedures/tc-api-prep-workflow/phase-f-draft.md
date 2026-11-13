# TC API prep — Phase F

Part of [WORKFLOW.md](WORKFLOW.md), opened at Phase F as its WORKFLOW.md section names. Every rule here is a full gate of the workflow.

## Phase F — Draft in chat (approval gate) [medium freedom]

Post the full table in the conversation using the **confirmed columns**:

```text
Draft API test cases (not published yet)

**Sources:** API spec: {summary or link} · Swagger: {url}

**Coverage:** {N} endpoints / {M} test cases

**Out of scope:** {the Phase E out-of-scope list, or none}

**Columns:** {final Phase B list} · **Priority rule:** {only when the spec states no criticality — see api-tc-guidelines § Priority}

| **Test Case ID** | **Module / Feature** | ... |
| --- | --- | --- |
| ... one row per TC ... |
```

State clearly: **Not posted / no file written yet.**

🔴 **STOP — wait for approval** or edits. Re-show changed rows after feedback.

**Go back:** If the user asks for edits, apply them and return to the start of Phase F — re-show the changed rows and wait. New scope or source, or whole draft rejected → Phase D, then Phase E again; not as row edits. Phase G starts only after approval.
