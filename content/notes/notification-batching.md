---
title: "Notification Batching"
tags: [concept, infrastructure, notifications, openclaw]
---

# Notification Batching

A three-tier queuing system for all outbound agent notifications that eliminates alert spam.

**Critical** — deliver immediately. Errors, interactive prompts requiring human input, anything time-sensitive.

**High** — batch hourly. Job failures, important status updates, things that matter but can wait an hour.

**Medium** — batch every 3 hours. Routine scan results, completion confirmations, FYI-level updates.

All messages route through a central queue by default. Nothing bypasses the queue.

---

## The Problem It Solves

Without batching, every event generates a notification. A single agent run might fire a dozen. Multiply that by cron jobs running every 15 minutes and you have a notification stream that's impossible to parse — so you start ignoring it, which defeats the purpose entirely.

The fix isn't fewer agents or fewer events. It's smarter delivery. Group by urgency, batch by time window, send at predictable intervals.

---

## How Tiers Work

The tier is set at the time of message generation, not delivery. The agent decides urgency when it creates the notification:

```
queue_notification(
  message="Scan complete: 3 results found",
  tier="medium"  # routine, no action needed
)

queue_notification(
  message="Auth error on API call — manual review needed",
  tier="critical"  # requires immediate attention
)
```

The queue handles the rest. Critical messages go out immediately. Medium messages sit until the next 3-hour batch window.

---

## Implementation

The queue can be as simple as a SQLite table with columns for message, tier, created_at, and delivered_at. A small scheduler process checks the table on interval and fires batched messages to the configured channel (Telegram, Discord, email, whatever).

The important constraint: every outbound notification must go through the queue. No direct sends. If a direct send is hardcoded somewhere, it will eventually cause spam.

---

## Related

- [[agent-teams|Agent Teams]]
- [[brains-and-muscles|Brains and Muscles]]
