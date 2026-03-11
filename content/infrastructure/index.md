---
title: Infrastructure
description: Patterns that keep autonomous systems reliable
---

Autonomous systems fail in predictable ways: they spam you with notifications, run the same job twice, spend money you can't see, and make decisions nobody reviewed. These patterns fix the common ones.

All of these are based on Matthew Berman's production system — specifically the infrastructure prompts from his "5 Billion Tokens Perfecting OpenClaw" series.

## Patterns

- **[[infrastructure/notification-batching|Notification Batching]]** — three-tier queue that batches low-urgency alerts and delivers critical ones immediately. Stops your agent from pinging you every time a cron finishes.
- **[[infrastructure/cron-infrastructure|Cron Infrastructure]]** — central SQLite log for all scheduled jobs. Idempotency checks, stale detection, failure alerting. Replaces "I think it ran?" with actual visibility.
- **[[infrastructure/llm-cost-tracking|LLM Cost Tracking]]** — per-call logging of token counts and costs. Without this, API spend is invisible. With it, you can evaluate whether any given workflow justifies its cost.
- **[[infrastructure/ai-advisory-board|AI Advisory Board]]** — multi-expert agent team that evaluates proposals before you commit to them. Five expert personas run in parallel; a synthesis agent produces a ranked recommendation.
