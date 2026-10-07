---
type: grilling
status: closed
assignee: main-thread (session 2026-10-07 c)
blocked_by: [01, 10, 13]
---

# Figma compare gate

## Question

Given the measured cost from the baseline, what is the minimal Figma comparison that still meets the evidence standard? Today the workflow compares every UI case, including passing ones, every round (retest :308, testing :249). Options to weigh include changed screens only, cached reference exports, and one compare per screen rather than per case. The answer must fit the allocation set by [15-minute budget](10-fifteen-minute-budget.md). Any part the user chooses to skip is recorded as an accepted risk.

## Framing (pre-baseline, no recommendation yet)

Prepared while [Baseline phase timing](01-baseline-phase-timing.md) and [15-minute budget](10-fifteen-minute-budget.md) are open. No option is marked recommended until the measured Figma cost and the budget allocation exist.

**What a comparison is made of today** (`references/figma-design-comparison.md` §2–§3, retest `WORKFLOW.md` Step 4d, testing `WORKFLOW.md` E0)

- **Design side (input):** open the node through Figma Dev Mode MCP (`get_screenshot` / `get_metadata` / `get_design_context`), or the browser fallback when the desktop app is not running.
- **App side (evidence):** the screen captured as the case runs, compared on five points (elements, char-exact text, order/position, node states, no overflow/overlap), with layout measured at every in-scope width.
- It runs per case, PASSED cases included, every round.

**Options to put to the user.** They split into two kinds: ones that remove repeated work without changing the evidence standard, and ones that skip coverage.

| # | Option | Saves | Evidence standard | Kind |
|:-:|---|---|---|---|
| A | **One compare per screen × width per round**: cases that land on the same screen in the same round share one fresh app capture and one design read | repeated design reads and repeated five-point checks | unchanged: the comparison is still fresh in this round | dedupe |
| B | **Cache the design-side export** (node screenshot + metadata), keyed by the Figma file `lastModified` fingerprint already stored by [Intake persistence](05-intake-persistence.md); re-fetch only when the fingerprint changes | MCP/browser round-trips for the design side in round 2+ | unchanged: the design is an input, not evidence; the app capture stays fresh | dedupe |
| C | **Changed screens only**: compare only the screens the fix or ticket touches; the rest go unchecked | the compare cost of every untouched screen | **reduced**: stops catching regressions and unasked defects on untouched screens (`references/customer-escape-prevention.md` §2) | skip candidate; the user decides, recorded as an accepted risk; never recommended |
| D | **Layout measurements at the widths in scope only**, without the extra breakpoint-side widths | runs per extra width | reduced where a breakpoint is named in the spec | skip candidate; same handling as C |

Per the map, A and B (the minimal gate that still meets the standard) are evaluated first. C and D go to the user only if A and B together still do not fit the allocation from ticket 10.

**Numbers needed before asking**

- Wall-clock per Figma compare: design read (MCP vs browser fallback) and the five-point check, from ticket 01's phase labels.
- Cases per distinct screen per round, which sizes the saving from A.
- The share of rounds where the Figma `lastModified` was unchanged since the previous round, which sizes the saving from B. If the transcripts cannot show this, it is reported as unmeasured, not estimated.
- The Figma budget slice per flow from ticket 10.

## Resolution

Decided with the user on 2026-10-07, using [research/13-per-gate-timing.md](../research/13-per-gate-timing.md): Figma compare takes a median of 0.5–0.6 min per round (2.3% of retest AGENT + EXEC, 0.5% of testing). **Keep the full comparison, and remove repeated work only.** (A) One compare per screen × width per round: cases on the same screen share one fresh app capture and one design read. (B) Cache the design-side export, keyed by the Figma `lastModified` fingerprint, and re-fetch only when it changes. The evidence standard is unchanged. Options C (changed screens only) and D (fewer widths) were not chosen, so no accepted risk is recorded.
