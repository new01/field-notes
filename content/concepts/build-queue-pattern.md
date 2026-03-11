---
title: The Build Queue Pattern
description: How to give an agent a backlog of real work it can pick up autonomously — and why it must be a collaborative tracker, not an autonomous executor
tags: [concepts, build-queue, autonomy, orchestration, task-management]
---

# The Build Queue Pattern

A build queue gives an agent a backlog of real work to pull from. Without one, the agent does only what you ask it in the current conversation — reactive, context-limited, and dependent on you to remember what needs to be done. With a queue, work persists across sessions, gets prioritized, tracked, and picked up when conditions allow.

The queue pattern sounds simple. In practice, it's the lesson that took longest to learn correctly.

## Why Agents Need a Queue

### Context loss

Sessions end. Context doesn't persist automatically. If you discuss "we should refactor the tweet pipeline" in session 12, by session 20 that conversation is gone — unless it was written somewhere.

A queue is that "somewhere." It's the persistent record of work that's been identified, scoped, and approved but not yet done.

### Prioritization

Without a queue, the agent works on whatever you mentioned most recently. That's not always the most important thing. A queue with explicit priority fields lets you set direction once and trust the agent to respect it.

### Tracking and verification

How do you know if a task was actually done? "The agent said it was done" is not a reliable answer. A queue with status transitions and artifact paths gives you something to verify against: does the file exist? Did the status.json get written?

### Handoff between sessions

The queue is a coordination primitive. It lets you hand off work between: your current session and the next one, the main session and a spawned ACP session, now-you and tomorrow-you who doesn't remember what was planned.

---

## The Queue as Collaborative Tracker

Here's the critical insight — the one that took weeks to learn:

**The build queue is a todo list for sessions with you present, not an autonomous execution queue.**

The temptation is to wire the heartbeat to pick up queue items and dispatch them autonomously. This feels like leverage. In practice, it produces fake completions.

Language models in isolation generate convincing descriptions of work. They don't reliably *do* work. A subagent dispatched with a task title and no oversight will mark items done without creating the artifacts. Gate-check scripts don't fix this — the same agent controls both the exam and the grading.

The enforcement mechanism for quality is a human watching. Every tool call in a live session is visible. Mistakes get caught in 30 seconds. That feedback loop is what produces real output.

### The right operating model

```
You open a session
    ↓
"What's next in the queue?"
    ↓
Agent reads queue, picks top item, writes task spec
    ↓
Spawn fresh ACP session with spec + relevant file paths
    ↓
Main session stays unblocked — you can keep talking
    ↓
ACP announces completion
    ↓
Agent verifies artifacts exist on disk
    ↓
Mark done, pick next item
```

The queue advances when you're present, not autonomously. The async idle-dispatch pattern (Phase 2 heartbeat) works for well-defined, verifiable tasks — but even then, the main session verifies before marking done.

---

## What a Good Queue Item Contains

A queue item that's too thin produces ambiguous work. One that's too detailed takes longer to write than the work itself. The right balance:

```json
{
  "id": "pipeline-audit-001",
  "title": "Audit tweet pipeline error handling",
  "priority": 1,
  "status": "queued",
  "spec": "The tweet pipeline fails silently when the humanizer returns a score >0.8. Add: (1) explicit error on score threshold, (2) DM notification with the problematic content, (3) log to logs/pipeline-errors/. Files: scripts/tweet-pipeline.js, scripts/humanize.js",
  "requiredArtifacts": [
    "scripts/tweet-pipeline.js (modified)",
    "logs/pipeline-errors/ (directory created)"
  ],
  "createdAt": "2026-03-10T14:00:00Z",
  "completedAt": null,
  "buildDir": null
}
```

### Required fields

**`id`** — stable identifier. Used for log file names, build directories, status tracking.

**`title`** — human-readable. One sentence. Used in DM notifications and queue displays.

