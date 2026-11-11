# Test execution plan (testing ticket)

Fill **before** running Playwright (Phase B/C in `testing-ticket-workflow`). User approves this plan; then run tests.

```markdown
## Test execution plan — {ISSUE-KEY}

**Environment:** {pd3 | dev | other URL}
**Branch / build:** {if known}
**Auth:** {storageState file | role | login steps}
**Preflight:** [ ] [playwright-preflight.md](playwright-preflight.md) checklist done — YES/NO

### AC/EC enumeration (coverage gate layer 1 — char-exact)

List every Acceptance Criteria / Expected-Condition line from the ticket, one id per testable assertion (split compound "A and B" into `AC2a` / `AC2b`):

| AC/EC id | Assertion (verbatim) |
|----------|----------------------|
| AC1 | |
| AC2 | |

### In scope (coverage gate layer 2 — every AC/EC id maps to ≥1 row)

| # | Scenario | AC/EC id(s) | Width | Spec / path | Data setup |
|---|----------|-------------|-------|-------------|------------|
| 1 | | | 1440 | | |
| 2 | | | 390 | | |

One row per scenario x width: a scenario in scope at 1440 and 390 is two rows, not "1440 · 390" in one cell. A scenario with no layout dependence (for example a pure API check) uses one row with Width = n/a.

**Coverage check:** every AC/EC id above appears in the `AC/EC id(s)` column of ≥1 scenario. An id with no scenario = a gap → add the scenario (or move it to Out of scope with a reason). Do not confirm the plan until every enumerated id is covered or explicitly excluded. An id is not covered at a width it has no row for.

**Reconcile (after the run):** every plan row (scenario x width) has a results row; a plan row with no results row is reported as a mismatch in the summary and does not block the run.

### Execution lanes

The plan always shows both lane rows, L1 and L2, one account per lane ([parallel-test-lanes.md](parallel-test-lanes.md)). If fewer than two accounts are leasable, keep the L2 row and write the reason in it (serial plan only with a named §4 predicate).

| Lane | Account (role) | Scenario # | Order | Data prefix |
|------|----------------|------------|-------|-------------|
| L1 | | | | QA-L1 |
| L2 | | | | QA-L2 |

**Starting state:** {the state each lane begins in: logged-in user id, toggles/flags, record status, data it needs — checked before the first scenario}

### Out of scope

- {each out-of-scope width as width + reason, never as a row in the In-scope table}
- {explicit exclusions — an AC/EC id deferred here is listed by id + reason, never silently dropped}

### Evidence to collect

- [ ] Playwright HTML report path
- [ ] Screenshots on failure
- [ ] Trace on failure (retain path)
- [ ] API/network note if UI blocked

### Pass criteria

- All in-scope scenarios **PASSED** with fresh runner output (see [qa-evidence-gates.md](qa-evidence-gates.md))
- **Every enumerated AC/EC id is rowed-and-verdicted** — `enumerated in-scope ids == rows carrying a verdict + evidence` (AC/EC coverage gate layer 6); none parked only in a remark, none left `NOT TESTED`
- Every BLOCKED row carries its cause and is queued for the end decisions popup

### Risks

| Risk | Mitigation |
|------|------------|
| VPN / CF | preflight |
| Flaky selector | {wait strategy} |

**Approved by user:** [ ] YES — proceed to run
```

After run, attach results to Jira draft per workflow — do not post until user approves comment text.
