---
title: Toyota Production System for Agents
description: Applying the TPS stop-the-line principle to LLM agents — agents halt and signal when they detect quality issues rather than pushing through and compounding errors
tags: [concepts, quality, architecture, reliability, openclaw]
---

The Toyota Production System's most famous principle: any worker on the assembly line can pull the Andon cord to stop the entire line when they detect a defect. The line stops, the problem is fixed, then production resumes. No defective unit moves to the next stage.

Applied to LLM agents: when an agent detects a quality issue in its own output or its upstream input, it halts and signals rather than pushing through.

## Why agents don't naturally stop

LLM agents are trained to be helpful and to complete tasks. This creates a bias toward continuing: when something looks wrong, the agent often tries to work around it, making assumptions, filling gaps, proceeding with degraded input rather than stopping.

The result: defects propagate downstream. A hallucinated fact in stage 2 becomes a confident claim in stage 4. A malformed input that stage 2 "handles" produces subtly wrong output that only fails visibly at delivery.

## The Andon pattern for agents

```
Stage N detects issue →
  Writes structured signal to artifact: { "halted": true, "reason": "...", "at_stage": N }  →
    Executor stops pipeline execution →
      Notifies operator →
        Resumes only after explicit operator override or fix
```

The signal must be structured — not just an error message, but a machine-readable halt record with the specific issue and the stage that detected it.

## What triggers a halt

**Input quality failures:** upstream stage produced output that doesn't meet this stage's declared input contract (missing fields, stale timestamps, invalid format).

**Self-review failures:** generated output scored below quality threshold after retry.

**Confidence failures:** agent explicitly expresses low confidence in its output (some prompting strategies elicit this reliably).

**Constraint violations:** output would violate a declared constraint (length, format, content policy).

## Implementation via Andon (the tool)

Andon (github.com/allnew-llc/andon-for-llm-agents) implements this pattern as a middleware layer:
- Wraps each agent call with quality checks
- Maintains a halt log that operators can inspect
- Supports configurable resume conditions (auto-resume after N minutes, manual resume, or never)

## Trade-off with throughput

The TPS analogy has a real tension: stopping the line reduces throughput. In manufacturing, this is accepted because defect cost > throughput cost. In agent pipelines, evaluate case by case.

For pipelines producing content that a human will review anyway, halting is cheap — the human would catch it. For fully automated pipelines where output goes directly to production, halting is critical — the defect has no other gate.

## Related

- [[Agent Self-Review Loop]] — the self-review step that can trigger a halt
- [[Input Validation in Skills]] — the input contract that detects upstream failures
- [[Four-Role Orchestrator Chain]] — the pipeline structure where Andon halts propagate
- [[Dead-Man's Switch]] — the complementary monitoring pattern (absence of signal vs explicit halt signal)
