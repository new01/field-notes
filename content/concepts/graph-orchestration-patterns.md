---
title: Graph Orchestration Patterns
description: Why parallel agent swarms fail for build tasks and how directed sequential graphs with committed artifacts consistently outperform them
tags: [concepts, graph-orchestration, multi-agent, sequential, patterns]
---

# Graph Orchestration Patterns

Research synthesized from LangGraph, AutoGen, CrewAI, BMAD, Google Agents, and AWS ML Blog literature through early 2026. The consensus is clearer than you'd expect from a field this young: **sequential graph execution beats parallel agent swarms for deterministic build work**, and the gap is significant.

This page covers the why, the how, and the specific patterns that work in practice.

> [!warning] The parallel agent trap
> Running agents simultaneously feels faster. In practice it causes rate limit errors, conflicting file writes, and coordination failures — often producing worse results than sequential execution at lower cost.

## Why Parallel Agent Swarms Fail

The intuition behind parallel multi-agent systems is seductive: more agents running simultaneously means more throughput. Divide the work, parallelize it, collect results.

In practice, for build tasks with sequential dependencies, this consistently fails in three ways:

### API Overload and Rate Limit Thrashing

Running 5 agents simultaneously means 5 concurrent API consumers hitting the same rate-limited provider. On production API tiers with per-minute token limits, parallel agents quickly saturate the window. Requests start queuing, then failing, then the retry logic compounds the problem.

Sequential execution keeps concurrency at 1. One API call in flight at a time. Predictable, recoverable, and often faster than parallel execution that's rate-limited into a retry spiral.

### Conflicting File Edits

Multiple agents writing to the same files simultaneously produce garbage. Two agents both modifying `scripts/tweet-pipeline.js` — one editing error handling, one editing the HN source — will either overwrite each other or corrupt the file if writes interleave.

The workaround (careful file-locking, explicit coordination protocols) costs more complexity than the parallelism saves. Sequential execution makes this problem impossible: only one agent writes at a time.

### No Shared Context

Agents running in isolated parallel sessions cannot see each other's work. Agent A's discovery that the tweet pipeline has a bug in error handling doesn't reach Agent B working on the humanizer integration. They both proceed with incomplete pictures.

The sequential model eliminates this: each phase inherits the verified committed state of the prior phase. Full context, no coordination protocol required.

---

## The Directed Graph Model

The correct model for multi-agent build work is a **directed graph** where:
- Each node is a phase (plan, build, test, document, deploy)
- Edges represent verified completion — a phase only runs after the prior phase commits successfully
- One node executes at a time
- Committed artifacts (git commits, status files on disk) are the ground truth

```
BRIEF
  └─ Phase 1: Primary artifact
     └─ Phase 2: Wire and integrate
        └─ Phase 3: Verify and close
```

No phase starts until the prior phase commits. The commit is the gate.

### Why commits are the right primitive

Agents have session memory. Memory drifts. An agent that "remembers" it created a file might have only intended to create it or half-written it before a failure.

Git doesn't drift. What's in a commit is what's actually there, bit-for-bit. When Phase 2 starts from a commit that Phase 1 produced, it's starting from verified reality — not from what Phase 1 claimed.

This is the **committed artifact pattern**: each phase's output is committed to git before the next phase begins. The commit hash is the coordination mechanism, not agent memory or session state.

---

## The Blackboard Pattern

From distributed AI systems research (Confluent, 2025; arxiv 2504.21030): a **blackboard** is a shared information space that agents read from and write to sequentially, without direct agent-to-agent communication.

In practice: `builds/<task-id>/` is the blackboard. The scratchpad JSON file lives there and travels through the graph.

```json
{
  "run_id": "tweet-20260310-001",
  "pipeline": "tweet",
  "started_at": "2026-03-10T08:00:00Z",
  "stages": {
    "format_selection": {
      "status": "done",
      "selected_format": "A",
      "rationale": "Hook-forward format matches the technical audience for this topic",
      "completed_at": "2026-03-10T08:01:23Z"
    },
    "generation": {
      "status": "done",
      "draft": "Context windows aren't RAM. They're a conversation that resets every session...",
      "completed_at": "2026-03-10T08:02:45Z"
    },
    "humanizer": {
      "status": "pending"
    }
  },
  "final_output": null
}
```

Each phase reads only the fields it needs from the scratchpad, writes only its own output fields, and commits before exiting. The next phase reads the committed scratchpad — not a live session hand-off.

### What each framework says about this

**LangGraph**: Shared typed state schema. Each node reads needed fields, writes output fields. Sub-agents have private scratchpads; only final results surface to shared state.

**BMAD (v6, Jan 2026)**: Explicit artifact files at each handoff. Four phases: Analysis → Planning → Solutioning → Implementation. Agents hand off with explicit notes, no implicit context carryover.

**Google Agents (Dec 2025)**: `none` mode for sub-agents — they see only what you explicitly construct for them, not the full transcript of prior agents.

**LangChain**: "You must explicitly decide what messages pass between agents." No implicit sharing.

The consensus is strong across all frameworks: minimal, explicit context passing outperforms full conversation carryover.

---

## Phase Naming Convention

Consistent phase naming makes graphs legible. The convention:

