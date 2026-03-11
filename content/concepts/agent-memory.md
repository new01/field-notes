---
title: Agent Memory
description: How to give your OpenClaw agent continuity across sessions
tags: [concepts, memory, openclaw]
---

# Agent Memory

An OpenClaw agent wakes up fresh every session. Without memory files, it has no idea what happened yesterday, what you prefer, or what it was working on. With them, it picks up exactly where it left off.

## The Two-Tier Memory System

Memory has two tiers that serve different purposes and load at different times.

### Tier 1: Daily Notes

**Location:** `memory/YYYY-MM-DD.md`

Raw logs of what happened each session. What was built, what broke, what decisions were made. Written at session end or at context flush points, read at session start.

#### What goes in daily notes
- Decisions made (not just "made a decision" — the actual decision and why)
- Bugs found and root causes (searchable later)
- Files changed and what changed in them
- Things that didn't work and what was tried
- Context flush markers (`--- CONTEXT FLUSH [HH:MM] ---`)

#### What doesn't go in daily notes
- Play-by-play narration of every tool call
- Intermediate outputs that weren't meaningful
- Anything already captured in MEMORY.md

### Tier 2: Long-Term Memory

**Location:** `MEMORY.md`

Curated distillation of what matters across sessions. Not a log — a continuously updated knowledge base. Significant decisions, preferences, lessons learned, things that shouldn't be repeated.

#### What goes in MEMORY.md
- User preferences and working style
- Architecture decisions with rationale
- Recurring mistakes to avoid
- Key file paths and system topology
- Active projects and their status

#### Security note
Keep `MEMORY.md` out of shared contexts (group chats, multi-user sessions). It contains personal context that shouldn't leak. Load it only in private main sessions.

## Extended Memory Patterns

Beyond the two-tier baseline, these additional files handle specific memory needs.

### LEARNINGS.md

Corrections and things the agent got wrong. Written by the agent when it realizes it had a misconception. Format: what was believed → what's actually true → why it matters.

### ERRORS.md

Recurring mistake patterns with a specific focus: the same mistake made twice gets documented so it doesn't happen a third time. Format: mistake type, how it manifests, what the correct behavior is.

### FEATURE_REQUESTS.md

Self-improvement ideas generated during normal operation. Things the agent notices it should do better. Fed into the [[concepts/self-improvement-system|Self-Improvement System]] for periodic review.

## Why It Matters

### The compounding effect

Memory is the difference between a tool you have to re-explain yourself to every day and a collaborator that builds context over time.

#### Week 1
Onboarding — feeding the agent information about your goals, working style, and preferences. Primarily manual.

#### Week 2-3
The agent starts anticipating preferences. Fewer clarification questions. Decisions align without prompting.

#### Week 4+
Genuinely proactive. The agent surfaces things you'd want to know before you think to ask. Memory has compressed into real context.

### The cost consideration

Every memory file that auto-loads costs tokens on every session. A 50KB MEMORY.md means 50KB of context before any actual work starts.

##### The discipline
- Keep daily notes factual and compressed
- Review MEMORY.md monthly and prune what's no longer relevant
- See [[concepts/prompt-file-governance|Prompt File Governance]] for the full framework

## Practical Setup

```
workspace/
  SOUL.md          — personality and behavior doctrine
  MEMORY.md        — long-term curated memory (main sessions only)
  USER.md          — who you are, timezone, contact info, projects
  AGENTS.md        — session initialization rules and memory budget
  memory/
    2026-03-01.md  — daily session log
    2026-03-02.md
    ...
```

## Related

- [[concepts/prompt-file-governance|Prompt File Governance]] — controlling what auto-loads and what it costs
- [[concepts/self-improvement-system|Self-Improvement System]] — using memory files as input to an improvement feedback loop
- [[guides/doctrine-files|Doctrine Files]] — the complete guide to SOUL.md, AGENTS.md, USER.md

## Sources

Alex Finn ("100 Hours of OpenClaw Lessons") — "first week = onboarding the agent with your context; value compounds; the agent becomes proactively useful as memory grows." Matthew Berman ("5 Billion Tokens Perfecting OpenClaw") — Prompt 8 (Memory System); extended files LEARNINGS.md, ERRORS.md, FEATURE_REQUESTS.md.
