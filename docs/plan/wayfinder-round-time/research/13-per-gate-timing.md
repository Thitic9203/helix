# Research: per-gate timing

Resolves [Per-gate timing](../tickets/13-per-gate-timing.md). Measured 2026-10-07 over the 171 runs in the baseline raw data. The main thread re-ran the phase script and the headline numbers matched. Scripts and raw data stay outside this repo.

## Method

- **Phase time** runs from tool_use to tool_result. For background tools it runs until the task notification arrives.
- The model's generation gap right after a result counts toward the same phase.
- Gaps over 2 hours are dropped.
- **Share** = phase minutes divided by the run's AGENT + EXEC minutes.
- Phases are assigned by regex on tool names and commands.

## Results

**Retest:** 110 runs; AGENT + EXEC median 48.9 min per run.

| Phase | Runs with it | Median min (p75) | Share |
|---|---|---|---|
| Figma compare | 28 | 0.5 (1.0) | 2.3% |
| MP4 capture + re-captures | 26 | 1.2 (7.4) | 2.9% |
| Reviewer / self-review | 10 | 15.0 (20.8) | 2.8% |
| Guard / pre-delivery gates | 48 | 0.5 (2.0) | 0.8% |
| Ticket / Confluence / Swagger read | 102 | 2.3 (3.8) | 4.9% |
| Drafting the comment | 53 | 0.4 (0.6) | 0.5% |
| Comment edits / re-posts | 29 | 0.2 (0.7) | 0.3% |

**Testing:** 53 runs; median 64.7 min per run.

| Phase | Runs with it | Median min (p75) | Share |
|---|---|---|---|
| Figma compare | 8 | 0.6 (2.7) | 0.5% |
| MP4 capture + re-captures | 29 | 1.5 (9.0) | 4.5% |
| Reviewer / self-review | 11 | 2.7 (24.7) | 4.5% |
| Guard / pre-delivery gates | 36 | 1.4 (2.9) | 2.6% |
| Ticket / Confluence / Swagger read | 37 | 0.8 (1.6) | 1.7% |
| Drafting the comment | 25 | 0.3 (0.9) | 0.4% |
| Comment edits / re-posts | 3 | 0.2 (1.4) | 0.0% |

**Smoke:** 8 runs; median 22.1 min per run.
- Guards run in all 8 runs, with a median of 1.3 min and a 2.9% share.
- Every other phase is under 1 min or absent.

## Reading

- **The seven named gates account for only about 13–15% of AGENT + EXEC time.** The other ~85% is test runs, login, API and local tools, and generation time not attributed to any gate.
- **Gates cost most in the tail:** MP4 re-captures reach a p75 of 7–9 min, and reviewer subagents run a median of 15 min in retest (p75 about 25 min in testing).
- **Parallelism exists, but on paper.** Reads and Figma calls are batched in one message, yet still mostly serial in wall-clock terms. The retest reviewer overlapped other work for only 7.5 of 220 min, so the main thread effectively waits on it. MP4 capture launched in the background barely overlaps other work. Guards, drafting, and edits are serial.

## Comment edit loop (81 edits; 76 retest, 5 testing)

- Edits are concentrated: 11 retest runs had 3 or more edits each.
- 48 of 74 edits came less than 5 min after the previous post (median gap 1.9 min).
- **Causes:**
  - 31 were agent self-edits with no visible trigger. The agent's own notes name broken rendering or format, review findings, and media.
  - 33 were user-requested. 15 of these are uncategorised; the rest concern media, result content, wording, and format.
  - 9 followed the agent re-reading the posted comment.
- **What changed:** 34 of 74 edits changed the number of media references; 41 changed table markers.
- **Pattern:** post, notice within minutes that rendering, media or tables are wrong, then re-PUT the whole body.

## Caveats

- Phase assignment is regex-based. Some environment preflight checks may count as guards.
- Drafting written directly inside the post call is unmeasured, so drafting time is understated.
- Pixel diffs inside test scripts count as test time, not Figma.
- Background tool time overlaps other phases, so the shares must not be summed.
