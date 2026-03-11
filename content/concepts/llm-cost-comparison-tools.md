---
title: LLM Cost Comparison Tools
description: The emerging ecosystem of tools for comparing LLM API pricing — CLI utilities, MCP servers, and dashboards covering 400+ models
tags: [concepts, cost, tooling, infrastructure]
---

A cluster of tools has emerged for comparing LLM API pricing across providers — filling the gap left by rapidly changing model pricing that's hard to track manually.

## The tools (as of early 2026)

**LLM-costs** — an `npx` CLI that outputs per-token costs for common models:
```bash
npx llm-costs compare claude-sonnet gpt-4o gemini-pro
```

**TokenTax** — covers 400+ models with structured pricing data, exportable as JSON. Useful for programmatic cost calculations in pipeline tracking.

**Volt HQ** — exposes pricing data as an MCP server, making it callable directly from agent contexts.

**Agentlytics** — local agent stats dashboard that tracks actual token consumption per session alongside pricing data, producing real cost-per-session numbers.

## Why this matters

Model pricing changes frequently — Anthropic, OpenAI, and Google all adjust pricing as they release new model tiers. Hardcoded pricing in cost tracking code goes stale within months.

The right approach: pull live pricing from a tool like TokenTax rather than maintaining a local pricing table. This keeps cost calculations accurate without manual updates.

## For agent pipeline cost tracking

The recommended pattern:
1. Pull model pricing from a live source (TokenTax API or local cache)
2. After each API call, record: model, input_tokens, output_tokens
3. Calculate cost: `cost = (input_tokens × input_price) + (output_tokens × output_price)`
4. Log to SQLite with run_id for per-pipeline aggregation

This gives you real per-run costs that update automatically when pricing changes.

## Limitations

These tools track list pricing — they don't account for:
- Volume discounts (available at high usage tiers)
- Caching discounts (Anthropic charges less for cache hits)
- Batch API pricing (significantly cheaper for non-latency-sensitive work)

Real cost can be meaningfully lower than list pricing at scale. Track both list price and actual invoice to calibrate.

## Related

- [[concepts/pipeline-cost-per-run|Pipeline Cost Per Run]] — the tracking pattern these tools support
- [[concepts/subscription-token-account-risk|Subscription Token Account Risk]] — why you need API keys (with metered pricing) rather than subscription tokens
