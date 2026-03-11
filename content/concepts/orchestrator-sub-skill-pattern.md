---
title: Orchestrator Sub-Skill Pattern
description: Top-level orchestrator skills delegate to focused sub-skills — keeping individual skills narrow, composable, and independently replaceable
tags: [concepts, architecture, skills, orchestration, openclaw]
---

Each top-level orchestrator skill delegates to focused sub-skills. The orchestrator handles sequencing and handoffs; the sub-skills handle execution. This keeps individual skills narrow, composable, and independently replaceable.

## The structure

```
competitive-analysis/
  SKILL.md              ← orchestrator: sequences sub-skills, manages artifact
  sub-skills/
    scrape-ads.md       ← fetches creative library for a brand
    analyze-creative.md ← extracts copy angles, hooks, CTAs
    benchmark.md        ← compares against your own positioning
    report.md           ← formats findings for delivery
```

The orchestrator's job is logistics: what runs first, what data flows where, what the handoff looks like. It doesn't do the actual work — it routes to the sub-skill that does.

## Why narrow sub-skills

**Single responsibility.** A sub-skill that does one thing is testable in isolation. You can run `analyze-creative.md` on a known input and verify the output before wiring it into a pipeline.

**Replaceability.** If the creative analysis logic needs to change, you replace one sub-skill. The orchestrator and other sub-skills are untouched.

**Reuse.** The same `web-search.md` sub-skill can be used by the competitive analysis orchestrator, the research scanner, and the morning brief builder. Write once, compose many times.

## The handoff contract

Each sub-skill declares its expected input and output in its header:

```markdown
# Analyze Creative

## Input
- brand_name: string
- creative_urls: list of image/video URLs
- competitor_context: brief text (from scrape-ads output)

## Output
- angles: list of copy angles detected
- hooks: opening hooks used
- ctas: calls to action
- tone: adjective describing brand voice
```

The orchestrator reads the output spec of sub-skill N and feeds it as input to sub-skill N+1. The contract is explicit and versioned in text.

## When to use an orchestrator vs a flat skill

Use an orchestrator when:
- The task has 3+ distinct stages that each need focused context
- Stages could be independently reused or replaced
- The combined context would exceed practical limits for a single skill

Use a flat skill when:
- The task is simple enough to do in one pass
- The stages are tightly coupled and wouldn't make sense in isolation
- You're prototyping and the full structure would slow you down

Start flat. Extract sub-skills when the flat skill grows unwieldy.

## Related

- [[concepts/skill-based-agent-architecture|Skill-Based Agent Architecture]] — the foundation this pattern builds on
- [[concepts/four-role-orchestrator-chain|Four-Role Orchestrator Chain]] — a specific four-role orchestration pattern
- [[concepts/input-validation-in-skills|Input Validation in Skills]] — pre-flight validation at each sub-skill boundary
- [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — the sequential execution model that governs orchestration
