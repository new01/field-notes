---
title: Four-Role Orchestrator Chain
description: A sequential multi-agent pipeline where each role consumes the previous stage's output and explicitly hands off to the next
tags: [concepts, architecture, multi-agent, orchestration, openclaw]
---

# Four-Role Orchestrator Chain

A sequential multi-agent pipeline where each stage consumes the previous stage's output and explicitly hands off to the next — enforcing clean boundaries without requiring a central coordinator.

## The Four Roles

Instead of one agent doing everything, work splits into four canonical roles. Each has a defined input, a defined output, and no access to the full session history of the others.

### Planner

Takes the raw request and produces a structured spec.

#### What the Planner receives
- The original task description
- Any relevant context files (USER.md, project notes)

#### What the Planner produces
A JSON brief with all the context downstream stages need: goal, constraints, acceptance criteria, relevant files, expected output format.

##### Planner anti-patterns
- Trying to do any actual work (leave that to Builder)
- Making assumptions not grounded in the task — flag ambiguity, don't resolve it silently
- Producing a vague brief that forces Builder to guess

### Builder

Receives the brief, does the core work.

#### What the Builder receives
- The Planner's JSON brief (only)

#### What the Builder produces
The primary artifact: generated content, code, analysis, or transformed data. Appended to the shared artifact file.

##### Builder anti-patterns
- Re-reading the original request rather than trusting the brief
- Producing output that doesn't match the brief's acceptance criteria
- Doing partial work and marking it complete

### Reviewer

Receives the artifact and checks it against defined quality criteria.

#### What the Reviewer receives
- The Planner's brief (acceptance criteria)
- The Builder's artifact

#### What the Reviewer produces
Pass/fail verdict with specific, actionable flags. Not general feedback — specific lines, specific issues, specific fixes required.

##### Reviewer anti-patterns
- Approving to avoid conflict ("looks fine")
- Flagging stylistic preferences as failures
- Sending vague feedback that Builder can't act on

### Delivery

Receives the reviewed artifact and routes it to its destination.

#### What Delivery receives
- Reviewer approval (will not run on fail)
- The final artifact

#### What Delivery does
Routes the artifact: file write, API call, Discord message, email, database write. Logs the delivery confirmation.

##### Delivery anti-patterns
- Delivering before Reviewer approves
- Silently swallowing delivery errors
- Delivering to the wrong destination without confirmation

## Why the Handoff Contract Matters

### Debuggability

When something goes wrong, inspect the artifact at each stage boundary. The JSON file shows exactly what each stage received and produced. No guessing.

### Restartability

A failed stage can be retried from the last good artifact without re-running everything. Builder fails? Rerun Builder with the same brief. Don't re-plan.

### Composability

Roles can be swapped out independently. Different Reviewer logic (stricter, domain-specific) without touching Planner or Builder. Different Delivery targets without touching anything upstream.

## Implementation

The simplest implementation: a JSON artifact file each stage reads and writes.

```json
{
  "run_id": "run-20260310-001",
  "brief": {
    "goal": "...",
    "constraints": [],
    "acceptance_criteria": []
  },
  "artifact": {
    "content": "...",
    "built_at": "2026-03-10T20:00:00Z"
  },
  "review": {
    "passed": true,
    "flags": []
  },
  "delivery": {
    "sent_at": "2026-03-10T20:05:00Z",
    "target": "discord:channel-id"
  }
}
```

Each stage appends its output and passes the whole file forward. The file is the handoff.

## Relation to Sequential Graph Execution

The four-role chain is a specific instance of the broader sequential graph execution pattern: one node at a time, each node reads the complete artifact trail of every prior node before it acts.

### When four roles is too many
Simple, low-stakes tasks don't need the full chain. A morning brief doesn't need a Reviewer. A file rename doesn't need a Planner. Apply the full chain where quality matters and failures are costly.

### When four roles isn't enough
Some pipelines need a fifth stage — an Auditor that checks Delivery actually happened correctly. Or a Planner that spawns multiple Builders in parallel on independent sub-tasks before a synthesis Reviewer.

## Related

- [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — the broader framework sequential chains operate within
- [[concepts/orchestrator-sub-skill-pattern|Orchestrator Sub-Skill Pattern]] — how top-level orchestrators delegate to focused sub-skills
- [[concepts/input-validation-in-skills|Input Validation in Skills]] — pre-flight checks at the start of each stage
- [[concepts/agent-teams|Agent Teams]] — when to use parallel teams vs sequential chains
