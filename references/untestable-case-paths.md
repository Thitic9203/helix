# Untestable-looking cases — find the honest way to test them

## Contents

- [0. When this applies](#0-when-this-applies)
- [1. Classify the real cause before any verdict](#1-classify-the-real-cause-before-any-verdict)
- [2. Ticket and app disagree — decide it yourself](#2-ticket-and-app-disagree--decide-it-yourself)
- [3. External device or scan step](#3-external-device-or-scan-step)
- [4. No suitable account](#4-no-suitable-account)
- [5. Missing data — create it in the test](#5-missing-data--create-it-in-the-test)
- [6. Responsive failures that are test-side](#6-responsive-failures-that-are-test-side)
- [7. The environment broke the run](#7-the-environment-broke-the-run)
- [8. By-design skips in the result tool](#8-by-design-skips-in-the-result-tool)
- [MUST / NEVER](#must--never)

## 0. When this applies

Only when a case is skipped, BLOCKED, or not PASSED and the first explanation is "cannot be tested" —
no data, no account, a phone or scan step, a ticket that disagrees with the app, a layout that hides a
control, or a broken run. "Cannot be tested" is a starting hypothesis; this file lists the ways
past it. It extends [no-wait-decision-gate.md](no-wait-decision-gate.md) (layers 13–16) and feeds
[non-pass-challenge-gate.md](non-pass-challenge-gate.md) and [root-cause-investigation.md](root-cause-investigation.md);
it never replaces them.

## 1. Classify the real cause before any verdict

A skip or not-passed is never accepted from its error line. For each case read: the skip condition or
assertion in the test code, the app code at the tested commit (`path:line`), the ticket with every
comment, its parent, linked and later tickets with their comments. Then give it exactly one cause:

| Cause | Meaning | Next |
|---|---|---|
| **test** | selector, wait, helper, stale skip reason, wrong fixture choice | fix the test, re-run |
| **data** | the state the case needs does not exist | §4, §5 |
| **env** | network, VPN, callback, service down, wrong env | §3, §7 |
| **spec-question** | ticket sources disagree with each other | §2 |
| **app-differs** | a clear ticket line and the app differ | §2, bug gate |
| **by-design** | the case does not apply to this project or viewport by a written source | §8 |

Record cause + evidence (`path:line`, ticket and comment link) per case. An old skip reason that
blames a ticket is re-checked: if that ticket is Done or superseded, the skip is outdated (cause **test**).

## 2. Ticket and app disagree — decide it yourself

Decide from sources, in this order of weight: a later Done ticket on the same screen, PO or QA retest
comments ("tested on dev: passed" on a later behaviour), the commit and PR that made the behaviour (its
message and linked ticket), the design tool's frames for each breakpoint. A later source that covers
the point is the expected; assert it and cite it.

With no later source, the ticket line is the expected: assert that line verbatim. If the app differs,
the case is a FAIL candidate that goes through the project's bug gate (scope check, approval) like any
other — it is never parked as "waiting for the PO". A genuinely hedged or self-contradicting spec with
no later decision stays under [no-wait-decision-gate.md](no-wait-decision-gate.md) layer 17.
Where the workflow's challenge gate gives a superseded expected its own outcome
([non-pass-challenge-gate.md](non-pass-challenge-gate.md) §2, retest's bug-ER rules), that outcome still applies.

## 3. External device or scan step

A step that needs a phone app, a card reader or a QR scan (for example a national identity app):

1. Look for the provider's **sandbox or test mode** (typed test ID, test card) that keeps the real
   server-to-server exchange. The product's own server code must still run.
2. Find an environment whose callback the provider accepts. Probe each env's start URL with a plain
   GET (sandbox page vs error status) and record the result with the date.
3. Never mock the identity or provider data (no route mock of the post-login page); that fakes the
   result. A provider that only works in production with a real device is not automatable honestly:
   record it, do not simulate it.
4. Label the simulated hop in the result ("sandbox typed-ID confirm instead of the phone app") and the
   environment + commit the result came from.
5. Moving a case to another environment needs the owner's OK; record the exception and switch back
   when the default environment's probe passes.

## 4. No suitable account

Before saying no account fits, search: the project's account sheet or roster, and the app's admin user
list or API, filtering on the attributes the case needs (signed in before or not, role, affiliation,
grade or plan, locked fields). Record what was checked and why each candidate fails. Create a new
account only through a real product path (sign-up, provider sandbox, admin invite) and only with the
owner's OK; never write rows straight into a database.

## 5. Missing data — create it in the test

Create the state in the test through the product's real API or UI, on QA-owned items only:

- an unlock that needs completion → call the progress API for every item, reload, poll for the state;
- an item in a status → create it, move it through the allowed transitions (submit, approve with the
  allowed reviewer accounts, request-edit); a delete that the current status refuses goes through the
  transition that allows it first;
- a list that needs one more entry → the project's seed helper, or one permanent QA-owned record
  (for example a comment) that later runs reuse;
- data a desktop case consumed → the responsive twin uses another item type or files its own.

Clean up through allowed transitions; keep a ledger of created ids. A shared item that the test would
move to another status is never edited — make a throwaway one.

## 6. Responsive failures that are test-side

Below a breakpoint the same control is often still in the DOM but hidden, or moved. Locate by the
**visible** control, never by DOM order or `innerText` (which also reads `display:none` nodes):

- duplicate elements per breakpoint (a hidden desktop badge or button) → filter to visible;
- table replaced by cards (with a tap overlay) → a card-aware reader and opener;
- actions moved into a "more" menu, a filter sheet or a navigation drawer → open it first;
- chip or card rows folded after N items → expand ("more") first;
- controls that show only on hover or after a tap on touch devices → tap, wait for visible, then act;
- mobile lanes that send a headless user agent → set the real mobile user agent in the fixture.

Read the component code for the breakpoint before changing the test.

## 7. The environment broke the run

When the environment fails mid-run (VPN drop, login service unreachable), rerun **only the broken
projects, whole, at the same commit**, and count only that rerun for them. Record the break, the time,
and which projects were replaced. This replaces broken results; it is never a retry of a failing test
until it turns green.

## 8. By-design skips in the result tool

A test-management tool that maps every skip to "blocked" makes a by-design skip (a case that does not
apply to a viewport or project) look like an open problem. Record each by-design skip with its written
source (spec line, design frame, code `path:line`) and report it apart from real blocked cases.

## MUST / NEVER

| Rule | Why |
|---|---|
| MUST classify every skip and not-passed case with one cause from §1 and its evidence | An error line names a symptom, not a cause |
| MUST decide a ticket-vs-app conflict from later sources, else assert the ticket line verbatim (§2) | Parking it for the PO leaves the case unfinished |
| NEVER mock identity or provider data to pass a device step (§3) | The result would show a flow that never ran |
| MUST label every simulated hop and the environment + commit of the result | A reader must see what was real |
| NEVER create an account or switch environment without the owner's OK (§3, §4) | Shared environments and accounts are not QA's alone |
| NEVER edit a shared item to make a state; create a throwaway one (§5) | Other tests and users depend on it |
| NEVER retry a failing test to green; rerun only environment-broken projects whole at the same commit (§7) | A retry hides a flaky or real failure |
