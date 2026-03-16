---
title: Agent Long Term Memory
description: Persistent memory systems that let AI agents maintain state and context across session resets
tags: [concepts, agents, memory]
---

# Agent Long Term Memory

An AI agent's context window resets between sessions. Without persistent memory, every session starts from zero — the agent has no record of what it built yesterday, what decisions were made, or what state a project is in.

Long term memory solves this. It's the layer of storage that survives context resets and lets agents accumulate knowledge over time.

## Why It's a Hard Problem

The naive solution — just dump everything into a file and load it at session start — runs into context window limits fast. A month of work history is too large to fit in a single context. The useful parts need to be extracted, compressed, and organized for efficient retrieval.

The harder version of the problem: knowing *what* to remember. Not every event during a session is worth preserving. Good long term memory systems are selective.

## Common Approaches

### File-based memory

The simplest approach: structured markdown files that the agent reads and writes. Split into tiers — raw session logs for recency, distilled summaries for long-term knowledge.

Works well for single agents. Doesn't scale to multi-agent systems without a shared store.

### Vector databases

Embed memories as vectors. At session start, retrieve only the most semantically relevant memories for the current task.

Scales better. Requires embedding infrastructure and a retrieval step that adds latency.

### Structured knowledge stores

Store facts, decisions, and relationships in a structured format (JSON, database). Query by key rather than semantic similarity.

Fast retrieval for known keys. Doesn't handle unstructured recall well.

### Hybrid approaches

Most production systems combine tiers: structured storage for facts and decisions, vector retrieval for contextual recall, raw logs for recency. Each tier serves a different retrieval pattern.

## What Gets Stored

Effective long term memory stores things that would otherwise need to be re-explained on every session:

- **Decisions and rationale** — not just "we chose X" but why, so the agent doesn't revisit closed questions
- **Project state** — what's done, what's in progress, what's blocked
- **User preferences** — working style, formatting preferences, communication patterns
- **Lessons learned** — mistakes made and root causes, so they don't repeat
- **Key facts** — file locations, credentials patterns, system topology

## The Context Budget Problem

Every byte loaded into context costs tokens. Long term memory that auto-loads at session start needs to be size-disciplined.

A common heuristic: keep auto-loading memory under 10-20KB. Anything larger should be retrieved on-demand rather than pre-loaded.

## Related

- [[concepts/agent-memory|Agent Memory]] — the full two-tier memory architecture
- [[concepts/agent-orchestration-platforms|Agent Orchestration Platforms]] — how memory fits into multi-agent systems
- [[concepts/agent-budget-enforcement|Agent Budget Enforcement]] — controlling token costs from memory loading
