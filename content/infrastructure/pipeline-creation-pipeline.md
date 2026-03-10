---
title: Pipeline Creation Pipeline
tags: [infrastructure, pipelines, patterns]
---

# Pipeline Creation Pipeline

Every repeatable process deserves the same treatment: a script with observability, an Obsidian design doc, a Mission Control entry, and optionally a public design pattern page. Without a structured intake flow, pipelines accumulate as invisible infrastructure — things that run but can't be monitored, explained, or reproduced.

The Pipeline Creation Pipeline is the fix. When a new pipeline is needed, it runs through a structured checklist and produces all standard artifacts automatically.

---

## Why This Exists

An ad-hoc pipeline is:
- A script nobody can find
- A cron job nobody knows is running
- A failure mode nobody documented
- A pattern nobody can repeat

Structured intake ensures every pipeline is born with the same skeleton regardless of what it does.

---

## Standard Pipeline Artifacts

Every pipeline produces six things before it's considered real:

**1. Script file** — with a `callAnthropic()` integration for any LLM calls (never `openclaw agent` CLI), a `--force` flag for testing, and failure logging to `/api/agent-failures`.

**2. Cron-logger wrapper** — the last block of every script. Integrates with Mission Control's cron observability system so runs are tracked, durations logged, and overdue jobs flagged.

**3. Obsidian design doc** — captures trigger, inputs, outputs, failure modes, and design decisions. Lives in `Notes/Pipelines/`.

**4. Mission Control registration** — a `pipelines.json` entry with pipeline ID, description, trigger type, and current status. Shows up in the MC pipeline map.

**5. Crontab entry** — if the pipeline is scheduled, it gets a crontab line. Manual pipelines get a documented trigger path instead.

**6. Website page** (optional) — if the pipeline implements a reusable design pattern, it gets a public page here.

---

## Standard Pipeline Structure

```javascript
async function main() {
  // Pipeline logic here
  // - callAnthropic() for LLM calls
  // - POST /api/notify for results (tier: critical/high/medium)
  // - POST /api/agent-failures on error
}

// Always the last block — cron observability
try {
  const { shouldRun, logStart, logEnd } = require(
    '/home/monolith/Projects/mission-control/scripts/cron-logger'
  );
  if (!process.argv.includes('--force') && !shouldRun('<name>', <interval_min>)) {
    console.log('[<name>] Skipping — ran recently');
    process.exit(0);
  }
  const runId = logStart('<name>');
  main()
    .then(() => logEnd(runId, 'done', 'complete'))
    .catch(e => { logEnd(runId, 'failed', e.message.slice(0, 200)); process.exit(1); });
} catch (_) {
  main().catch(console.error);
}
```

---

## The Intake Checklist

Before building a pipeline, answer these:

1. **What does it do?** One sentence. If you need more, it's two pipelines.
2. **What triggers it?** Cron schedule, manual command, or event from another pipeline?
3. **What are the inputs?** Files, API responses, queue items?
4. **What are the outputs?** Files written, notifications sent, queue items created?
5. **What are the failure modes?** What breaks, how often, and what should happen?
6. **What does Mission Control show?** Last run time, status, output summary?
7. **Does it need a public page?** Only if the design pattern is reusable and worth documenting.

---

## Related

- [[infrastructure/cron-infrastructure|Cron Infrastructure]]
- [[infrastructure/notification-batching|Notification Batching]]
- [[infrastructure/llm-cost-tracking|LLM Cost Tracking]]
