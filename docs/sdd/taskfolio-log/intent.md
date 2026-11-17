# Intent — taskfolio-log

Written in the originator's own words, before `spec.md`. Spec: docs/sdd/ai-native-sdlc-alignment R1.

## What is wanted

From fork PR Thitic9203/ols-qa#127 (author Samornseepralad), a port of Thitic9203/helix#20: "the new
`taskfolio-log-workflow` skill (`/taskfolio-log`, menu item 13; Other moves to 14). It fills the user's own
Taskfolio timesheet for the current week from evidence (Jira changes, bugs opened, Slack, Google Calendar)."

## Why

So timesheet entries are taken from what the user actually did each day, not typed from memory; a
time/project/completeness gate runs before saving and every saved entry is re-read. The week is never
submitted by the agent.

## Constraints

Free (local AppleScript + existing connectors; no new spend). Never clicks Submit week. Writes only after
the user confirms. Helix is not touched here — the helix sync runs from main after merge (CLAUDE.md, helix sync rule).

## Reviewed by owner on 2026-11-12

2026-11-12 — owner approved re-landing #127 with a spec: "เขียน spec แล้วเปิด PR ใหม่" (relayed by the main thread).
Owner review of this file's exact text happens on the docs PR.
