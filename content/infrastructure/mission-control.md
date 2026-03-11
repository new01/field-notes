---
title: Mission Control
description: The operational observability dashboard for OpenClaw — real-time view of agent health, build queue, cron status, and failures
tags: [infrastructure, observability, dashboard, mission-control, monitoring]
---

# Mission Control

Mission Control is a local Node.js server that gives you a real-time operational view of everything your agent is doing. Without it, you're flying blind — checking log files manually, running status commands, wondering why something isn't working.

With it: one URL, current state of everything, built-in failure detection.

## What It Is

A lightweight Node.js HTTP server that serves a live dashboard. Runs as a PM2 process alongside your agent. Reads from the same data sources the agent writes to — build queue, cron logs, process list, disk metrics.

**Not a SaaS.** Not a cloud product. Runs on the same machine as your agent. Latency is filesystem reads. No API calls, no subscription, no data leaving your network.

Default port: `3001`. Access at `http://localhost:3001` or, if port-forwarded, from anywhere.

---

## Key Views

### System Health

The landing view. Shows at a glance:

- **CPU usage** — current system load. Agent-heavy workflows show up here.
- **Memory usage** — total and available. Important if you're running local Whisper or large models.
- **Disk usage** — percentage used. Transcript ingestion and log accumulation can fill disks fast.
- **Active agent count** — how many OpenClaw sessions are currently running.
- **Gateway status** — is the main gateway process up?
- **Recent failure count** — failures in the last hour.

The health view is designed to be glanceable. Green across the board means nothing needs attention. Any red or amber means investigate.

### Build Queue

The full queue in one view:

- **In-progress** — tasks currently being executed, with start time and elapsed duration
- **Queued** — pending tasks in priority order
- **Done** — recent completions with artifact paths
- **Failed** — failed tasks with failure reason and timestamp
- **Stuck detection** — items in-progress for more than 2 hours automatically flagged

Click any item to see the full spec and status.json. The artifact paths are clickable links to the actual files on disk.

This is where you verify that completed tasks actually completed. "Done" without artifacts is a fake completion. Mission Control shows you both the status claim and the artifact evidence.

### Cron Status

Every cron job registered in the system appears here with:

- **Last run time** — when it fired
- **Last run status** — success, failed, or timed out
- **Next scheduled run** — calculated from the cron expression
- **Recent error rate** — percentage of recent runs that errored

Cron jobs that haven't fired when expected are flagged. This catches silent cron failures — where the job was removed from crontab or the script it calls stopped working.

### Pipelines

Active pipeline runs — tweet pipeline, morning brief, ingestion jobs. Shows:

- Pipeline name
- Current phase
- Start time and elapsed duration
- The artifact file for this run (click to inspect)

Stuck pipelines (running longer than expected) are highlighted.

### Agent Fleet

All PM2 processes associated with OpenClaw:

- Gateway daemon
- Mission Control itself
- Watchdog/dead-man's switch
- Any persistent cron daemons

Status for each: running, stopped, errored, or restarting. You can restart individual processes from this view.

### Agent Failures

The failure log — failures from the last 24 hours with context:

- **What failed** — which agent session, which task
- **Failure mode** — timeout, error, fake completion, API rate limit
- **Time** — when it happened
- **Recovery action** — whether it auto-recovered or requires manual intervention

---

## Health Metrics in Depth

### Active Agent Count

More than 3 concurrent agents typically signals something wrong — a heartbeat loop spawning unexpectedly, a stuck pipeline retry loop, or a build dispatch that fired multiple times. Mission Control shows this in real-time so you can catch runaway agent creation early.

### Disk Usage

Two things consume disk fast: transcript files from YouTube ingestion (a 60-min video transcript is 50-100KB), and cron logs (one file per run, accumulating daily). Mission Control shows current disk usage. Set an alert threshold — 80% is a reasonable warning, 90% is critical.

### Recent Failure Count

This is the single most important metric after "is the gateway running." One failure in an hour might be noise. Five failures in an hour means something is systematically broken.

---

## Reading the Build Queue

### Identifying Stuck Tasks

An item in "in-progress" for more than 2 hours hasn't made progress. This usually means:
- The ACP session that was dispatched crashed or timed out
- The session completed but never wrote status.json
- A gate check hung waiting for a file that was never created

