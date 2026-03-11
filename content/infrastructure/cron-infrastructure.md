---
title: "Cron Job Infrastructure"
---

# Cron Job Infrastructure

Cron jobs for agents accumulate fast. An Innovation Scout runs daily. A cost summary runs hourly. A monitoring scan runs every 15 minutes. Without a central logging layer, you have no visibility into what's running, what's failing, or why something didn't produce output.

The pattern is a SQLite `cron_log` table where every job calls `log-start` before doing any work and `log-end` when done. That's the whole thing. Simple, but the absence of it means flying blind.

---

## The Schema

```sql
CREATE TABLE cron_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  job_name TEXT NOT NULL,
  run_id TEXT NOT NULL UNIQUE,   -- UUID generated at log-start
  started_at INTEGER NOT NULL,   -- unix timestamp
  ended_at INTEGER,              -- null until complete
  status TEXT,                   -- 'success' | 'failed' | 'stale'
  duration_ms INTEGER,
  summary TEXT                   -- human-readable note about what happened
);
```

Each job:
1. Calls `log-start` → receives a `run_id`
2. Does its work
3. Calls `log-end(run_id, status, summary)` when done

---

## Three Critical Features

**Idempotency check (`should-run`):**
Before starting, the job queries: has this job name already logged a start within the current window? If yes, skip. This prevents duplicate runs when jobs get triggered multiple times — system restarts, misconfigured intervals, manual triggers.

```sql
SELECT id FROM cron_log
WHERE job_name = ?
  AND started_at > ?   -- current window start
  AND status IS NOT NULL  -- completed
LIMIT 1;
```

**Stale detection:**
A cleanup job runs periodically and marks any `cron_log` row with a `started_at` more than 2 hours ago and no `ended_at` as `status = 'stale'`. Stale means: the job started but never reported completion. Usually means it crashed without error handling. Stale rows get flagged so you can investigate.

**Persistent failure detection:**
If the same job logs `status = 'failed'` three or more times within a 6-hour window, trigger an immediate alert. This catches jobs that are silently failing in a loop — the cron is running, the job is executing, but the work is broken. Without this, you can go days without noticing that a scan or review has been failing every hour.

---

## What Gets Logged

Every scheduled agent task should log. This includes:

- Automated review councils (Innovation Scout, Security Review)
- Data monitoring scans
- Cost summary generation
- Notification batch delivery
- Any script that runs on a timer

The summary field is valuable: write a one-line description of what the job found or did, not just whether it succeeded. "Scanned 47 items, 3 flagged" is more useful than "success."

---

## Connecting to Notifications

When a job fails, the cron log records it. The notification layer (see [[infrastructure/notification-batching|Notification Batching]]) handles delivery. The two systems should be loosely coupled: the cron log doesn't send notifications directly, it writes a record. A separate notification job reads failed logs and enqueues the appropriate alert.

This keeps responsibilities clean and avoids situations where a notification failure compounds a job failure.

---

## Sources

Matthew Berman ("5 Billion Tokens Perfecting OpenClaw," Prompt 7) — SQLite schema, log-start/log-end pattern, idempotency check, stale detection, persistent failure detection with alert.

---

**Related:**
- [[infrastructure/notification-batching|Notification Batching]] — what to do when a job fails
- [[concepts/self-improvement-system|Self-Improvement System]] — the review councils that this infrastructure supports
