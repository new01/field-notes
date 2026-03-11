---
title: Dead-Man's Switch
description: A monitoring pattern where the absence of a signal is the failure condition — for systems that can't self-report their own failure
tags: [concepts, infrastructure, monitoring, observability, openclaw]
---

# Dead-Man's Switch

A monitoring pattern where **the absence of a signal is the failure condition** — rather than waiting for an explicit error report. Used when the thing you want to monitor is exactly the thing that might fail to report.

## The Problem It Solves

### Why traditional monitoring breaks for agents

An AI agent can't self-report an overload. If the API is overloaded, the agent isn't running — so any logging call never gets called. You can't ask the patient to diagnose their own unconsciousness.

#### The failure loop
Traditional monitoring: agent logs its own errors → dashboard reads log → alert fires.

This breaks completely when the agent is the failure point. If the agent stops running, the log never gets written, the dashboard shows nothing, no alert fires. The system appears healthy while doing nothing.

#### What this looks like in practice
Your heartbeat is configured to run every 30 minutes. The API goes overloaded at 2am. You wake up at 8am to 6 hours of missed tasks and no alerts. The last log entry is from 1:58am saying "everything normal."

### The solution: invert the monitoring assumption

Instead of "alert me when something goes wrong," the dead-man's switch asks: "alert me if I don't hear that everything went right."

## How It Works

### The proof-of-life file

The agent writes a Unix timestamp to a file as the **very first action of every heartbeat** — before any other work, before any API calls.

```bash
date +%s%3N > /tmp/agent-alive.ts
```

This is the "I'm alive" signal. It requires no API, no LLM, no network — just a file write.

### The external observer

A separate process (the watchdog) checks the file age every 60 seconds. It is deliberately minimal — no LLM, no API calls, just file stat and timestamp comparison.

#### The check logic
```
file_age = now - last_modified_timestamp
expected_interval = heartbeat_interval_minutes * 60 * 1000

if file_age > expected_interval + buffer:
    fire alert
```

#### The buffer
Add 30-60 minutes of buffer beyond the heartbeat interval. Occasional skips (system busy, brief API hiccup) shouldn't trigger false alerts. Sustained absence should.

### The separation of concerns

The watchdog runs as a **separate PM2 process**. If the main agent service goes down, the watchdog keeps running. If the notification API is unavailable, it falls back to a direct CLI call.

#### Why separation matters
If the observer shared infrastructure with the observed, a single failure could take out both. The watchdog must be independently survivable.

## Implementation

```
/tmp/agent-alive.ts             — proof-of-life file (Unix timestamp in ms)
scripts/watchdog.js             — check logic + DB update + notification sender
scripts/watchdog-daemon.js      — PM2 daemon wrapper (runs every 60s)
```

A cron entry restarts the watchdog every few minutes if it dies — defense in depth.

## Notification Behavior

### Alert stages

#### On detection
Immediate alert — "Heartbeat stopped. Last seen: [time]. Will ping every 10 minutes while ongoing."

#### While ongoing (every 10 minutes)
"Heartbeat still stopped. Duration: [N] minutes."

#### On recovery
"Heartbeat restored. Incident duration: [N] minutes."

### Delivery path

Notifications route through a channel that does **not** depend on the agent — direct API call from the watchdog, not through OpenClaw's notification system (which itself depends on the agent being healthy).

## Signal Combination

Multiple signals reduce false positives.

| Signal | What it detects |
|--------|----------------|
| Stale alive file (>90 min for 1h heartbeat) | Heartbeat stopped — probable API overload |
| 2+ cron error files in `/tmp/cron-errors/` | Multiple agent calls failing simultaneously |
| Both signals together | Systemic failure — high confidence |

A single stale file could be a bug. A stale file plus multiple cron errors is a systemic failure. The combination catches real incidents without crying wolf on transients.

## The Key Insight

The dead-man's switch pattern applies to **any system where the monitor and the monitored share a failure mode**.

##### Common places it applies
- Agent health monitoring (heartbeat proof-of-life)
- Background job health (cron writes timestamp, watchdog checks)
- Database connection health (writer signals to external checker)
- External service availability (poller signals absence of response)

Separate the observer. Make the absence of a signal the alarm.

## Related

- [[infrastructure/cron-infrastructure|Cron Infrastructure]] — cron wrapper scripts write error files that feed the watchdog
- [[infrastructure/notification-batching|Notification Batching]] — the delivery layer the watchdog routes through
- [[concepts/overload-tolerant-event-ledger|Overload-Tolerant Event Ledger]] — the ledger the watchdog writes overload state to
- [[concepts/heartbeat-system|Heartbeat System]] — the heartbeat that writes the proof-of-life timestamp
