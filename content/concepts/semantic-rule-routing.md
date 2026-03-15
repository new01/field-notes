---
title: Semantic Rule Routing
description: Dynamically selecting which rules, skills, or context files to inject per prompt based on semantic relevance — loading 2–3 targeted rules instead of flooding the context window with everything.
tags: [concepts, prompts, context, rules, skills, agents, efficiency, routing]
---

Semantic rule routing is the practice of analyzing each incoming prompt and selectively injecting only the rules or skills most relevant to it — rather than loading the full rule set unconditionally. Instead of a flat "dump everything into context" approach, a routing layer sits in front of each agent invocation and picks 2–3 targeted instructions.

The mechanism mirrors how a skilled engineer doesn't recite every coding standard before each task — they pull up the relevant checklist for the specific work at hand.

## The problem it solves

AI coding tools like Claude Code, Cursor, and Codex load rules from dedicated directories (`.claude/rules/`, `.cursor/rules/`, `.codex/AGENTS.md`). As teams accumulate rules — testing conventions, security guidelines, framework patterns, commit message formats — the aggregate context grows. Loading 30+ rules per prompt has two concrete costs:

**Token waste** — rules irrelevant to the current task consume context budget that could hold more meaningful information (codebase content, conversation history, tool output).

**Attention dilution** — frontier LLMs are not perfectly uniform across their context window. Burying the relevant instruction among 30 others reduces the probability it gets weighted correctly. Teams commonly observe rules being "ignored" once the rule count passes a threshold (around 40–50 files is a commonly reported inflection point).

## How semantic routing works

A semantic router intercepts the prompt before the LLM processes it. The routing step:

1. **Embeds the prompt** — converts it to a vector representation
2. **Scores rules** — compares against pre-indexed embeddings of each rule's content or description
3. **Selects top-k** — injects only the 2–3 highest-scoring rules into the context
4. **Passes to model** — the LLM sees a lean, targeted context

In practice, this runs as a pre-prompt hook (e.g., a Claude Code `PrePromptHook`) that rewrites the effective rule set before each turn. The routing decision adds a small latency penalty but reduces net token usage significantly on rule-heavy configurations.

A fallback mode ("keyword routing") skips embeddings and matches rules based on token overlap — faster, less accurate, useful when a local embedding model isn't available.

## Cross-tool rule unification

A secondary problem semantic routing tools address is rule fragmentation across coding assistants. Teams using Claude Code, Cursor, and Codex simultaneously often maintain three parallel rule sets that drift apart over time.

The pattern: write rules once in a canonical format, then distribute them to each tool's expected directory/format automatically. The router layer handles per-tool conversion:

- Claude Code → `.claude/rules/*.md` with semantic routing active
- Cursor → `.cursor/rules/*.mdc` (auto-converted format)
- Codex → `.codex/AGENTS.md` (aggregated into single file)

One source of truth, multiple deployment targets.

## Tradeoffs

**Routing accuracy** — semantic matching is probabilistic. A rule critical for security (e.g., "never expose API keys in logs") should not depend on semantic routing to be included — it should be a global/always-on rule, separate from the routed set. Reserve routing for high-volume, task-specific rules.

**Cold start** — the router needs to index rule embeddings before it can route. For small rule sets (<10 files) the routing overhead may exceed the benefit; flat loading is simpler.

**Debuggability** — when the model misses a rule, the failure mode shifts from "model ignored the rule" to "router didn't select the rule." Both are opaque, but the routing layer adds one more diagnostic step.

**Embedding model dependency** — semantic routing at its best requires a local embedding model. The quality of routing correlates with the quality of the embeddings.

## When to use it

Semantic rule routing pays off when:

- Rule count exceeds ~20 files
- Rules are highly task-specific (framework-specific, component-specific)
- Token budget is a real constraint (long sessions, large codebases)
- The same rules are maintained across multiple AI tools

It adds unnecessary complexity when:

- Rules are few and general
- Context budget is ample
- The team uses a single tool

## Related concepts

- [[Prompt File Governance]] — how to structure and maintain rule sets over time
- [[Skill-Based Agent Architecture]] — routing at the skill/capability level
- [[Agent Skill Packages]] — packaging reusable agent behaviors
- [[Prompt Enrichment Architecture]] — upstream prompt transformation before model invocation
- [[Cognitive Load Optimization]] — reducing unnecessary load on model context
