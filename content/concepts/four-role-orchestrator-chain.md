---
title: Four-Role Orchestrator Chain
description: A sequential multi-agent pipeline where each orchestrator skill consumes the previous stage's output and explicitly hands off to the next
tags: [concepts, architecture, multi-agent, orchestration, openclaw]
---

A sequential multi-agent pipeline where each orchestrator skill consumes the previous stage's output and explicitly hands off to the next — enforcing clean stage boundaries without requiring a central coordinator.

## The pattern

Instead of one agent doing everything, the work is split into four canonical roles:

**Planner** — takes the raw request and produces a structured spec. Output: a JSON brief with all the context downstream stages need.

**Builder** — receives the brief, does the core work (generation, transformation, computation). Output: the primary artifact.

**Reviewer** — receives the artifact and checks it against defined quality criteria. Output: pass/fail with specific flags.

**Delivery** — receives the reviewed artifact and routes it to the appropriate destination (file write, API call, notification). Output: confirmation.

Each role receives only what the previous stage produced. No role has access to the full session history of the others.

## Why the handoff contract matters

Without explicit handoffs, stages communicate implicitly through shared state — which means any stage can accidentally read or write context it shouldn't. Explicit handoff contracts make the pipeline:

- **Debuggable** — when something goes wrong, you can inspect the artifact at each stage boundary
- **Restartable** — a failed stage can be retried from the last good artifact without re-running everything
- **Composable** — roles can be swapped out independently (e.g., different reviewer logic) without touching other stages

## Implementation

The simplest implementation is a JSON artifact file that each stage reads and writes:

```json
{
  "run_id": "run-20260310-001",
  "brief": { "...": "planner output" },
  "artifact": { "...": "builder output" },
  "review": { "passed": true, "flags": [] },
  "delivery": { "sent_at": "...", "target": "..." }
}
```

Each stage appends its output to the artifact and passes the whole file to the next stage. The file is the handoff.

## Relation to sequential graph execution

The four-role chain is a specific instance of the broader sequential graph execution pattern: one node at a time, each node reads the complete artifact trail of every prior node before it acts. No concurrent execution within the chain.

## Related

- [[Graph Orchestration Patterns]] — the broader research behind sequential graph execution
- [[Skill Handoff Pattern]] — the lightweight file-based handoff contract
- [[Orchestrator Sub-Skill Pattern]] — how top-level orchestrators delegate to focused sub-skills
- [[Input Validation in Skills]] — pre-flight checks at the start of each stage
