---
type: grilling
status: in-review
assignee: main-thread (session 2026-11-04)
blocked_by: [03-auto-update-policy, 04-install-path, 05-devenv-posture, 07-link-skills-overwrite]
---

# Team notice

## Question

Who receives the notice (everyone who may have installed Helix), and through which channel? What does it say: each risk in plain words, how to check whether your machine has it (from the footprint inventory), what to do now (pin, disable or undo), and when the fixed version lands? The draft is shown to the owner before anything is sent.

## Progress

- 2026-11-04: the owner chose the channel, a notice file in this repo. The draft is in [notice-draft.md](../notice-draft.md) and is waiting for owner approval. One line in it is still unverified: where to set `HELIX_AUTO_UPDATE=0` so that the SessionStart hook sees it. That line is flagged inside the draft.
