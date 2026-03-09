---
title: Cron Job Infrastructure
description: Centralized logging, idempotency guards, and failure detection for all scheduled agent tasks
tags: [concepts, infrastructure, cron, sqlite, openclaw]
---

Every autonomous system eventually runs scheduled jobs — scanners, digests, queue processors, report generators. Without a shared logging layer, you have no idea what ran, what failed, or why. Cron job infrastructure solves this with a simple pattern: every job calls `log-start` before doing any work and `log-end` when done.

## The core pattern

```js
const { shouldRun, logStart, logEnd } = require('./cron-logger');

// Skip if the job ran successfully in the last 25 minutes
if (!shouldRun('my-job', 25)) process.exit(0);

const runId = logStart('my-job');
try {
  // ... do the work ...
  logEnd(runId, 'done', 'Processed 12 items');
} catch (e) {
  logEnd(runId, 'failed', e.message);
  throw e;
}
```

That's the whole interface. `logStart` writes a `running` entry to SQLite and returns a run ID. `logEnd` closes it with status, duration, and a summary string. `shouldRun` checks whether the same job completed successfully within a time window — the idempotency guard.

## Why SQLite

A flat log file works until it doesn't. SQLite gives you indexed queries over job history without any infrastructure overhead — no daemon, no network, no credentials. The schema is four columns: `job_name`, `started_at`, `status`, `output_summary`. Everything you need for a dashboard or alert query fits in a single `SELECT`.

## Idempotency guards

Cron jobs can fire twice. Systems restart at inconvenient times. A job that takes 20 minutes can overlap with its next scheduled run. The `shouldRun(name, minInterval)` check prevents this by refusing to start if the same job already completed successfully within the window. It fails open — if the database is unavailable, the job runs anyway.

## Failure detection

Three consecutive failures on the same job within six hours is a signal worth acting on. That pattern — same job, short window, repeated failures — usually means something upstream changed: an API endpoint moved, a file path broke, a dependency went down. Detecting it early means you find out before you notice the missing output.

## Dashboard visibility

Once every job writes to the same table, you get a single query for system health:

```sql
SELECT job_name, MAX(started_at) as last_run, status, output_summary
FROM cron_runs GROUP BY job_name ORDER BY last_run DESC;
```

This powers a dashboard card that shows every scheduled job, when it last ran, and whether it succeeded — without touching any log files.

## Python support

The same pattern works in Python via a context manager:

```python
from cron_logger import CronLogger

with CronLogger('media-processor', skip_if_ran_within=40) as cron:
    if cron.should_skip:
        sys.exit(0)
    process_all()
    cron.summary = 'Processed 5 items'
```

The context manager handles `log-start` on entry and `log-end` on exit, including failure cases where an exception is raised.

## What it replaces

Before this pattern: 15 cron jobs writing to separate log files, no shared visibility, silent failures discovered hours later when expected outputs didn't appear.

After: one SQLite table, one dashboard card, one query to answer "is everything running?"

## Related

- [[Self-Improvement System]]
- [[LLM Cost Tracking]]
- [[Notification Batching]]
