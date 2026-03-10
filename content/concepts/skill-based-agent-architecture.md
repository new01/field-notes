---
title: Skill-Based Agent Architecture
description: Every agent capability as a plain markdown instruction file — skills define workflow, tools, inputs, and handoffs in prose with no code
tags: [concepts, architecture, skills, openclaw]
---

Every agent capability is a plain markdown instruction file. Skills define workflow, tools, inputs, and handoffs in prose — no code, no platform dependency, just structured instructions the agent reads and executes.

## Why plain text

Code-based agent capabilities create a hard coupling between the capability definition and the execution environment. When the runtime changes (different model, different framework, different API version), the code breaks.

Prose-based skills decouple the *what* from the *how*. The skill says "search for recent GitHub repos matching these criteria, filter by star count, summarize the top 5." The agent figures out the tool calls. The skill author doesn't write the tool calls.

This also makes skills auditable by non-engineers. A skill that does competitive research can be reviewed by anyone who can read.

## Skill anatomy

A well-formed skill has:

```markdown
# Skill Name

## Purpose
One sentence: what does this skill produce and why.

## Required inputs
- input_a: description, format
- input_b: description, format

## Steps
1. [Step with explicit action]
2. [Step with explicit action]
...

## Output format
Description of what the skill produces.

## Handoff
What the next stage in the pipeline needs from this skill's output.
```

The `Required inputs` section is the pre-flight contract: if inputs aren't present or are stale, the skill declares failure before doing any work.

## Skills as composable units

The power of skill-based architecture is composability. A `competitive-analysis` skill can call a `web-research` sub-skill, which calls a `source-fetch` sub-skill. Each is independently testable and replaceable.

```
competitive-analysis/
  SKILL.md          ← top-level orchestrator
  sub-skills/
    web-research.md
    summarize.md
    compare.md
```

The top-level skill delegates to sub-skills by name. The agent resolves the delegation.

## Trade-offs

**Advantages:** portable across runtimes, readable by non-engineers, easy to version in git, composable without code changes.

**Disadvantages:** complex conditional logic is awkward in prose; performance-critical operations still need code; debugging requires reading agent reasoning traces rather than stack traces.

For most workflow automation, the advantages dominate. Fall back to code only where prose genuinely can't express the logic.

## Related

- [[Four-Role Orchestrator Chain]] — the four-role pipeline built on skill-based capabilities
- [[Orchestrator Sub-Skill Pattern]] — how top-level orchestrators delegate to sub-skills
- [[Input Validation in Skills]] — the pre-flight pattern for validating skill inputs
- [[Graph Orchestration Patterns]] — the broader orchestration framework skills operate within
