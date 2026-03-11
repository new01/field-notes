---
title: Overload-Tolerant Event Ledger
description: A SQLite-based system event log that makes silence visible — so a delta checker can find what should have happened but didn't
tags: [concepts, infrastructure, observability, sqlite, openclaw]
---

# Overload-Tolerant Event Ledger

A SQLite-based system event log that records every expected action — cron starts and ends, notification attempts, overload events, agent failures — so a delta checker can compare what *should* have happened against what *did* happen on every heartbeat.

## The Problem It Solves

### Why silence is dangerous

Without a ledger, overloads are invisible. A cron fires, the agent call hangs, nothing is logged, nothing is retried. The next heartbeat has no idea what was missed.

#### The classic failure mode
Job fires at 2am. API overloads. Agent call hangs until timeout. Cron exits with error. No log entry written (agent wasn't running). Next heartbeat sees normal state. 6 hours of missed work, no trace.

### Making silence visible

The ledger inverts this. Every job registers with an expected interval when it starts. If its `last_ok_ts` hasn't updated within `interval * 1.5`, the delta checker flags it as a missed job — even if no error was ever written.

Silence becomes a signal.

## Architecture

### Tables

```sql
events          — raw log of everything (type, job_name, status, detail, duration_ms)
cron_registry   — all known jobs with expected intervals + last_ok_ts
dm_log          — every outbound notification with delivery status (pending/sent/failed)
overload_state  — singleton row: current overload flag + cooldown + reason
```

### Key scripts

```
scripts/event-logger.js   — synchronous, never-throw logging functions
scripts/delta-checker.js  — computes missed jobs + failed DMs on demand
scripts/watchdog.js       — reads/writes overload_state, sends notifications
```

### event-logger.js interface

```js
logCronStart(jobName)          // → runId
logCronEnd(runId, status)      // closes the run
logDmSent(target, preview)     // → dmId
logDmFailed(dmId, reason)      // marks delivery failure
logOverload(context, detail)   // sets overload_state
logRecovery(context)           // clears overload_state
getOverloadState()             // current singleton
shouldRun(jobName, intervalMs) // idempotency guard
```

The functions are synchronous and never throw. The goal is that a logging failure never breaks the job being logged.

## Delta Check

### Runs every heartbeat

```js
// For each job in cron_registry:
// if last_ok_ts older than interval_ms * 1.5 → missed job

// For dm_log:
// status='failed' AND retry_count < 3 → recoverable notification

// For overload_state:
// if cooldown_until in the past → clear overload flag
```

Returns: `{ missedJobs, failedDms, overloadState, summary }`

The heartbeat uses this output to decide what to retry and what to surface to the operator.

## Overload Detection Sources

### Two independent paths

Overload state is set by two independent paths:

**External watchdog** — detects stale alive file or multiple cron error files. Doesn't go through the agent at all.

**Cron wrapper** — catches exit codes and error strings from agent calls, writes per-job error files. Detection strings: `overloaded`, `529`, `rate_limit`, `quota`, `ETIMEDOUT`, `context_limit`.

Two independent paths means a single point of failure in detection is eliminated.

## Notification Retry Logic

Every outbound notification goes through `logDmSent()` → gets a `dmId`. On failure, `logDmFailed()` is called. The heartbeat reads `dm_log` and retries up to 3 times. The operator is notified only if the same message fails all 3 attempts.

## API Endpoints

```
GET /api/system-events    — last 50 events
GET /api/delta-check      — run delta check, return report
GET /api/overload-state   — current overload singleton
```

## Why SQLite

### The zero-dependency rationale

No daemon, no network, no credentials. The entire ledger is a single file. Queries are synchronous. The event logger can be imported and called from any script in the stack without setup.

#### What this means in practice
If Postgres goes down, your monitoring goes down with it. SQLite is the same binary as your Node process — if your app can run, your logging can run.

## Related

- [[infrastructure/cron-infrastructure|Cron Infrastructure]] — jobs call logCronStart/logCronEnd
- [[concepts/dead-mans-switch|Dead-Man's Switch]] — writes to overload_state
- [[infrastructure/notification-batching|Notification Batching]] — notification log integrates with the delivery queue
- [[infrastructure/mission-control|Mission Control]] — reads /api/system-events and /api/delta-check to display ledger state
