---
title: Prompt File Governance
description: Every line in auto-loaded files costs tokens on every request
tags: [concepts, tokens, governance, openclaw]
---

Every file that auto-loads into agent context on every request burns tokens on every request — including heartbeats, background tasks, and short follow-up messages. There is no free context. Treat auto-loaded files like a CSS stylesheet: lean, purposeful, no duplication.

## The discipline

Each file gets one job. Nothing else.

| File | Contains | Does NOT contain |
|------|----------|-----------------|
| `SOUL.md` | Personality, tone, behavior | Operational rules |
| `AGENTS.md` | Security rules, style bans, operational standards | Personal context |
| `USER.md` | Name, timezone, contact info | Preferences, history |
| `TOOLS.md` | Channel IDs, paths, device names | Documentation |
| `MEMORY.md` | Curated long-term memory | Anything in other files |

The rule: if something exists in one file, it does not exist in another. No duplication across files. If you want the agent to cross-reference a rule, link to it — don't copy it.

## Why it matters

A bloated prompt file stack adds thousands of tokens to every single request. With heartbeats firing every 30 minutes and background cron tasks running every hour, this compounds fast. A disciplined 8KB session start costs roughly 5x less than a lazy 50KB one at production scale.

The secondary effect: when files have clear scope, it's obvious where a new rule belongs. When they're all dumped into one file, everything becomes ambiguous.

## What to audit

Read every auto-loaded file and ask: would removing this line change behavior? If no, cut it. Is this rule duplicated somewhere else? Deduplicate. Does this file contain things that belong in a different file? Move them.

Keep `IDENTITY.md` under 5 lines. Keep `USER.md` under 20. Review `SOUL.md` quarterly — every rule you added "just in case" is probably still there.

## Related

- [[concepts/agent-memory|Agent Memory]] — what belongs in MEMORY.md specifically
- [[concepts/brains-and-muscles|Brains and Muscles]] — the brain reads these files; respect what you load into it

## Sources

Matthew Berman ("5 Billion Tokens Perfecting OpenClaw") — Prompt 17 (Prompt File Organization); exact file-to-scope mapping; writing style bans as part of governance; "every line in auto-loaded files costs tokens on every request."
