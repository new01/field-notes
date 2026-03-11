---
title: Pipeline Cost Per Run
description: Tracking the actual token cost of each agent pipeline run — the benchmark that makes "is this worth automating?" a real question with a real answer
tags: [concepts, cost, infrastructure, observability, openclaw]
---

Tracking the actual token cost of each agent pipeline run turns "is this worth automating?" from a gut-feel question into one with a real answer.

## The benchmark

A full competitive research → creative analysis → positioning report pipeline on a capable model costs roughly $24 per run. That's a concrete number to build unit economics around.

At $24/run:
- Running it daily = $720/month
- Running it weekly = ~$96/month
- Running it on-demand when needed = variable, but tracked

Without per-run cost tracking, none of those numbers are visible until the billing invoice arrives.

## What to track

Per pipeline run:
- `pipeline_name` — which pipeline ran
- `model` — which model was used for each stage
- `input_tokens` — tokens consumed as input (system prompt + context)
- `output_tokens` — tokens generated
- `cost_usd` — calculated from token counts × per-token pricing
- `run_id` — ties back to the artifact file for the run
- `duration_ms` — wall clock time (model cost + latency)

Per stage within a run:
- Stage name, model used, token counts, cost

The stage breakdown reveals which stages are expensive — usually the generation stages with large context windows, not the cheap relevance-gate stages.

## Implementation pattern

```js
// Log at the end of each API call
await logLlmCall({
  model: 'claude-haiku-4-5',
  input_tokens: response.usage.input_tokens,
  output_tokens: response.usage.output_tokens,
  pipeline: 'tweet-batch',
  stage: 'generation',
  run_id: runId,
});
```

Store in SQLite — synchronous writes, no network dependency, queryable with standard tools.

## Cost vs value

The goal isn't to minimize cost — it's to make cost visible so decisions are grounded. A $24 competitive analysis run that surfaces one high-signal competitor move is worth far more than $24. A $2 tweet generation run that produces six drafts that all get killed is probably not.

Per-run tracking makes both of those calculations possible.

## Model selection as a cost lever

Most pipeline stages don't need the most capable model. A relevance gate (is this content worth processing?) can use a cheap fast model. Only generation and synthesis stages need the full-capability model.

Tracking per-stage costs makes model selection decisions visible:

| Stage | Model | Cost |
|-------|-------|------|
| Relevance gate | haiku | $0.002 |
| Generation | sonnet | $0.18 |
| Self-review score | haiku | $0.001 |
| **Total** | | **$0.183** |

Replace the haiku gate with sonnet and cost jumps 5×. The data makes that tradeoff explicit.

## Related

- [[LLM Cost Comparison Tools]] — tools for comparing per-token pricing across providers
- [[Graph Orchestration Patterns]] — the pipeline architecture cost tracking plugs into
- [[Subscription Token Account Risk]] — why API pricing (not subscription) is required for production workloads
- [[Overload-Tolerant Event Ledger]] — the event log that per-run costs feed into
