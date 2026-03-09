---
title: "LLM Cost Tracking"
---

# LLM Cost Tracking

If you're running OpenClaw agents that handle real workloads, you're spending money on API calls. Without instrumentation, you don't know how much, which models, or which workflows are expensive. That makes optimization guesswork and makes cost projections impossible.

LLM cost tracking is straightforward: record every API call with enough data to audit later.

---

## What to Capture Per Call

```sql
CREATE TABLE llm_calls (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  called_at INTEGER NOT NULL,       -- unix timestamp
  provider TEXT NOT NULL,           -- 'anthropic' | 'openai' | etc
  model TEXT NOT NULL,              -- 'claude-sonnet-4-5' | etc
  tokens_in INTEGER NOT NULL,
  tokens_out INTEGER NOT NULL,
  cost_usd REAL NOT NULL,           -- calculated at call time
  duration_ms INTEGER,
  task_context TEXT                 -- what was this call for? (optional)
);
```

A parallel JSONL log (`llm_calls.jsonl`) gives you a lightweight per-call trail that works even when the SQLite write fails. Write to both.

---

## Cost Estimation Module

Maintain a pricing table in code, separate from the call logging:

```json
{
  "claude-sonnet-4-5": {
    "input_per_1m": 3.00,
    "output_per_1m": 15.00
  },
  "claude-haiku-3-5": {
    "input_per_1m": 0.80,
    "output_per_1m": 4.00
  }
}
```

Calculate cost at call time, not in post-processing. Storing `cost_usd` in the log means the dashboard is always correct even if you update pricing later — historical records preserve what you paid, not what you'd pay today.

The pricing table needs updates when providers change prices. Keep it in a config file, not hardcoded.

---

## Usage Dashboard Queries

Once you have the data, useful queries:

**Daily spend:**
```sql
SELECT 
  date(called_at, 'unixepoch') as day,
  SUM(cost_usd) as total_cost,
  COUNT(*) as call_count,
  SUM(tokens_in + tokens_out) as total_tokens
FROM llm_calls
GROUP BY day
ORDER BY day DESC;
```

**Cost by model (last 7 days):**
```sql
SELECT 
  model,
  SUM(cost_usd) as cost,
  AVG(tokens_in) as avg_tokens_in,
  AVG(tokens_out) as avg_tokens_out,
  COUNT(*) as calls
FROM llm_calls
WHERE called_at > strftime('%s', 'now', '-7 days')
GROUP BY model
ORDER BY cost DESC;
```

**Most expensive workflows** (requires `task_context`):
```sql
SELECT task_context, SUM(cost_usd) as cost
FROM llm_calls
WHERE task_context IS NOT NULL
GROUP BY task_context
ORDER BY cost DESC
LIMIT 20;
```

---

## What This Makes Possible

**Model selection decisions.** If a workflow that currently uses Claude Sonnet would work just as well with Haiku, that's a 4-6x cost difference. You can't know that without the data.

**Scaling projections.** "This workflow costs $0.04 per run, runs 24 times/day, costs $28/month" — that's a real number you can make decisions with. Without tracking, you're guessing.

**Identifying expensive prompts.** High token counts on output usually mean the model is being verbose for no reason. A prompt tweak can cut costs significantly on high-frequency tasks.

**Justifying infrastructure.** If you're spending $X/month on API calls, local alternatives (smaller models, cached responses, batching) become worth evaluating.

---

## Implementation Notes

This data is only useful if it's actually collected. The highest-friction part is instrumentation — every LLM call in your stack needs to call the logging function. If you add tracking after building several workflows, you'll have gaps.

The practical approach: build the logging module first, then wrap every LLM call through it. One function, one place, always called.

---

## Sources

Matthew Berman ("5 Billion Tokens Perfecting OpenClaw," Prompt 12) — llm_calls SQLite table, JSONL parallel log, cost estimator module, usage dashboard queries.

---

**Related:**
- [[infrastructure/cron-infrastructure|Cron Job Infrastructure]] — the same SQLite-backed pattern applied to job scheduling
- [[concepts/prompt-file-governance|Prompt File Governance]] — reducing token spend by controlling what auto-loads
