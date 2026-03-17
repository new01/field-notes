---
title: Multi Agent Context Scoping
description: The discipline of deciding what information each agent in a multi-agent system should see, controlling context boundaries to prevent overload, leakage, and irrelevant noise.
tags: [concepts, agents, multi-agent, context, orchestration, architecture]
---

In multi-agent coding systems, the hardest problem isn't building the agents. It's deciding what context each agent should see.

Give an agent too much context and it drowns in irrelevant information, burns tokens on noise, and makes worse decisions. Give it too little and it lacks the information needed to do its job. The boundary between those two failure modes is where context scoping lives.

## Why context is the hard problem

When a single agent handles a task, context management is straightforward: feed it the relevant files, the task description, and let it work. The agent sees everything it needs because the scope is bounded by a single task.

Multi-agent systems break this simplicity. Ten agents working on related parts of a codebase each need different slices of information. The agent writing tests needs the implementation details. The agent reviewing code needs the PR diff and the style guide. The agent planning architecture needs the high-level structure but not individual function bodies.

If every agent sees everything, you get:

- **Token waste** — agents process thousands of lines of context they'll never use, burning compute and money on every run
- **Attention dilution** — large language models have finite attention, and irrelevant context actively degrades output quality
- **Information leakage** — agents see data they shouldn't, creating security and privacy risks in systems that handle sensitive information
- **Context conflicts** — when two agents see overlapping but slightly different versions of the same information, they make contradictory decisions

Context scoping is the information architecture problem underneath every multi-agent system. Get it wrong and no amount of agent sophistication fixes the downstream mess.

## Approaches to scoping

There's no single right way to scope context. The approach depends on the system's architecture and the nature of the work.

**Role-based scoping** assigns each agent a role with a defined information boundary. A test-writing agent sees the module under test and the test framework conventions. A deployment agent sees infrastructure config and deployment history. Each role has a context profile — a specification of what it can and should access. This is the simplest model to reason about and the easiest to audit.

**Task-derived scoping** determines context from the task itself. When a work item enters the system, the orchestration layer analyzes what the task requires and assembles a context package specifically for that task. A bug fix in the authentication module pulls in the auth code, related tests, and recent commit history for that module — nothing else. This is more dynamic than role-based scoping but requires a smarter orchestration layer.

**Hierarchical scoping** mirrors organizational structure. A top-level orchestrator sees the full project plan but no implementation details. Mid-level coordinators see their domain's files and the interfaces to adjacent domains. Leaf agents see only the specific files they're working on. Information flows up as summaries and down as scoped instructions.

**Need-to-know scoping** is the most restrictive model. Each agent starts with minimal context — just the task description — and must explicitly request additional information through controlled channels. The orchestration layer decides whether to grant each request. This minimizes waste and leakage but adds latency and requires infrastructure for context requests.

## The context assembly problem

Regardless of approach, every multi-agent system needs a mechanism to assemble the right context for each agent invocation. This is harder than it sounds.

A naive implementation dumps the entire repository into every agent's context window. This works for small projects with few agents but collapses at any real scale. The more surgical approach requires answering several questions for each agent invocation:

- What files does this agent need to see?
- What metadata (git history, issue descriptions, related conversations) is relevant?
- What do other agents' outputs look like, and does this agent need any of them?
- What should be explicitly excluded to prevent leakage or confusion?

The answers change per task, per agent, and per run. A static context definition works for simple pipelines but breaks down in dynamic systems where agents' needs shift based on what earlier agents discovered.

## Context boundaries as architecture

The way you draw context boundaries defines your system's architecture more than the agents themselves do. An agent is largely interchangeable — swap one language model for another, and the system still works. But change what information flows where, and the system's behavior changes fundamentally.

This means context scoping decisions are architectural decisions. They determine:

- **Coupling** — agents that share context are implicitly coupled. Changes to shared context affect all agents that consume it.
- **Parallelism** — agents with independent context scopes can run in parallel without coordination. Overlapping scopes require synchronization.
- **Failure isolation** — when context is tightly scoped, one agent's failure doesn't contaminate another's inputs. Broad context sharing means errors propagate further.
- **Debuggability** — when something goes wrong, knowing exactly what an agent saw makes diagnosis possible. When agents see everything, it's hard to determine what influenced a bad decision.

## Practical patterns

Several patterns emerge in systems that handle context scoping well:

**Context manifests** — each agent invocation includes a manifest listing exactly what context was provided and why. This makes debugging straightforward: you can reconstruct exactly what an agent saw when it made a particular decision.

**Summary layers** — instead of passing raw context between agents, intermediate agents produce summaries. A code analysis agent reads the full codebase and produces a structured summary. Downstream agents consume the summary, not the raw code. This compresses information while preserving the signal that matters.

**Context budgets** — each agent has a token budget for context. The orchestration layer must fit the relevant information within that budget, forcing prioritization. This prevents the common failure mode where "just add more context" leads to bloated, unfocused agent inputs.

**Scope validators** — before an agent runs, a validation step checks that its context package meets the expected shape: required fields present, excluded fields absent, total size within budget. This catches misconfiguration before it causes downstream problems.

## Related

- [[concepts/agent-orchestration-platforms|Agent Orchestration Platforms]] — the coordination infrastructure that manages context flow between agents
- [[concepts/agent-memory-systems|Agent Memory Systems]] — persistent state that agents carry across runs, a form of context that outlives individual invocations
- [[concepts/cognitive-load-optimization|Cognitive Load Optimization]] — reducing unnecessary information processing, applied at the agent level
- [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — DAG-based execution where context flows along graph edges between agent nodes
- [[concepts/orchestrator-sub-skill-pattern|Orchestrator Sub-Skill Pattern]] — how orchestrators delegate with scoped context to focused sub-agents
- [[concepts/prompt-enrichment-architecture|Prompt Enrichment Architecture]] — assembling and enriching agent prompts with relevant context before execution
- [[concepts/agent-budget-enforcement|Agent Budget Enforcement]] — enforcing resource limits including context token budgets per agent
- [[concepts/ai-pipeline-security-layers|AI Pipeline Security Layers]] — security boundaries that overlap with context scoping to prevent information leakage