- **`plan-a`** — initial analysis and specification
- **`plan-b`** — alternative approach or revised spec (if plan-a reveals issues)
- **`build-a`** — primary implementation
- **`build-b`** — secondary implementation or parallel (non-conflicting) work stream
- **`audit-a`** — review of build output, verification pass
- **`audit-b`** — secondary audit or peer review
- **`wire`** — integration: docs, config registration, crontab, pipelines.json
- **`close`** — final verification, status.json, queue item update, summary report

A typical build:

```
plan-a → build-a → audit-a → wire → close
```

A more complex build with an alternative path:

```
plan-a → plan-b → build-a → build-b (non-conflicting) → audit-a → wire → close
```

The phase name goes in the commit message: `feat(tweet-pipeline): build-a — error handling and threshold gates`. A git log tells the exact story of how the task executed.

---

## Gate Checking Between Phases

A gate check is the verification that runs between phases — the condition that must pass before the next phase starts.

### Exit code verification

Every phase should exit with code 0 on success, non-zero on failure. The orchestrating script checks:

```bash
node scripts/build-a.js
if [ $? -ne 0 ]; then
  echo "build-a failed — aborting graph"
  exit 1
fi
git add -A && git commit -m "feat: build-a complete"
```

If the exit code is non-zero, the graph stops. The failure is logged, the task resets to "queued" with an error note, and no bad state propagates forward.

### Artifact existence check

More important than exit codes: verify the artifacts exist on disk.

```javascript
const required = [
  'scripts/tweet-pipeline.js',
  'data/pipeline-runs/',
  'docs/tweet-pipeline.md'
];

const missing = required.filter(p => !fs.existsSync(path.join(buildDir, p)));
if (missing.length > 0) {
  throw new Error(`Gate check failed — missing: ${missing.join(', ')}`);
}
```

A process can exit 0 while having produced no useful output. File existence is the real check.

### Schema validation

For JSON output files, validate the schema before advancing:

```javascript
const status = JSON.parse(fs.readFileSync(statusPath));
if (!status.artifacts || status.artifacts.length === 0) {
  throw new Error('Gate check failed — status.json has empty artifacts array');
}
```

---

## When to Deviate from Sequential

Sequential execution is the default. There are genuine cases where parallel is appropriate.

### Genuinely independent workstreams with no shared files

If two build tasks don't touch any of the same files, have no data dependencies between them, and won't both be making calls to the same rate-limited API simultaneously — they can run in parallel.

Example: one agent generates documentation for completed pipeline A while another builds pipeline B from scratch. Different files, different content, no coordination needed.

### Fan-out research

Research tasks that decompose into many independent lookups genuinely benefit from parallelism. "Find the GitHub repo for each of these 20 tools" — 20 independent HTTP calls with no dependencies. Run them simultaneously.

**Anthropic's finding (2025)**: multi-agent systems outperformed single agents by 90.2% on breadth-first research tasks. The key word is "breadth-first" — many independent directions. For linear dependency chains, the same research found sequential collaboration produces higher-quality results.

### The test before parallelizing

Before running anything in parallel, ask:
1. Do these tasks write to any of the same files? If yes: sequential.
2. Does one task's output inform what the other does? If yes: sequential.
3. Will both tasks hit the same rate-limited API? If yes: either sequential or staggered.
4. Is the coordination protocol more complex than the work itself? If yes: sequential.

If all four answers are "no" — parallel is reasonable.

---

## Research Backing

The research consensus on this is unusually clear:

**AWS ML Blog (Nov 2025):** "Sequential collaboration often produces higher-quality results than parallel approaches — especially when one phase informs the design of the next."

**LangGraph (Bussler, Oct 2025):** Parallel branch execution requires "complex state coordination guards" to maintain correctness. Sequential execution eliminates this problem surface entirely.

**AutoGen research (Oct 2025):** Naive parallel swarms consistently underperform sequential graphs in benchmarks. Root causes: conflicting writes, no shared context, rate limit thrashing.

**Confluent (2025):** The blackboard pattern (shared scratchpad, sequential writes) outperforms message-passing coordination for agent handoffs in production systems.

**Core insight (Phil Schmid / Google Developers Blog, Dec 2025):** "Context Engineering is not about adding more context. It is about finding the *minimal effective context* required for the next step." The biggest performance gains came from *removing* complexity, not adding it.

---

## Applied: Pipeline Stage Types

Different pipeline stages have different AI requirements. Mixing them up burns money:

| Stage Type | AI Needed? | Context Budget |
|---|---|---|
| Fetch / Scrape | No | None |
| Relevance gate | Yes (cheap) | Task + item text only |
| Generation | Yes (full) | Task + format spec + relevant artifact fields |
| Humanizer | Yes (medium) | Original text + score flags + voice rules |
| Dedup / Merge | No | None |
| Delivery (write/send) | No | None |

Expensive AI calls go only in generation stages. Cheap Haiku-tier calls for relevance gates. No AI where deterministic logic suffices.

---

## Related

- [[infrastructure/graph-orchestration|Graph Orchestration]] — the foundational concepts and research backing
- [[concepts/four-role-orchestrator-chain|Four-Role Orchestrator Chain]] — role-based sequential agent handoff pattern
- [[concepts/build-queue-pattern|Build Queue Pattern]] — the queue these graph executions pull from
