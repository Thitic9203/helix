# Helix skill invocation discipline

Helix workflows are **skills** (`SKILL.md`), not informal chat habits. This document adapts proven agent-discipline patterns for QA.

## Instruction priority

1. **User explicit instructions** (AGENTS.md, CLAUDE.md, direct chat) — highest  
2. **Helix workflow skills** — override default agent behavior for QA tasks  
3. **Default system behavior** — lowest  

If the user says “skip Jira post,” that overrides a skill’s default gate, except create-bug Phase C confirm.

## When to invoke a skill

If there is even a **small chance** a Helix workflow applies (TC prep, retest, Playwright ticket, create bug, or menu via **`helix`**):

1. **Load the workflow** — Claude Code: use the slash-command (`/retest-bug`, etc.) or invoke the **`helix`** skill and let it route. Each command reads and follows the matching workflow SKILL.md.  
2. **Announce once:** `Using **{workflow}** to {purpose}.`  
3. Follow the workflow’s gates and references.

Which command handles which request: the single table in [skill-routing.md § Primary menu](skill-routing.md#primary-menu) (unsure → `/helix`).

## Red flags

If tempted to skip a workflow skill (“I can draft TC without it”, “quick retest”), stop and invoke — review gates are mandatory. More: [agent-rationalizations.md](agent-rationalizations.md).

## Long workflows and todos

When [long-workflow-todos.md § When to create todos](long-workflow-todos.md#when-to-create-todos) applies, create todos per major phase with the agent's todo tool; with no todo tool, list the phases in chat and tick them off — so the user sees progress.

## Subagents and parallel work

Use only when the skill or [subagent-qa-patterns.md](subagent-qa-patterns.md) / [parallel-prep.md](parallel-prep.md) says so — not by default.
