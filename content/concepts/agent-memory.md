---
title: Agent Memory
description: How to give your OpenClaw agent continuity across sessions
tags: [concepts, memory, openclaw]
---

An OpenClaw agent wakes up fresh every session. Without memory files, it has no idea what happened yesterday, what you prefer, or what it was working on. With them, it picks up exactly where it left off.

Memory has two tiers:

**Daily notes** (`memory/YYYY-MM-DD.md`) — raw logs of what happened each session. What was built, what broke, what decisions were made. Written at session end, read at session start.

**Long-term memory** (`MEMORY.md`) — curated distillation of what matters across sessions. Not a log — a continuously updated knowledge base. Significant decisions, preferences, lessons learned, things that shouldn't be repeated.

The agent reads these files at the start of each session to reconstruct context. The more context it has accumulated, the more proactively useful it becomes. This is the compounding effect: week one is onboarding, week four is a system that knows your preferences before you state them.

## Why it matters

Memory is the difference between a tool you have to re-explain yourself to every day and a collaborator that builds context over time. The first week of running OpenClaw should be focused on onboarding — feeding the agent information about your goals, working style, and preferences. That investment pays out in every subsequent session.

## Practical setup

```
workspace/
  SOUL.md          — personality and behavior
  MEMORY.md        — long-term curated memory (load in private sessions only)
  USER.md          — who you are, timezone, contact info
  memory/
    2026-03-01.md  — daily session log
    2026-03-02.md
    ...
```

Keep `MEMORY.md` out of shared contexts (group chats, multi-user sessions). It contains personal context that shouldn't leak.

Extended memory patterns (from Matthew Berman's system): `LEARNINGS.md` for corrections, `ERRORS.md` for recurring mistake patterns, `FEATURE_REQUESTS.md` for self-improvement ideas. These feed into the [[self-improvement-system|Self-Improvement System]].

## Related

- [[prompt-file-governance|Prompt File Governance]] — controlling what auto-loads and what it costs
- [[self-improvement-system|Self-Improvement System]] — using memory files as input to an improvement feedback loop

## Sources

Alex Finn ("100 Hours of OpenClaw Lessons") — "first week = onboarding the agent with your context; value compounds; the agent becomes proactively useful as memory grows." Matthew Berman ("5 Billion Tokens Perfecting OpenClaw") — Prompt 8 (Memory System); Bee Memory ambient capture via wearable transcription.
