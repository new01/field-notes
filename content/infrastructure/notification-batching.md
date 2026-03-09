---
title: Notification Batching
description: Three-tier queue that eliminates notification spam from autonomous agents
tags: [infrastructure, notifications, sqlite, openclaw]
---

Every cron job completion, scan result, and status update becomes a ping if you don't batch them. A three-tier notification queue fixes this: urgent things arrive immediately, everything else batches on a schedule.

## The three tiers

| Tier | When to use | Delivery |
|------|-------------|----------|
| Critical | Errors, interactive prompts, things needing immediate action | Immediately |
| High | Job failures, important findings, things to review today | Hourly batch |
| Medium | Routine scan results, status updates, completed tasks | Every 3 hours |

All messages route through the queue by default. Nothing bypasses it. The tier is declared when the message is generated, not at delivery time.

## SQLite schema

```sql
CREATE TABLE notifications (
  id TEXT PRIMARY KEY,
  created_at TEXT,
  tier TEXT CHECK(tier IN ('critical','high','medium')),
  target TEXT,
  message TEXT,
  delivered INTEGER DEFAULT 0,
  delivered_at TEXT,
  message_hash TEXT  -- dedup: skip if same hash delivered in last 6h
);
```

## Implementation notes

The batch dispatcher runs as a `setInterval` inside your server process — no separate process needed. Dedup by SHA256 of message content prevents the same alert from firing repeatedly during a sustained failure.

Tier assignment guide for OpenClaw: errors and interactive prompts = Critical; agent failures and important findings = High; cron completions and routine scan results = Medium.

## Related

- [[infrastructure/cron-infrastructure|Cron Infrastructure]] — the cron logging system that triggers these notifications
- [[infrastructure/llm-cost-tracking|LLM Cost Tracking]] — cost spikes are a Critical notification

## Sources

Matthew Berman ("5 Billion Tokens Perfecting OpenClaw") — Prompt 9; "Stop spamming Telegram on every event"; all outbound messages route through queue by default.
