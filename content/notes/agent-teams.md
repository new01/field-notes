---
title: "Agent Teams"
tags: [concept, agent-teams, architecture, parallel-execution, openclaw]
---

# Agent Teams

A pattern where a single prompt spawns multiple specialized subagents that work in parallel, each handling a distinct slice of a larger task, then a synthesis agent merges outputs into a final deliverable.

The key properties:
- **Parallel execution** — no serial bottleneck; all agents work simultaneously
- **Role specialization** — each agent has a specific domain, persona, or task scope
- **Single-prompt activation** — the user writes one prompt; coordination is handled internally

---

## Why This Matters

Most people build agents sequentially: research, then write, then evaluate — one step at a time. Agent teams break that bottleneck. Three agents handling research, writing, and evaluation in parallel finish in the time it takes the slowest one, not the sum of all three.

The main session becomes air traffic control. It orchestrates, it doesn't execute.

---

## What It Looks Like in Practice

A typical agent team for content work:

1. **Research agent** — gathers sources, extracts key points
2. **Writer agent** — drafts based on research output
3. **Editor agent** — reviews draft for accuracy and tone
4. **Synthesis agent** — merges all outputs into the final deliverable

Each agent receives the full context of prior agents' work before acting. The artifact trail — the chain of outputs — is the coordination mechanism. No real-time communication required.

---

## The Non-Technical Case

This pattern isn't just for engineering tasks. The majority of practical agent team use cases are non-technical: competitive analysis, content production, business research, customer support workflows. Any task with multiple independent workstreams is a candidate.

---

## Related

- [[brains-and-muscles|Brains and Muscles]]
- [[notification-batching|Notification Batching]]
