---
title: Agent RAG Memory with Vector Databases
description: Using vector databases like Qdrant to give AI agents deep, semantic memory retrieval across unlimited history — beyond what fits in a context window.
tags: [concepts, agents, memory, infrastructure, rag, vector-database]
---

Agents have a hard ceiling: the context window. Everything an agent knows in a session must fit inside it. As history grows — weeks of pipeline runs, research findings, past decisions — it stops fitting. The oldest and often most valuable context gets evicted to make room for the new.

RAG-based agent memory solves this by storing agent history in a vector database and retrieving only what's semantically relevant to the current task. Instead of cramming everything into context, the agent queries for what it needs.

## How it works

At its core, the pattern is simple:

1. **Write** — after each session, task completion, or notable event, the agent serializes its findings into documents and stores them in a vector database
2. **Embed** — each document is converted to a vector embedding (a numerical representation of its meaning) by an embedding model
3. **Retrieve** — at the start of a new session or when context is needed, the agent runs a semantic search against the database using the current task as a query
4. **Inject** — the most relevant retrieved documents are prepended to the agent's context window before it starts working

The vector database doesn't remember everything in every session — it surfaces what's *relevant*. An agent working on a bug in the invoicing pipeline retrieves documents about invoicing history, not last week's research on a completely different feature.

## Why Qdrant

[Qdrant](https://qdrant.tech) is an open-source vector database built for this pattern. It runs locally (Docker or native binary), has a clean REST API, supports filtering alongside semantic search, and handles the operational concerns (persistence, indexing, collection management) that make rolling your own vector store painful.

Key capabilities that matter for agent memory:

- **Payload filtering** — search vectors *and* filter by structured metadata (agent name, date range, topic tag, session ID). This lets you ask "find memories relevant to this task, from sessions in the last 30 days, tagged as verified findings."
- **Named collections** — separate namespaces per agent, per project, or per memory type. Keep episodic logs separate from curated semantic summaries.
- **Streaming upserts** — efficient incremental writes. Each session's output can be stored as it completes without expensive batch reindexing.
- **Local-first** — no API key, no cloud vendor dependency, no data leaving the machine.

## Memory tiers in practice

The most effective implementations layer memory types rather than dumping everything into one collection:

**Short-term store** (in-context) — the agent's active context window for the current session. Fast, complete, temporary.

**Episodic store** (Qdrant) — a rolling log of what happened: pipeline outputs, research findings, decisions made, errors encountered. Each entry is a document with a timestamp, agent identifier, and topic tags. The agent queries this for "what did I find last time I worked on this?"

**Semantic store** (Qdrant, separate collection) — distilled knowledge. Not raw logs, but compressed conclusions: "this API is rate-limited above 100 req/min," "the client prefers weekly digests over daily noise." The agent curates this from episodic memory over time. Queries here answer "what do I know about this domain?"

**Procedural store** (skill files) — how to do things. This doesn't usually live in a vector DB — markdown skill files work better here because they're human-editable and version-controlled.

## The retrieval call

A typical retrieval sequence before starting a task:

```python
# 1. Embed the current task description
query_vector = embed("Investigate why the invoicing pipeline is failing on step 3")

# 2. Search episodic memory for relevant prior sessions
episodes = qdrant.search(
    collection_name="agent-episodes",
    query_vector=query_vector,
    query_filter={"agent": "pipeline-agent", "tags": ["invoicing"]},
    limit=5
)

# 3. Search semantic memory for relevant domain knowledge
knowledge = qdrant.search(
    collection_name="agent-knowledge",
    query_vector=query_vector,
    limit=3
)

# 4. Inject into context
context = format_memory_block(episodes, knowledge)
```

The retrieved context slots into the system prompt or early user turn, before the agent starts its actual work. The agent sees its relevant history without having its entire history forced into context.

## What this enables

**Persistent agent identity** — an agent that has worked on a codebase for months knows its quirks, its patterns, its past mistakes. That knowledge survives session restarts. Without a memory system, the agent is always a stranger.

**Cross-session learning** — if an agent tried an approach and it failed, that failure is stored. The next time it encounters a similar situation, retrieval surfaces the prior failure and the agent can avoid repeating it.

**Multi-agent knowledge sharing** — multiple agents can write to the same Qdrant collection and read from each other's memories. A research agent and a build agent working on the same project share a knowledge layer.

**Unbounded history** — context windows are typically 100K–200K tokens. A vector database can hold years of agent activity. Only relevant fragments get retrieved, keeping context usage efficient regardless of how long the project has been running.

## Tradeoffs to know

**Retrieval isn't recall** — semantic search finds semantically similar documents, not necessarily the right documents. An agent relying too heavily on retrieved memory can hallucinate relevance, surfacing tangentially related past context that actually misleads it.

**Embedding models matter** — retrieval quality depends entirely on the embedding model. A weak model produces poor vectors; semantically similar documents don't cluster well, and retrieval misses. For code and technical content, code-specialized embeddings outperform general-purpose ones.

**Write discipline is required** — a memory system is only as good as what gets written to it. Agents that write vague, unstructured memory entries get vague, unstructured retrievals back. Good memory hygiene — structured documents, consistent tags, explicit summaries — compounds over time.

**Latency adds up** — embedding + vector search + document retrieval adds latency before the agent can start its first response. For interactive sessions this is noticeable; for background tasks it's usually irrelevant.

## Getting started

A minimal Qdrant setup for a single OpenClaw agent:

1. Run Qdrant locally: `docker run -p 6333:6333 qdrant/qdrant`
2. Create two collections: `agent-episodes` and `agent-knowledge`
3. At session end, embed the session summary and upsert to `agent-episodes`
4. Periodically, have the agent review recent episodes and distill key facts into `agent-knowledge`
5. At session start, run the retrieval query and prepend results to context

The [Zaytas/openclaw-qdrant-rag](https://github.com/Zaytas/openclaw-qdrant-rag) project wraps this pattern as an OpenClaw-compatible skill, handling the embedding, upsert, and retrieval boilerplate so agents can write memory in one call and retrieve in one call.

## Related

- [[concepts/agent-memory-systems|Agent Memory Systems]] — the broader taxonomy of memory types for autonomous agents
- [[concepts/agent-memory|Agent Memory]] — how OpenClaw agents manage continuity across sessions using files
- [[concepts/agent-long-term-memory|Agent Long-Term Memory]] — strategies for maintaining agent context over extended periods
- [[concepts/multi-day-agent-build-loops|Multi-Day Agent Build Loops]] — why session boundary memory failures kill long-running agent work
- [[concepts/agent-self-review-loop|Agent Self-Review Loop]] — agents evaluating outputs, a pattern that benefits from memory of prior reviews
