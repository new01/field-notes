---
title: Agent Teams
description: Spawning multiple specialized subagents to handle parallel workstreams
tags: [concepts, agent-teams, architecture, openclaw]
---

# Agent Teams

A single prompt spawns multiple specialized subagents, each handling a distinct slice of a larger task. When they finish, a synthesis pass merges their outputs.

The key properties:
- **Parallel execution** — no serial bottleneck; all agents work simultaneously
- **Role specialization** — each agent has a specific domain, persona, or skill focus
- **Single-prompt activation** — one prompt triggers the whole team; coordination is internal

## When to Use It

### The independence test

Agent teams work when a task has multiple **genuinely independent** workstreams. The test: can each sub-task start immediately with only the shared brief, with no dependency on any other sub-task's output?

#### Good candidates for agent teams
- Research + writing + evaluation (all start from the same brief, no circular deps)
- Backend + frontend + audit (independent codebases, non-overlapping files)
- Planning + building + review (when Build can start from the brief, not from Plan's output)
- Multi-source competitive analysis (each agent covers a different competitor)

#### Poor candidates — use sequential instead
- Tasks where step B needs step A's specific output
- Tasks that write to the same files
- Tasks where one agent's decision changes what another should do
- Tasks where quality depends on accumulated context from prior steps

### The file conflict test

If two agents will write to the same file, they cannot safely run in parallel. Conflicting writes corrupt state and produce unpredictable results.

## The Coordination Mechanism

### Why agents don't talk to each other

Agents don't communicate in real time. They coordinate through **shared files** — a brief written before any agents spawn, a scratchpad that each agent reads and appends to.

#### The blackboard pattern

Each agent inherits the full artifact trail of every prior agent before it acts. This "blackboard" approach (from multi-agent AI research) is more reliable than real-time message passing.

##### Why the blackboard beats message passing
- No race conditions — agents read a stable file, not a live stream
- Full context — each agent sees everything, not just what was directed at it
- Debuggable — inspect the scratchpad file at any point to understand state
- Restartable — a failed agent restarts with the same input; no message replay needed

### The standard coordination structure

```
Phase 0: Brief (orchestrator writes brief.md + scratchpad.md)
  → Agent A: reads brief, does its work, appends to scratchpad
  → Agent B: reads brief + scratchpad (including A's output), does its work
  → Agent C: reads brief + scratchpad (including A+B output), synthesizes
```

#### The synthesis pass
Always end with a synthesis agent that reads all outputs and produces a unified result. Raw parallel output without synthesis is unusable — it's N separate responses, not one coherent answer.

## API Rate Limits and the Ceiling

### The practical constraint

Running 4 agents simultaneously = 4 concurrent API consumers. At scale this causes rate limit errors, degraded quality, and coordination failures.

#### The conservative operating model
- 1 active subagent at a time
- Sequential graph execution with gate checks between nodes
- Synthesize between phases rather than running everything at once

This is slower but reliable. The speed of parallel execution only matters if all agents complete successfully — a single rate-limit failure can cascade and require a full re-run.

### Ceiling by context

##### Personal/hobbyist use
1-2 parallel agents maximum. The API ceiling is tight; reliability matters more than speed.

##### Max subscription (Anthropic)
2-3 parallel agents with monitoring. Watch for rate limit responses and back off.

##### Team/API key
Depends on tier. Start at 2 parallel, increase only after proving reliability at that level.

## A Practical Pattern

### The advisory board pattern

A specific agent team pattern for multi-perspective decision evaluation. Each agent plays a specific expert persona and evaluates the same proposal from their domain:

```
Prompt → [Financial Analyst, Technical Lead, User Advocate, Risk Officer]
       → Synthesis agent reads all four reviews → Recommendation
```

No agent reads another's review before writing. Each perspective is independent. The synthesis agent sees all four and produces the final call.

This is more useful than a single agent wearing multiple hats — the personas genuinely diverge when given separate context windows.

## Related

- [[infrastructure/ai-advisory-board|AI Advisory Board]] — the advisory board pattern in detail
- [[concepts/brains-and-muscles|Brains and Muscles]] — each team member is a brain; the muscles are shared
- [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — why sequential usually beats parallel
- [[concepts/four-role-orchestrator-chain|Four-Role Orchestrator Chain]] — sequential alternative to parallel teams

## Sources

Mark Kashef ("7 Things You Can Build with Claude Code Agent Teams") — 7 live demos; 6 of 7 use cases are non-technical, meaning agent teams apply to business and content tasks, not just engineering. Matthew Berman — Business Intelligence Council as a sophisticated agent team pattern with parallel expert personas and synthesis pass.
