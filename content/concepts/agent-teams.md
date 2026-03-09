---
title: Agent Teams
description: Spawning multiple specialized subagents to handle parallel workstreams
tags: [concepts, agent-teams, architecture, openclaw]
---

A single prompt spawns multiple specialized subagents, each handling a distinct slice of a larger task. When they finish, a synthesis pass merges their outputs. The result: tasks that would take a single agent an hour get done in parallel, with each agent focused on its domain.

The key properties:
- **Parallel execution** — no serial bottleneck; all agents work simultaneously
- **Role specialization** — each agent has a specific domain, persona, or skill focus
- **Single-prompt activation** — one prompt triggers the whole team; coordination is internal

## When to use it

Agent teams shine when a task has multiple genuinely independent workstreams. Research + writing + evaluation. Backend + frontend + audit. Planning + building + review. If the sub-tasks don't depend on each other's outputs, they can run in parallel.

Don't use agent teams for tasks with hard dependencies between steps. If step B needs step A's output, sequential execution is correct. Forcing parallelism here causes coordination failures and conflicting writes.

## The coordination mechanism

Agents don't communicate in real time. They coordinate through shared files — a `brief.md` written before any agents spawn, a `scratchpad.md` that each agent reads and appends to. Each agent inherits the full artifact trail of every prior agent before it acts.

This "blackboard" pattern (from multi-agent AI research) is more reliable than trying to coordinate agents through messages. The shared file IS the coordination.

## A practical pattern

```
Phase 0: Brief (orchestrator writes brief.md + scratchpad.md)
  → Agent A: reads brief, does its work, appends to scratchpad
  → Agent B: reads brief + scratchpad (including A's output), does its work
  → Agent C: reads brief + scratchpad (including A+B output), synthesizes
```

Each agent has full context of what came before. No conflicts. No missed state.

## API rate limits

Running 4 agents simultaneously = 4 concurrent API consumers. At scale this causes rate limit errors. The conservative operating model: 1 active subagent at a time, sequential graph execution, gate checks between nodes. Slower but reliable.

## Related

- [[ai-advisory-board|AI Advisory Board]] — a specific team pattern for multi-perspective decision evaluation
- [[brains-and-muscles|Brains and Muscles]] — each team member is a brain; the muscles are shared

## Sources

Mark Kashef ("7 Things You Can Build with Claude Code Agent Teams") — 7 live demos; 6 of 7 use cases are non-technical, meaning agent teams apply to business and content tasks, not just engineering. Matthew Berman — Business Intelligence Council as a sophisticated agent team pattern with parallel expert personas and synthesis pass.