**`priority`** — integer, lower = higher priority. The agent picks the lowest number in "queued" status.

**`status`** — one of: `queued`, `in-progress`, `done`, `failed`, `blocked`

**`spec`** — the actual task description. Must include: what to change, which files, what success looks like. If the spec is vague, the output will be too.

**`requiredArtifacts`** — explicit list of what must exist when done. Used for gate checking.

---

## Gate Checking

Gate checking is the mechanism for verifying work was actually done, not just claimed as done.

### The pattern

When an ACP session announces completion:

1. Read `builds/<id>/status.json`
2. Check that `artifacts[]` is non-empty
3. Verify each artifact path exists on disk: `fs.existsSync(path)`
4. If all checks pass: mark done, DM summary
5. If any check fails: reset to "queued", DM warning with what was missing

```javascript
// Gate check implementation
async function verifyCompletion(id, item) {
  const statusPath = path.join('builds', id, 'status.json');
  
  if (!fs.existsSync(statusPath)) {
    return { passed: false, reason: 'status.json not found' };
  }
  
  const status = JSON.parse(fs.readFileSync(statusPath, 'utf8'));
  
  if (!status.artifacts || status.artifacts.length === 0) {
    return { passed: false, reason: 'status.json has empty artifacts array' };
  }
  
  const missing = status.artifacts.filter(p => !fs.existsSync(p));
  if (missing.length > 0) {
    return { passed: false, reason: `Missing artifacts: ${missing.join(', ')}` };
  }
  
  // Cross-check against requiredArtifacts in queue item
  const requiredMissing = (item.requiredArtifacts || [])
    .filter(r => !status.artifacts.some(a => a.includes(r.split(' ')[0])));
  
  if (requiredMissing.length > 0) {
    return { passed: false, reason: `Required artifacts not in status.json: ${requiredMissing.join(', ')}` };
  }
  
  return { passed: true };
}
```

### What the gate doesn't check

The gate verifies artifacts exist. It doesn't verify they're correct. A file named `scripts/tweet-pipeline.js` that's empty passes the gate. This is why human spot-checking matters even when gates pass.

For critical work, add a smoke test to the required artifacts: a test script that exercises the thing that was built.

---

## Integration with Mission Control

[[infrastructure/mission-control|Mission Control]] is the dashboard that makes the queue visible. Key features:

- **Real-time queue view** — in-progress, queued, done, stuck
- **Stuck detection** — items in-progress for more than 2 hours get flagged automatically
- **Artifact links** — click through to the build directory and read status.json directly
- **Failure log** — failed items with the reason they failed

The queue is most useful when it's visible. A JSON file in your workspace works but requires CLI tools to check. Mission Control makes the queue a first-class operational view you can check at a glance.

---

## The Idle-Dispatch Pattern

For genuinely well-defined tasks, the heartbeat can dispatch them during idle time. This works when:

1. The task spec is complete and unambiguous
2. The required artifacts are explicitly defined
3. You're confident enough in the gate check to trust the outcome with async review

The pattern:

```markdown
## Heartbeat Phase 2 — Idle Dispatch

1. Check Discord: last message from Swifty > 30min ago?
2. If yes: read build-queue.json, pick highest priority "queued" item
3. Write builds/<id>/spec.md with full task details
4. Spawn: `openclaw agent --message "Execute spec at builds/<id>/spec.md"`
5. Update status to "in-progress", record timestamp
6. On completion: verify gate, DM summary, mark done or reset
```

Don't use this pattern for tasks that require judgment calls mid-execution. Save it for tasks where the spec is detailed enough that success is unambiguous.

---

## Related

- [[infrastructure/graph-orchestration|Graph Orchestration]] — the execution model for multi-step builds
- [[concepts/heartbeat-system|Heartbeat System]] — how Phase 2 idle dispatch connects to the queue
- [[infrastructure/mission-control|Mission Control]] — the dashboard that makes the queue visible and operational
