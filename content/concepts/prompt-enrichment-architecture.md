---
title: Prompt Enrichment Architecture
description: Systems that automatically transform rough or incomplete prompts into structured, optimized instructions before they reach an AI agent or model.
tags: [concepts, agents, prompts, architecture, quality, automation, pipelines]
---

The quality of an AI agent's output depends heavily on the quality of its input. But in practice, the instructions agents receive — from users, from other systems, from task queues — are often rough, ambiguous, or missing context the agent needs to do good work. Prompt enrichment architecture is the layer that systematically improves prompts before they reach the agent, decoupling input quality from input source.

## The input quality problem

A user typing a task into a chat interface writes something like: "fix the checkout bug." An automated pipeline might emit: "process queue item 47." Neither is a good agent prompt. Both lack context the agent needs: which bug, in which file, with what constraints, and what does "done" look like?

Without enrichment, the agent either asks clarifying questions (slowing down the pipeline), makes assumptions that may be wrong (reducing output quality), or fails entirely (wasting compute and requiring retry).

The alternative is to intercept the rough input before it reaches the agent and programmatically expand it into something the agent can act on reliably.

## What enrichment adds

Prompt enrichment is not just prompt engineering. It's a runtime transformation that pulls in context the original prompt didn't include:

**Structural expansion** — reformatting a one-line instruction into a structured prompt with an explicit task description, context section, constraints, and success criteria. The agent receives a complete spec rather than a fragment.

**Context injection** — automatically attaching relevant background: recent conversation history, user preferences, the current state of the system, or documents related to the task. The agent doesn't need to fetch this itself.

**Clarification and disambiguation** — detecting underspecified terms and resolving them before the agent starts. "Fix the checkout bug" becomes "Fix the null pointer exception in `checkout/payment.ts` line 247, introduced in commit a3f9b, which causes the payment confirmation page to error on non-US address formats."

**Constraint surfacing** — adding implicit constraints the agent should know about but wasn't told: don't modify files under test lock, stay within the current sprint scope, don't call external APIs during the build phase.

**Format specification** — telling the agent explicitly what output format is expected: a git commit, a markdown file at a specific path, a JSON object matching a schema. Reduces ambiguity about what "done" means.

**Prior attempt context** — if this task has been tried before (and failed), injecting what was attempted and why it didn't work, so the agent can take a different approach rather than repeating the failure.

## Architecture patterns

### Pre-agent enrichment pipeline

The most common pattern: a dedicated enrichment step runs between task intake and agent dispatch.

```
Task intake (user input / queue / trigger)
    ↓
Enrichment pipeline
  ├── Structural template application
  ├── Context retrieval (memory, docs, state)
  ├── Constraint injection
  └── Format specification
    ↓
Enriched prompt → Agent
```

The enrichment pipeline can itself use an LLM (a smaller, faster model optimized for this task) or rule-based logic, or a combination. The agent receives only the enriched version — it never sees the rough input.

### Iterative refinement

For complex tasks, enrichment is not a single pass but a feedback loop. The agent attempts the task; the result is evaluated; if it falls short, the failure is analyzed and the prompt is re-enriched with the failure context before retry.

```
Rough prompt → Enrich → Agent → Evaluate
                  ↑                  |
                  └──── Failure ─────┘
```

This is more expensive per task but significantly increases success rate on tasks where the failure mode is "agent didn't understand what was needed."

### Skill-level enrichment

Rather than enriching at the task level, enrichment is embedded in individual skills or tools. When an agent invokes a skill, the skill wrapper enriches the invocation — normalizing parameters, adding context from the agent's current state, and validating inputs before executing. The agent authors a rough call; the skill makes it precise.

### User profile enrichment

For multi-user systems, enrichment incorporates user-specific context: communication preferences, domain vocabulary, past decisions, active projects. The same rough prompt produces different enriched prompts for different users because the context injection layer knows who is asking.

## Enrichment vs. system prompts

System prompts provide static context — instructions that apply to every interaction. Enrichment provides dynamic context — information specific to this particular prompt. They're complementary:

- System prompts establish the agent's role, constraints, and behavioral defaults
- Enrichment adds the task-specific context the system prompt can't anticipate

A well-architected agent uses both: a stable system prompt that doesn't change between tasks, and a dynamic enrichment layer that ensures each prompt carries the context it needs.

## Quality and consistency benefits

In a multi-agent pipeline where many different tasks flow through many different agents, enrichment provides consistency at scale. Without enrichment, output quality varies with input quality — some tasks are described well, others poorly, and the pipeline's reliability reflects that variance.

With a standardized enrichment layer, the pipeline's effective input quality floor rises. Rough inputs get lifted to a consistent level before reaching agents, which means agents can be tuned for structured, context-rich prompts rather than needing to handle every possible level of ambiguity.

This is especially valuable in autonomous pipelines where there's no human in the loop to catch a bad prompt before it's sent.

## Relationship to adjacent patterns

- [[input-validation-in-skills]] — input validation is a complementary first gate; enrichment adds context, validation enforces contracts
- [[orchestrator-sub-skill-pattern]] — the orchestrator can apply enrichment before dispatching to sub-skills
- [[four-role-orchestrator-chain]] — a planner-role agent often performs implicit enrichment before handing tasks to executor agents; making this explicit improves reliability
- [[agent-self-review-loop]] — post-execution review identifies prompt quality issues that inform enrichment improvements
- [[cognitive-load-optimization]] — enrichment offloads the cognitive work of context retrieval from the agent onto infrastructure
- [[binary-choice-architecture]] — enriched prompts with explicit success criteria make binary evaluation (done / not done) more reliable
