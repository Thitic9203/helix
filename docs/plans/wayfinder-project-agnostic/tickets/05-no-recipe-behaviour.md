# What a skill does when a project has no guide or recipe

Type: `wayfinder:grilling` (HITL) · Status: closed · Blocked by: 04 · Assignee: Claude (main thread)

## Question

When a Helix skill runs in a project with no guide or data recipe (or a skeleton one like Pyrite's),
does it stop and report, ask the user for each value, or offer to create the guide? Which values may it
never guess (accounts, URLs, transitions)?

## Resolution (2026-11-18, Claude default from existing rules; owner said "do it all, don't ask piecemeal")

Reuse the existing "no guide" rule for every workflow, test-data-prep included:
- Ask **once per missing value**, save it immediately to the project's guide/recipe in the user's repo, no
  second "save this?" question (`workspace-guide-discovery.md:49-54, :65`).
- A skeleton recipe (e.g. Pyrite's "not configured" rows) counts as missing values for those rows.
- Never invent credentials, accounts, URLs or transitions; when a needed capability is missing, stop and
  report (`workspace-guide-discovery.md:13`).
- Secrets are never written to a repo; the guide stores only the path of the local secrets file.
Owner can override at plan approval (ticket 08).
