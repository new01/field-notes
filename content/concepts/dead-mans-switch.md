---
title: Dead-Man's Switch
description: A monitoring pattern where the absence of a signal is the failure condition — for systems that can't self-report their own failure
tags: [concepts, infrastructure, monitoring, observability, openclaw]
---

A monitoring pattern where the **absence of a signal** is the failure condition — rather than waiting for an explicit error report. Used when the thing you want to monitor is exactly the thing that might fail to report.

## The problem it solves

An AI agent can't self-report an overload. If the API is overloaded, the agent isn't running — so any logging call never gets called. You can't ask the patient to diagnose their own unconsciousness.

Traditional monitoring (agent logs its own errors → dashboard reads log) breaks completely when the agent is the failure point.

## How it works

1. **The agent writes a proof-of-life timestamp** to a file on every successful heartbeat — first action, before anything else
2. **An external observer** (separate process, separate daemon) checks the file age every 60 seconds
3. If the file is older than the expected heartbeat interval plus buffer (e.g., 90 minutes for a 1h heartbeat), the observer flags a failure
4. The observer sends notifications directly — bypassing the agent entirely

The key: the observer is **not subject to the same failure mode** as the thing it monitors. It's a lightweight process — no API calls, no LLM context.

## Implementation

```
/tmp/agent-alive.ts             — proof-of-life file (Unix timestamp in ms)
scripts/watchdog.js             — check logic + DB update + notification sender
scripts/watchdog-daemon.js      — PM2 daemon wrapper (runs every 60s)
```

**The watchdog runs as a separate PM2 process.** If your main service goes down, the watchdog keeps running. If your notification API is unavailable, it falls back to a CLI call directly.

A cron restarts the watchdog every few minutes if it dies.

## Notification behavior

- **On detection**: immediate alert — overload detected, reason, will ping every 10 minutes
- **Every 10 minutes while ongoing**: overload ongoing, duration
- **On recovery**: cleared, duration of the incident

## Signal combination

| Signal | What it detects |
|--------|----------------|
| Stale alive file (>90 min) | Heartbeat stopped — probable API overload |
| 2+ cron error files | Multiple agent calls failing simultaneously |

Single-signal could be a bug. Multi-signal is a systemic failure. The combination reduces false positives.

## The key insight

The dead-man's switch pattern applies to any system where the monitor and the monitored share a failure mode. Separate the observer. Make the absence of a signal the alarm.

This inverts the usual assumption of monitoring: instead of "alert me when something goes wrong," it becomes "alert me if I don't hear that everything went right."

## Related

- [[Cron Job Infrastructure]] — cron wrapper scripts write error files that feed the watchdog
- [[Notification Batching]] — the delivery layer the watchdog routes through
- [[Overload-Tolerant Event Ledger]] — the ledger the watchdog writes overload state to
