---
title: Dynamic Rule Loading
description: Semantic routing systems that select only the relevant 2–3 rules or skills per prompt at runtime, rather than loading the full ruleset into context — cutting token waste while preserving agent behavior quality.
tags: [concepts, agents, context, token-efficiency, rules, skills, routing]
---

Dynamic rule loading is a technique for managing agent instructions at runtime: instead of injecting an agent's entire ruleset into every prompt, a semantic router selects only the 2–3 rules most relevant to the current task and loads those. The rest stays on disk.

The result is dramatically smaller context windows per invocation — with no loss in behavioral coverage, since irrelevant rules don't affect output anyway.

## The problem: static rule loading wastes tokens

Most AI coding agents (Claude Code, Cursor, Codex) load all configured rules on every prompt. For small rulesets this is fine. But as teams build up libraries of 20–30+ rules — covering coding style, architecture patterns, testing conventions, security guidelines, and tool usage — the context overhead becomes significant.

A 30-rule library might consume 8,000–15,000 tokens per prompt. At scale, across hundreds of prompts per day, that accumulates into real cost. Worse, it crowds out code context that would actually help the model reason about the task.

Dynamic loading solves this by treating the ruleset as a retrieval problem rather than a static payload.

## How it works

At its core, dynamic rule loading requires two components:

**1. A rule index** — each rule is tagged with keywords, semantic descriptions, or embeddings that describe when it applies. Example: a rule titled "React component structure" is tagged with `react`, `component`, `jsx`, `tsx`.

**2. A semantic router** — a lightweight process that runs on each prompt (via a tool hook or pre-processing step) and scores the rule index against the incoming task description. It selects the top 2–3 matches and injects only those.

Router implementations range from simple to sophisticated:
- **Keyword matching** — fast, zero cost, works well for structured rules with clear scope
- **TF-IDF or BM25** — slightly smarter term weighting, still no LLM calls
- **Embedding similarity** — more semantically aware; uses a small embedding model
- **LLM-based classification** — highest accuracy; a small model (GPT-4o-mini, Claude Haiku) classifies the prompt and routes accordingly, typically costing ~$0.50/month at normal usage

## Token savings

The reduction is substantial. If 30 rules average 400 tokens each, static loading costs 12,000 tokens per prompt. Dynamic loading of 2–3 rules costs ~800–1,200. That's an 84–93% reduction in rule-injection overhead — which translates directly to faster responses, lower API costs, and more room for actual code context.

## Cross-tool rule sharing

A secondary benefit of centralizing rule management is write-once, deploy-everywhere distribution. Rules authored once can be compiled to the format expected by Claude Code (CLAUDE.md skills), Cursor (.cursor/rules), Codex (AGENTS.md), or any other agent that reads flat-file instructions. The dynamic loading layer sits above all of them.

This eliminates the maintenance burden of keeping diverging rule files in sync across tools — particularly relevant for teams using multiple agents.

## Tradeoffs

| Factor | Static Loading | Dynamic Loading |
|---|---|---|
| Setup | None | Requires router + rule index |
| Token cost | High (all rules every time) | Low (2–3 rules per prompt) |
| Rule coverage risk | None (everything always present) | Misrouting can miss a relevant rule |
| Speed | Instant | Adds 10–100ms routing step |
| Transparency | Rules always visible | Harder to debug which rules applied |

The main failure mode is routing misses: if a rule isn't triggered when it should be, the agent lacks that guidance. Teams using this pattern typically add an "always-on" base layer of 2–3 critical rules that load unconditionally, with the dynamic layer handling the rest.

## Where this fits

Dynamic rule loading is an instance of the broader [[Prompt Enrichment Architecture]] pattern — pre-processing inputs to inject exactly the right context, no more and no less.

It's particularly valuable in:
- **Large monorepos** with many distinct sub-domains, each with its own conventions
- **Multi-agent pipelines** where different agents need different rule subsets
- **Cost-sensitive deployments** where API spend scales with context size
- **Teams with 10+ rules** where static loading starts to noticeably bloat context

See also: [[Agent Skill Packages]] for how rules and skills are typically structured, [[Skill-Based Agent Architecture]] for the broader organizational pattern, and [[Pipeline Cost Per Run]] for how to model the economics.
