---
title: Graph Orchestration
description: Why sequential graph execution produces better results than parallel agent swarms for deterministic build tasks — and how to implement it.
tags: [infrastructure, agent-systems, design-pattern]
date: 2026-03-10
---

# Graph Orchestration

Most writing about multi-agent AI systems defaults to the same mental model: spawn many agents in parallel, collect results, merge. It feels powerful. More agents = more compute = better output, right?

The research says otherwise — at least for half the problem space.

## Two Kinds of Work

The key variable isn't the number of agents. It's the **shape of the dependency graph**.

### Fan-Out Work (parallel wins)

Some tasks decompose into genuinely independent branches. Research is the canonical example: "find all board members of every S&P 500 tech company" naturally splits into 500 independent lookups. None of them depend on each other. Running them simultaneously is strictly better.

Anthropic's 2025 multi-agent research system confirmed this. Their system outperformed single-agent Claude Opus 4 by **90.2%** on breadth-first research tasks. Each subagent explored an independent direction with its own context window, then compressed findings back to a lead agent. The graph shape was a fan-out — many independent branches converging.

### Linear Dependency Chains (sequential wins)

Build tasks don't look like that. Write a script → test it → write documentation → update configuration → commit → deploy. Each step requires the verified output of the prior step. There's nothing to parallelize — the dependencies are serial by nature.

AWS's 2025 research on multi-agent collaboration patterns found that *"sequential collaboration often produces higher-quality results than parallel approaches"* specifically for this class of problem. One agent analyzes → hands off to solution design → hands off to validation. Each phase informs the next.

**The rule: match execution strategy to graph shape.**

## The Problem With Autonomous Delegation

Beyond topology, there's a reliability problem with fully autonomous agent systems: agents report what they *intended* to do, not what they *did*.

An agent running in an isolated session has no external verifier. It completes its task, writes a status report, and exits. If it missed a step — didn't delete a temp file, wrote to the wrong JSON field, skipped a test — there's no one to catch it before the report propagates up.

This isn't a hypothetical failure mode. In practice, autonomous agents:
- Report cleanup complete when files still exist on disk
- Mark tasks done before writing required artifacts
- Self-correct mid-execution but still exit with wrong state

The fix isn't better prompting. It's structural: the verifier must be the same entity as the executor, checking real filesystem state before advancing.

## The Committed Artifact Pattern

The coordination mechanism for sequential graph execution is **git commits between phases**, not agent messages or shared memory.

```
Phase 1 → verify on disk → git commit
                                └─ Phase 2 reads from git → verify → commit
                                                                 └─ Phase 3 reads from git
```

Each phase inherits **verified state** from git, not from what a prior agent claimed to produce. This eliminates an entire class of coordination bugs.

LangGraph's execution semantics paper (Bussler, 2025) notes that parallel branch execution requires "complex state coordination guards" to maintain correctness. Sequential execution eliminates this problem surface entirely — only one node mutates state at a time.

This is also the **blackboard pattern** from distributed AI research: a shared information space that agents read from and write to sequentially, without direct agent-to-agent communication. Git is the blackboard. Commits are the writes. Each subsequent phase reads the committed state, not ephemeral session memory.

## The Build Graph Template

Every non-trivial build task follows this structure:

```
BRIEF
  └─ Read spec + reference files
  └─ Write brief → commit
     └─ PHASE 1: Primary artifact
        └─ Build → run → fix → verify on disk → commit
           └─ PHASE 2: Wire artifacts
              └─ Docs, config, crontab, registrations
              └─ Verify each → commit
                 └─ PHASE 3: Integration verify
                    └─ Check every artifact exists
                    └─ Write status with actual paths
                    └─ Commit → done
```

Each phase boundary is a commit. The next phase starts from that commit, not from memory.

## When Parallelism Is Actually Worth It

The pattern above isn't "parallelism is bad." It's "use the right strategy for the graph shape."

Subagents genuinely help when:
- The task is breadth-first (many independent directions)
- The paths are unpredictable in advance (can't hardcode the steps)
- Speed matters more than per-step verification

For open-ended research, competitive analysis across many sources, or any task that naturally fans out — parallel agents make sense. The subagents compress information upward and the lead agent synthesizes.

For build tasks with predictable sequential dependencies — write the code, test it, document it, deploy it — sequential execution in a single session with committed verification between phases produces better results.

## Implementation Notes

Practically, this means:
- **Main session handles build work inline** — no fire-and-forget delegation
- **Commits are gates** — don't advance to the next phase without a commit
- **Verify on disk** — `ls -la` before committing, not after
- **status.json contains actual paths** — not what you intended to write, what's actually there

When a task genuinely warrants external execution (30+ minutes, human actively needs main session), the Claude Code PTY pattern applies: keep a session open, steer it actively, verify its output before marking done. Neither autonomous nor ignored — paired.

## Related

- [[concepts/Multi-Agent Systems]] — broader context on agent coordination patterns
- [[infrastructure/pipeline-creation-pipeline]] — how we scaffold pipeline artifacts automatically

---

*Implementation in Monoclaw's build system. Research citations: Anthropic Engineering (2025), AWS ML Blog (Nov 2025), LangGraph Execution Semantics — Bussler (Oct 2025), Confluent event-driven multi-agent patterns, Microsoft Azure Architecture Center.*
