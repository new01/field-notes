---
title: The Heartbeat System
description: How OpenClaw's periodic heartbeat enables autonomous proactive work — and how to configure it correctly
tags: [concepts, heartbeat, autonomy, cron, openclaw]
---

# The Heartbeat System

The heartbeat is OpenClaw's mechanism for giving an agent a pulse — a periodic wake-up that doesn't require human input. Without it, the agent is reactive: it only does things when you message it. With it, the agent does useful work between conversations.

> [!tip] Highest-leverage setup step
> Getting the heartbeat right is one of the highest-leverage things you can do in your OpenClaw setup. A well-configured heartbeat turns a reactive tool into an autonomous collaborator.

## What a Heartbeat Is

At its core: a scheduled message sent to the agent on a configurable interval. OpenClaw delivers this message to the main session just like any other message. The agent reads it, executes the heartbeat instructions defined in `HEARTBEAT.md`, and responds.

Configuration lives in `openclaw.json`:

```json
{
  "heartbeat": {
    "enabled": true,
    "intervalMinutes": 30,
    "message": "Read HEARTBEAT.md if it exists. Follow it strictly. If nothing needs attention, reply HEARTBEAT_OK."
  }
}
```

> [!note] Default interval
> 30 minutes is a reasonable default — frequent enough to catch issues promptly, infrequent enough to not burn context budget on useless cycles.

### Multiple Heartbeats

You can configure different heartbeats at different intervals for different purposes. A 30-minute operations check pairs well with a separate hourly dispatch cycle:

```json
{
  "heartbeats": [
    {
      "name": "ops",
      "intervalMinutes": 30,
      "message": "Run ops checks from HEARTBEAT.md. Reply HEARTBEAT_OK if nothing needs attention."
    },
    {
      "name": "build-dispatch", 
      "intervalMinutes": 60,
      "message": "Check build queue. If Swifty inactive >30min and items are queued, dispatch the next item."
    }
  ]
}
```

---

## Phase 1: Operations

Phase 1 heartbeat is pure housekeeping. It runs inline — no subagents, no spawning, no heavy work. Just checks.

> [!important] The inline-only rule
> Phase 1 must not spawn subagents. Phase 1 is the health check — if it spawns agents, it creates recursive load and confuses the monitoring picture. All Phase 1 work must complete in a single turn.

### What belongs in Phase 1

- **Proof-of-life timestamp** — first thing, before anything else. Write the current timestamp to `/tmp/agent-alive.ts`. This is what the dead-man's switch watchdog monitors.
- **Health checks** — is Mission Control running? Are cron daemons alive? Is disk space okay?
- **Failure detection** — scan the cron log directory for recent errors. Anything fail in the last hour?
- **Stale task detection** — any build queue items stuck in "in-progress" for more than 2 hours?
- **Memory maintenance** — if yesterday's memory file is unwritten, write a brief summary now

#### Example Phase 1 HEARTBEAT.md block

```markdown
## Phase 1: Ops (every heartbeat, inline only)

1. Write proof-of-life: echo $(date +%s%3N) > /tmp/monoclaw-alive.ts
2. Check disk: df -h / | tail -1 — if >90% full, DM immediately
3. Scan logs/cron/ for files modified in last 60min containing "failed" or "error"
4. Check build-queue.json for in-progress items older than 2 hours
5. If any alerts: DM. If all clear: reply HEARTBEAT_OK.
```

---

## Phase 2: Proactive Work

Phase 2 is where autonomous work happens. The agent picks up items from the build queue, runs ingestion pipelines, generates content — whatever proactive work is defined as appropriate.

> [!warning] Always check idle state first
> Phase 2 should only fire when the human is inactive. Dispatching background tasks while someone is actively chatting competes for resources and interrupts the conversation.

### The idle detection pattern

```markdown
## Phase 2: Proactive Work (when Swifty inactive >30min)

1. Check last message time from Swifty in Discord
2. If last message < 30min ago: skip Phase 2, reply HEARTBEAT_OK
3. If last message > 30min ago:
   a. Read build-queue.json
   b. Find highest-priority "queued" item
   c. Write builds/<id>/spec.md with full task spec
   d. Spawn Claude Code session: "Execute spec at builds/<id>/spec.md"
   e. Update item status to "in-progress"
```

