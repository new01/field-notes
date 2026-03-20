---
title: Multi-Day Agent Build Loops
description: Running autonomous AI agents across multiple days works — but session boundaries erase all context, and the memory problem is what actually breaks them
tags: [concepts, agents, memory, autonomy, build-loops]
---

# Multi-Day Agent Build Loops

Running a local AI agent continuously across multiple days to work through a project backlog is technically possible. Agents can execute well-scoped tasks, verify their own work, and advance a queue autonomously. The limitation isn't coding ability — it's memory. Every session boundary erases everything the agent knew.

## The Pattern Works

A properly structured build loop looks like this:

1. A queue holds discrete tasks, each with a complete spec and required artifact list
2. A dispatcher picks the next task and spawns a fresh agent with that spec
3. The agent executes, writes artifacts to disk, and signals completion via a status file
4. The dispatcher verifies artifacts exist (gate check) and marks the task done
5. Repeat until the queue is empty

Each task is self-contained. The agent doesn't need to understand the whole project — just the current spec. This design makes the loop resilient: a bad task execution doesn't poison subsequent tasks.

This pattern runs reliably. Multi-day build loops aren't theoretical — they're a working operational pattern for anyone willing to invest in the scaffolding.

## The Core Failure: Session Boundaries

An LLM-based agent's context resets at every session boundary. Session boundaries happen:

- When a session ends (explicit close, timeout, or process restart)
- When context window capacity fills during a long-running task
- When a subagent is spawned (fresh context by design)

What's lost at the boundary: everything. The agent doesn't know what it built yesterday, what decisions were made, what's already been tried, or what state partially-finished work is in.

The pattern this produces:

- **Repeated decisions** — problems solved on day 1 get re-solved on day 3 without the prior solution in context
- **Conflicting changes** — a bug fixed at 9am gets re-broken at 2pm when a different session doesn't have the fix in its context window
- **State blindness** — in-progress work isn't resumed; it's restarted, producing duplicates or conflicts
- **False completions** — without explicit artifact verification, the agent reports tasks done without producing the required output

"Context amnesia" is the documented name for this failure mode. It manifests most visibly in multi-agent systems where agents unknowingly undo each other's work.

## What the Session Boundary Looks Like in Practice

A three-day build loop without memory discipline looks like this:

**Day 1:** Agent sets up scaffolding. Decides to use a particular data model. Creates five files. Works well.

**Day 2:** Agent starts fresh. No knowledge of day 1's decisions. Sees the scaffolding but doesn't know why choices were made. Makes a conflicting data model decision. Creates partial duplicates of day 1's work. Marks three tasks done without verifying artifacts.

**Day 3:** Queue shows six tasks complete. You check the actual files. Two are empty. Three have conflicting implementations. One was done correctly.

The agent wasn't malfunctioning. It was operating correctly within its context window — it just had no access to any prior context.

## How to Fix It

The solutions are all variations on the same idea: write memory to disk and read it at the start of every session.

### Spec files as the session handoff artifact

The most reliable pattern for build loops: every task gets a complete spec written before execution. The spec contains everything needed to execute — file paths, requirements, what the task must produce, what success looks like. The agent reads the spec; the spec is its memory for that task.

Completion signals via a `status.json` file the agent writes on completion. The dispatcher reads this file to verify artifacts actually exist on disk. The handoff is fully explicit and verifiable.

### Daily memory files

The agent writes a session log at the end of each session: what was done, what decisions were made, what failed and why. The next session reads these logs before starting work.

Works well for single-agent setups. The key discipline: write the log *during* the session at context flush points, not only at the end — a session that crashes before the end write loses everything.

### Curated long-term memory

A `MEMORY.md` file that accumulates across sessions: architectural decisions, recurring mistakes, user preferences, project state. More selective than daily logs — only what matters long-term.

Token cost discipline required: this file loads on every session start. Keep it under 20KB or it starts significantly increasing every session's cost. Review and prune monthly.

### Explicit context flush markers

During long sessions, insert markers (`--- CONTEXT FLUSH [HH:MM] ---`) and force a state summary before the context window degrades. Preserves continuity within a single long-running session that would otherwise silently drift.

## What You Actually Need for a Reliable Multi-Day Loop

For a build loop to run faithfully over multiple days without human supervision:

**Before dispatching each task:**
- Write a complete spec with explicit required artifacts
- Include file paths and success criteria — no ambiguity

**During execution:**
- Agent writes context flush summaries at regular intervals
- Agent writes partial progress to a build directory, not just memory

**On completion:**
- Agent writes `status.json` with artifact paths
- Dispatcher verifies each artifact path exists on disk
- Only then: mark done and advance the queue

**Across sessions:**
- Dispatcher reads session memory before dispatching anything
- In-progress tasks get a context summary injected, not a blank start
- Gate checks are done by a different context than the executor — never let the grader grade their own exam

## The Verification Problem

Gate checking is where many build loops fail. The naive implementation: ask the agent "did you complete the task?" and mark done if it says yes.

Language models generate convincing completion reports. The only reliable verification is file system checks: does the artifact exist? Does it have content? For critical work, does a smoke test pass?

The agent cannot reliably self-verify — the same model that generated a false completion will also generate a confident verification of that false completion. The verification must be structural: path existence, file size, test execution.

## Related

- [[concepts/agent-memory|Agent Memory]] — the two-tier memory architecture for single-agent setups
- [[concepts/agent-long-term-memory|Agent Long-Term Memory]] — persistent memory systems across context resets
- [[concepts/build-queue-pattern|The Build Queue Pattern]] — how to structure a queue the agent can execute against
- [[concepts/agentic-error-recovery-loops|Agentic Error Recovery Loops]] — handling failures without human intervention