**Recovery:** Reset the item to "queued" manually. Read whatever is in `builds/<id>/` to understand where it stopped. Re-dispatch with a more detailed spec that handles the edge case that caused the failure.

### Fake Completions

Status "done" but artifact paths are empty or the files don't exist. This is the failure mode the gate check is supposed to catch. When you see it in Mission Control:

1. Read `builds/<id>/status.json` — what does it claim?
2. Run `ls builds/<id>/` — what actually exists?
3. Reset to "queued" with a note about what was missing
4. Update the spec to be more explicit about required artifacts

### Cascade Failures

Multiple items failing in sequence usually means a shared dependency is broken. Check: is the script all these tasks call still valid? Has a path changed? Did a dependency get updated and break the interface?

---

## Agent Failures: What They Mean

### Timeout

The agent session ran longer than the configured timeout and was killed. Usually means: the task was too large for the context budget, or the agent hit an infinite loop pattern. Fix: break the task into smaller pieces, or increase the timeout with a corresponding gate check at the midpoint.

### API Rate Limit

Too many concurrent requests to the LLM provider. Mission Control shows the failure but you may need to check your provider's usage dashboard to see the full picture. Fix: reduce concurrency, add delays between pipeline stages, upgrade your API tier.

### Fake Completion

The session ended successfully (no error) but artifacts are missing. The most common and most insidious failure mode. Fix: gate checking, explicit artifact requirements in spec, human spot-check for high-value tasks.

### Context Overflow

The session accumulated too much context and produced degraded output or stopped working. Fix: spawn sessions with minimal context — just the task spec and relevant file paths, not the full conversation history.

---

## The Doctor Report

Mission Control can run an automated health diagnosis on a schedule. The doctor report:

1. Checks all registered cron jobs — is each one firing as expected?
2. Scans failure logs — are there patterns (same failure type recurring, same pipeline always failing)?
3. Checks resource trends — is disk usage growing faster than expected?
4. Verifies the dead-man's switch watchdog is running
5. Generates a plain-language summary of findings

Run manually:

```bash
curl http://localhost:3001/api/doctor
```

Or schedule it — the report can DM you weekly with a health summary. Useful for catching slow-burn issues before they become crises.

---

## Setting It Up from Scratch

### Step 1: Clone or create the server

Mission Control is a standalone Node.js script. Create `mission-control/server.js` in your workspace.

The server needs to read from:
- `build-queue.json` (or your queue storage)
- `logs/cron/` directory
- PM2 process list (`pm2 jlist` JSON output)
- System metrics (`os.cpus()`, `os.freemem()`, `os.totalmem()`, `os.loadavg()`)

### Step 2: Register as a PM2 process

```bash
pm2 start mission-control/server.js --name "mission-control" --watch false
pm2 save
```

### Step 3: Configure port and paths

In `mission-control/config.json`:

```json
{
  "port": 3001,
  "queuePath": "../build-queue.json",
  "logDir": "../logs/cron",
  "stuckThresholdMinutes": 120,
  "refreshIntervalSeconds": 30
}
```

### Step 4: Verify it's running

```bash
curl http://localhost:3001/api/health
pm2 status mission-control
```

---

## The Dead-Man's Switch Watchdog Pattern

Mission Control and the dead-man's switch watchdog are complementary. Mission Control shows you the state of things you can see. The dead-man's switch alerts you when the thing doing the monitoring has itself gone silent.

The pattern: your agent writes `/tmp/agent-alive.ts` every heartbeat. The watchdog — a separate PM2 process independent of the agent — checks that file every 60 seconds. If it's more than 90 minutes old, the watchdog sends a direct notification bypassing the agent entirely.

Mission Control displays the watchdog's status: when it last checked the timestamp, what the timestamp says, and whether the watchdog itself is running. If Mission Control shows "watchdog not running" — that's the thing to fix first.

See [[concepts/dead-mans-switch|Dead-Man's Switch]] for the full implementation.

---

## Related

- [[concepts/build-queue-pattern|Build Queue Pattern]] — the queue Mission Control visualizes and monitors
- [[infrastructure/cron-infrastructure|Cron Infrastructure]] — cron job registration and the logs Mission Control reads
- [[concepts/dead-mans-switch|Dead-Man's Switch]] — the watchdog pattern that operates alongside Mission Control