### What Phase 2 can do

- Dispatch queued build tasks to Claude Code sessions
- Run ingestion scripts (HN fetch, RSS pull, YouTube transcript)
- Update Obsidian knowledge base with new findings
- Run the Innovation Scout (scan for improvement opportunities)
- Update MEMORY.md with lessons from recent sessions
- Generate tweet drafts from ingested content

### What Phase 2 should never do

> [!danger] Phase 2 anti-patterns
> - **DM for debug output** — log it, notify only on actionable decisions
> - **Run multiple heavy agents simultaneously** — one dispatch per heartbeat cycle
> - **Do inline work that takes >5 minutes** — everything heavy goes to a spawned session

---

## Heartbeat vs Cron

### Use heartbeat when

- Multiple checks can batch together in one turn
- Timing can drift slightly (30-minute intervals, not "at exactly 7:00 AM")
- You want idle detection context (is the human active right now?)
- You want to reduce API calls by combining periodic checks

### Use cron when

- Exact timing matters ("9:00 AM sharp every weekday")
- The task needs isolation from the main session
- The task is self-contained with direct delivery (morning brief → Telegram)
- You want the work to happen whether or not the main session is open

> [!tip] The practical heuristic
> Batch similar periodic checks into `HEARTBEAT.md`. Use cron for precise schedules and standalone pipelines.

See [[infrastructure/cron-infrastructure|Cron Infrastructure]] for cron patterns.

---

## The Proof-of-Life Timestamp Pattern

The first action of every Phase 1 heartbeat should be writing a timestamp. This is the foundation of the [[concepts/dead-mans-switch|Dead-Man's Switch]] monitoring pattern.

```bash
echo $(date +%s%3N) > /tmp/monoclaw-alive.ts
```

An external watchdog checks this file every 60 seconds. If it's more than 90 minutes old (the heartbeat interval + buffer), the watchdog fires a notification: the heartbeat has stopped.

> [!note] Why first?
> Write the timestamp as the very first action — before any tool calls, before any checks. If the heartbeat fires but fails halfway through, you still want the timestamp written. It means "I started" not "I finished." The absence of a recent timestamp means the heartbeat never fired at all.

---

## Configuration Patterns

### Minimal setup (getting started)

```json
{
  "heartbeat": {
    "enabled": true,
    "intervalMinutes": 60,
    "message": "Read HEARTBEAT.md. Reply HEARTBEAT_OK if nothing needs attention."
  }
}
```

### Production setup

```json
{
  "heartbeats": [
    { "name": "ops", "intervalMinutes": 30,
      "prompt": "Phase 1 ops check. Write alive timestamp. Check disk. Scan for cron failures. DM if alerts, else HEARTBEAT_OK." },
    { "name": "dispatch", "intervalMinutes": 60, 
      "prompt": "Phase 2 dispatch check. If idle >30min, dispatch next build queue item via Claude Code." }
  ]
}
```

---

## Common Mistakes

> [!caution] These will hurt you
> 
> **Doing long work inline.** The heartbeat fires in the main session. Heavy work goes to dispatched sessions — not inline turns.
>
> **Pinging for debug output.** Log it. Notify only on actionable events. Nobody wants a 50-line log dump in their DMs.
>
> **Missing proof-of-life write.** Without the timestamp, the dead-man's switch can't work. Non-negotiable.
>
> **No idle check before Phase 2.** Spawning background tasks during an active conversation competes for resources.

---

## Related

- [[concepts/dead-mans-switch|Dead-Man's Switch]] — the watchdog pattern that monitors heartbeat health
- [[infrastructure/cron-infrastructure|Cron Infrastructure]] — cron-based scheduling as a complement to heartbeat
- [[concepts/build-queue-pattern|Build Queue Pattern]] — how Phase 2 dispatch connects to the work queue
