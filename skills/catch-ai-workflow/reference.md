# CatchAI Reference

## Contents

- [Review targets and their governing source](#review-targets-and-their-governing-source)
- [Evidence standard](#evidence-standard)
- [Audit dimensions](#audit-dimensions)
- [Coverage matrix](#coverage-matrix)
- [Severity](#severity)
- [Verdict](#verdict)
- [Remediation and prevention](#remediation-and-prevention)
- [Result quality gate in an audit](#result-quality-gate-in-an-audit)
- [Report template](#report-template)

## Review targets and their governing source

| Target | What to audit | Governing source |
|---|---|---|
| Your own prior work | Files written, commands run, numbers quoted, conclusions | The file on disk, real command output, the ticket, the original request |
| Document / deliverable | Facts, figures, structure, terminology, internal consistency | The system it describes, the data it cites, sibling documents, house convention |
| System / feature under test | Behaviour, UI, API responses, data, error paths, non-functional bars | Spec, Figma, AC, OpenAPI/Swagger, DB schema, design tokens |
| Test artifacts | Test cases, coverage, assertions, CI gates | The requirement each case traces to; the run's real output |

A source *governs* a claim only when it defines what the claim should be; a correlating proxy (file timestamp, sibling page) governs nothing.

## Evidence standard

Every reported item carries all five or is not reported:

- **Expected** — quoted verbatim **with its governing source** (`Figma: <frame>`, `AC-3`, `swagger:/v1/users`, `path:line`).
- **Actual** — quoted verbatim, with where (`path:line`, URL, endpoint, command).
- **Reproduce** — the exact steps, command or request that shows it again.
- **Environment** — branch/commit, env, browser/viewport, data set, when the result can differ by them.
- **Impact** — who or what breaks, concretely.

## Audit dimensions

| Dimension | What to look for |
|---|---|
| Facts and numbers | Figures, dates, versions, paths, ids, calculations, quoted output that disagree with the source |
| Spec conformance | Labels, copy, field names, states, validation, flows — character-exact |
| Completeness | Items not delivered, caveats omitted, steps skipped, scope narrowed |
| Coverage gaps | Requirements with no check; untested error paths, boundaries, permissions, empty/max states |
| Consistency | Statements conflicting with each other, the code, sibling docs or earlier facts |
| Evidence and assumptions | "Passing", "safe", "deployed", "verified" with nothing behind it |
| Data integrity | Rounding, totals, windows, timezone, locale, sort/paging that change the answer |
| Non-functional bars | Accessibility, responsive, contrast, touch targets, performance, security |
| Regression risk | Other consumers of the changed code, field, route or token, and whether checked |
| Document quality | Structure vs sibling pages, headings, placeholders, dead links, stale figures |

## Coverage matrix

Build it before the report.

| Requirement / area | Checked by | Level | Gap |
|---|---|---|---|
| `<requirement or path>` | `<test, command, manual check, or "none">` | unit / integration / E2E / manual / none | `<what nothing covers>` |

Weight depth by risk: critical paths, error handling, boundaries, security and data integrity earn real coverage; trivial code does not. Every area at level **none** is a coverage gap, reported apart from defects (missing information, not a failure).

## Severity

| Severity | Meaning |
|---|---|
| Blocker | Blocks release or makes the deliverable unusable; data loss, security exposure, broken primary flow |
| Major | Core behaviour or a stated requirement wrong; a correct-looking number wrong; a stated quality bar missed ("it works" but below its source's bar) |
| Minor | Real but contained — cosmetic drift, wording, non-blocking inconsistency |
| Question | Expected or actual side unconfirmed; needs the spec owner or access |

An **unsourced claim** is its own class when the deliverable declares where its content comes from: "this line is traceable to nothing". Major when the claim is load-bearing and Minor when it is incidental (load-bearing = a reader acts on it: a figure, a support/compatibility list, a requirement; incidental = attribution, owner, author). Own tally ("Unsourced claims: N"); not added to the Defect count. Correction: "cite the source or remove the line". Never pair it with an asserted true value you could not observe; that value is a separate Question.

## Verdict

| Verdict | When |
|---|---|
| PASSED | Every checked item matched its governing source, and no coverage gap is Blocker or Major (a gap ranks as its item would if defective) |
| PWMI (PASSED WITH MINOR ISSUE) | At least one defect confirmed and none reaches FAILED: every product bug's matrix row is Lowest / Low / Medium ([bug-priority-matrix.md](../../references/bug-priority-matrix.md) § Hard rule), and every other finding is Minor |
| FAILED | A product bug whose matrix row is High / Highest; a Blocker or Major finding where no matrix row applies; or a result that changes between identical runs |
| BLOCKED | The expected side could not be confirmed for a material part of the scope (defined below) |
| No issue found | Checks ran, nothing survived verification — not the same as "did not check" |

A test case with an open coverage gap follows the matrix § Hard rule: BLOCKED with what is missing, never PASSED with a caveat; the PASSED row's gap test is for a document or your own prior work.

**Severity → matrix → verdict.** Blocker / Major / Minor rank findings in this report. A product bug (system under test, or an audited test verdict) takes its Priority from the matrix cheat-sheet, and the matrix decides the verdict (cite the row per its *Verdict line format*); if they disagree, the matrix wins and the label is corrected. A document or your own prior work (no matrix row): Blocker or Major → FAILED, Minor only → PWMI.

**Material part of the scope** = any item that would be Blocker or Major if defective (a primary flow, a load-bearing figure, a support/compatibility statement, a stated requirement). Unconfirmable Minor-only items do not make the run BLOCKED — give the verdict for the rest and list each as a Question.

## Remediation and prevention

Every defect gets two sourced answers: what fixes this instance, and what stops it coming back.

### Root cause before fix

Ask "why?" until the answer stops moving: (a) the owning layer is named with evidence (the file:line, config key, data row or document section that produces it), or (b) the next "why" leaves what the owner controls (external system, vendor) — name that boundary; what lies beyond is a Question. Stop at the owning layer, not where it surfaced.

A fix at the symptom (dedupe the list in the UI) or where it surfaced (round the report number) is rejected; a fix at the owning layer (the JOIN that multiplies rows) is accepted.

Cause unreachable (not reproducible, no access, external) → say so and recommend instrumentation to catch it next time.

### Prevention layers

Pick the cheapest layer that makes recurrence impossible, not merely unlikely (higher = stronger).

| Layer | Makes recurrence | Use when |
|---|---|---|
| Type or schema constraint | Impossible to express | The wrong state can be modelled away |
| Database constraint / migration | Impossible to store | Integrity, uniqueness, referential rules |
| Lint or static rule | Impossible to merge | The mistake has a syntactic signature |
| Regression test | Caught before merge | Behaviour can be asserted — must fail without the fix |
| CI gate | Caught before deploy | Coverage, contract, budget or conformance thresholds |
| Runtime validation at the boundary | Caught before damage | Input from users, external APIs, files, config |
| Monitoring or alert | Caught after the fact | Nothing earlier can observe it |
| Documentation or convention note | Relies on people remembering | Nothing above applies — say plainly that recurrence is only signposted, not prevented |

### Citation rules

1. **Open the source in this session** — an unread citation is fabrication.
2. **Quote the sentence that carries the rule**, not the page title.
3. **Version and date** for an external document ("React 19.2 docs, accessed 2026-09-10"); a workspace file by `path:line` and heading, never commit hash.
4. **Prefer the governing source** over one that mentions it (language spec over a blog, project convention over a general standard).
5. **Nothing governs it → label `Judgment`** with the trade-off; never dress judgment as a standard.

### Standard source registry

Cite the authority that defines the claim.

| Domain | Authority to cite |
|---|---|
| Accessibility, web platform | W3C WCAG, WAI-ARIA Authoring Practices; W3C/WHATWG spec, MDN |
| HTTP, URI, JSON, auth | The defining IETF RFC; OAuth/OIDC specs |
| Application security | OWASP Top 10, ASVS, cheat sheets; CWE |
| Library, framework, language | Official docs at the version in use, changelog, migration guide; the language spec |
| An API you consume | Its OpenAPI/Swagger document or official reference |
| Data shape and constraints | DB schema, migrations, or the repository contract |
| Testing terminology | ISTQB glossary; test framework docs |
| Repository convention | The project's CLAUDE.md, AGENTS.md, ADRs, style guide or lint config |

### Remediation entry template

```
Fix (Recommendation | Judgment)
- Root cause: <the owning layer and why it produces this> — Confirmed | Suspected | Unknown (only Confirmed closes the defect)
- Change: <the concrete edit, file, or configuration>
- Sources:
  - <title>, <exact section or heading> — <URL> (version <x>, accessed <YYYY-MM-DD>) | <path:line, heading> for a workspace file
    > "<quoted sentence that carries the rule>"
- Prevention: <layer from the table> — <the specific test, constraint, rule, or gate>
- Verification: <command or check that proves the fix, and its expected output>
- Trade-off: <what this costs; required when labelled Judgment>
```

## Result quality gate in an audit

How [SKILL.md § Result quality gate](SKILL.md#result-quality-gate-mandatory-before-an-audited-verdict-is-confirmed-low-freedom) runs when the audit does not own the run.

- Result lines: one final result line per case from the audited run's log (its own words, older lines `superseded`), kept in the report's record.
- Mechanical layers: `node tools/result-gate/check.js` with the arguments in [its step 2](../../references/result-quality-gate.md#how-to-run-it); paste its last line. No `tools/result-gate/` → walk all 20 layers by hand, count them, and say so ([dependencies.md](../../references/dependencies.md)).
- Checker exits 2 (no results.jsonl / cases.json / env-map.json / types.json in the input, so nothing was checked — not a pass) → walk the 20 layers by hand on the audited run's log; record `checker had no input; by hand`.
- A layer that asks for an action (layer 14 step 6, layer 18) or that a pre-run check decides (account source, session/build preflight, fixture) is judged from what the run recorded; the read-only rule wins, so the audit never creates data. Nothing recorded → red: BLOCKED for sending.
- **Flaky case** (results differ between identical runs): the source supports FAILED (layer 16); an earlier PASSED is a Defect in the audited work. Write `FAILED (intermittent, {failed_attempts} of {attempts})` in the correction and case line — never "not confirmable", never BLOCKED alone, never PASSED; a red layer adds its hold beside it (`TC-n — FAILED (intermittent, 1 of 2) per run log · BLOCKED for sending: layer 17, no accepted clip`).
- **Claim matches its source, evidence not in the audit input** (work PASSED, log PASS): Clean. List `evidence not provided for TC-n` once under coverage gaps as a Question, not a Defect, unless the audited work states evidence it lacks. A red layer (e.g. layer 9) still holds that case BLOCKED for sending.

## Report template

```
Verdict: PASSED | PWMI | FAILED | BLOCKED | No issue found
Scope: <what was audited> · Out of scope: <what was not>
Result quality gate: <checker's last output line | by hand, N layers × M cases | N/A — no test verdict in scope>

## Classification
| # | Item | Expected + source | Actual | Class |
Defects (actual ≠ sourced expected): N · Unsourced claims: N · Questions: N · Clean: N
<after a red-flag re-run only: the exit line from SKILL.md § Red flags>

## Defects
### 1. [Blocker] <short title>
- Expected: "<verbatim>" (source: <Figma frame / AC-3 / path:line>)
- Actual:   "<verbatim>" (<path:line / URL / endpoint>)
- Reproduce: <steps or command>
- Environment: <branch/commit, env, viewport>
- Impact: <who or what breaks>
- Correction: <the proposed fix, or the corrected statement — applied only after the owner approves it>

## Unsourced claims (not in the Defect count)
- [Major | Minor] "<verbatim line>" (<path:line>) — Correction: cite the source or remove the line

## Questions (expected or actual side unconfirmed)
- <item> — need <source or access> to confirm <exact point>

## Coverage gaps
- <requirement> — no check at any level

## Remediation
One remediation entry (template above) per defect, same number.

## Checked, no issue found
- <item> — verified against <source>
```

Nothing survived → write `No issue found.`, then what was checked against which source.

A hedged conclusion in the audited work goes under Defects as `[<severity>] Hedged conclusion — <the claim>`: Actual = the hedged sentence, Correction = the `Confirmed` answer with its artifact (SKILL.md § Hedged conclusions).
