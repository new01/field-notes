---
title: Skill-Based Agent Architecture
description: Every agent capability as a plain markdown instruction file — skills define workflow, tools, inputs, and handoffs in prose with no code
tags: [concepts, architecture, skills, openclaw]
---

# Skill-Based Agent Architecture

Every agent capability is a plain markdown instruction file. Skills define workflow, tools, inputs, and handoffs in prose — no code, no platform dependency, just structured instructions the agent reads and executes.

## Why Plain Text

### The coupling problem

Code-based agent capabilities create hard coupling between the capability definition and the execution environment. When the runtime changes — different model, different framework, different API version — the code breaks.

#### What breaks with code-based skills
- Tool call signatures change across model versions
- Framework-specific abstractions become obsolete
- Non-engineers can't audit or modify capabilities
- Debugging requires reading stack traces, not logic

### What prose-based skills give you

Prose-based skills decouple the *what* from the *how*. The skill says "search for recent GitHub repos matching these criteria, filter by star count, summarize the top 5." The agent figures out the tool calls. The skill author doesn't write the tool calls.

#### The portability advantage
A prose skill written for Claude 3.5 still works with Claude 4.x. The instructions are model-agnostic. The model handles the implementation.

#### The auditability advantage
A skill that does competitive research can be reviewed by anyone who can read. Non-engineers can understand, modify, and approve agent capabilities without a developer in the loop.

## Skill Anatomy

A well-formed skill has six sections. Each has a specific purpose.

### Purpose

One sentence: what does this skill produce and why.

##### Examples of good purpose statements
- "Search GitHub for repos with >100 stars mentioning [topic], return the top 5 with summaries."
- "Given a draft tweet, score it against 28 AI-pattern detectors and return a score from 0-100."

##### Examples of bad purpose statements
- "Help with research." (too vague)
- "Do the competitive analysis thing." (not a specification)

### Required Inputs

The pre-flight contract. If inputs aren't present or are stale, the skill declares failure before doing any work.

```markdown
## Required inputs
- query: natural language search term (string)
- max_results: how many results to return (integer, 1-20)
- min_stars: minimum GitHub star count threshold (integer)
```

#### Input validation
Every required input should be checked at skill start. Missing or malformed inputs should produce a clear error — not a hallucinated substitution.

### Steps

Explicit, numbered actions. Each step should be independently verifiable.

```markdown
## Steps
1. Search GitHub repos using the query parameter with these exact filters: ...
2. Filter results where star_count >= min_results
3. For each result (max max_results): fetch README, summarize in 2-3 sentences
4. Rank by relevance to query
5. Return structured output
```

##### What makes a good step
Specific enough that the agent can't fill in gaps with guesses. "Search GitHub" is too vague. "Search GitHub repos using query with filters: stars:>100, pushed:>2024-01-01, language:Python" is a step.

### Output Format

Description of exactly what the skill produces. Typed fields if the output feeds into another skill.

### Handoff

What the next stage in the pipeline needs from this skill's output. This is the contract for the downstream consumer.

### The complete template

```markdown
# Skill Name

## Purpose
One sentence: what does this skill produce and why.

## Required inputs
- input_a: description, format
- input_b: description, format

## Steps
1. [Specific action with explicit parameters]
2. [Specific action with explicit parameters]
...

## Output format
Description of what the skill produces. Schema if downstream needs it.

## Handoff
What the next stage needs from this skill's output.
```

## Skills as Composable Units

### The composability pattern

The power of skill-based architecture is composition. A `competitive-analysis` skill can call a `web-research` sub-skill, which calls a `source-fetch` sub-skill. Each is independently testable and replaceable.

```
competitive-analysis/
  SKILL.md          ← top-level orchestrator
  sub-skills/
    web-research.md
    summarize.md
    compare.md
```

#### How delegation works
The top-level skill references sub-skills by name. The agent resolves the delegation and executes the sub-skill. No explicit invocation syntax — just naming the sub-skill and describing what it should produce.

### Independent replaceability

Replace `web-research.md` with a version that uses a different data source. The `competitive-analysis` orchestrator doesn't change. The interface (inputs → outputs) stays stable; the implementation swaps.

## Trade-offs

### Advantages

- **Portable** — works across model versions and runtimes
- **Readable** — reviewable by non-engineers
- **Versionable** — git history for skill evolution
- **Composable** — mix and match without code changes
- **Fast to write** — prose is faster than code for workflow logic

### Disadvantages

- **Complex conditionals** — branching logic is awkward in prose; use code for complex decision trees
- **Performance-critical operations** — parsing, computation, heavy data processing still need code
- **Debugging** — requires reading agent reasoning traces, not stack traces

##### When to fall back to code
If the logic can't be expressed clearly in prose, or if the agent consistently misinterprets the prose version, write the logic as a script and have the skill call the script via Bash.

## Related

- [[concepts/four-role-orchestrator-chain|Four-Role Orchestrator Chain]] — four-role pipeline built on skill-based capabilities
- [[concepts/orchestrator-sub-skill-pattern|Orchestrator Sub-Skill Pattern]] — how top-level orchestrators delegate to sub-skills
- [[concepts/input-validation-in-skills|Input Validation in Skills]] — the pre-flight pattern for validating skill inputs
- [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — the broader orchestration framework skills operate within
- [[skill-store/index|Skill Store]] — published skills available to install
