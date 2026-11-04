---
type: grilling
status: closed
assignee: main-thread (session 2026-11-04)
blocked_by: [01-claude-plugin-pinning]
---

# Install path and verification

## Question

How should a teammate install Helix? Options include: a pinned release tag plus a published SHA-256 checked before running; a two-step download, review, then run; or `claude plugin install` from the marketplace at a pinned version. Which one becomes the only documented path, and what happens to the `curl | bash` line in README and install.sh?

## Resolution

Decided with the owner on 2026-11-04: **a pinned release tag plus SHA-256.** The documented install downloads the installer of a named release, checks it against the SHA-256 published with that release, and only then runs it. The `curl … | bash` line from `main` is removed from README and `install.sh`.

Accepted limit, from [research 01](../research/01-claude-plugin-pinning.md): the checksum lives on GitHub next to the code, so it catches tampering in transit or a wrong file, but not a compromised upstream. A signed release stays in **Not yet specified** (release integrity).
