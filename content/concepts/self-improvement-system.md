---
title: Self-Improvement System
description: A feedback loop where the agent tracks its own errors and proposes improvements
tags: [concepts, self-improvement, feedback-loop, openclaw]
---

An automated feedback loop where the agent tracks its own errors, learns from corrections, and proposes improvements to itself. The difference between an agent that makes the same mistakes forever and one that becomes more capable over time.

## The three memory files

**`LEARNINGS.md`** — corrections and insights. When you correct the agent or it discovers a better approach, it writes it here. On the next session, it reads this file and doesn't repeat the mistake.

**`ERRORS.md`** — recurring error patterns. Not one-off failures — patterns that show up repeatedly. "Always checks API health before marking a task done." "Never deploys without running the PII scan first." These become persistent rules.

**`FEATURE_REQUESTS.md`** — self-improvement ideas. When the agent notices something it could do better but doesn't have time to fix now, it logs it here. The Innovation Scout reviews this on a daily cron.

## The automated review loop

On a daily cron, an Innovation Scout subagent scans the codebase for automation opportunities — repetitive patterns, unhandled edge cases, things that could run automatically but don't yet. It generates improvement proposals.

Each proposal goes through an accept/reject loop: you review, mark accepted or rejected, and accepted proposals get queued for implementation.

The result: the agent proactively identifies work it could be doing. You don't have to think of everything.

## Security and health reviews

Periodic review councils run automatically:
- **Security Review** — multi-perspective analysis of external surface area, credential handling, data exposure risks
- **Platform Health Review** — reliability, test coverage, data integrity, stale cron jobs

These aren't one-shot audits. They run on schedule and surface findings as notifications.

## Why it matters

Most agents stay static. They do what you built them to do and nothing more. A self-improvement loop makes the agent a collaborator that grows — one that flags its own limitations, proposes fixes, and gets better at being your agent over time.

This is a long-term investment. The first month you won't notice much. Six months in, the agent has accumulated dozens of corrections and learned to avoid mistakes that would have cost you an hour each.

## Related

- [[concepts/agent-memory|Agent Memory]] — the memory files this system writes to
- [[infrastructure/ai-advisory-board|AI Advisory Board]] — decision gate before accepting any proposed improvement

## Sources

Matthew Berman ("5 Billion Tokens Perfecting OpenClaw") — Prompt 15; LEARNINGS.md + ERRORS.md + FEATURE_REQUESTS.md pattern; Innovation Scout daily cron; Security Review council; Platform Health Review; accept/reject feedback loop.
