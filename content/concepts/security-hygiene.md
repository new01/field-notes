---
title: Security Hygiene
description: What to lock down before giving your OpenClaw agent any external access
tags: [concepts, security, openclaw]
---

The chapter most first-time OpenClaw users skip. Before you give your agent access to email, social accounts, or any API with write permissions — read this first.

The agent can act on your behalf. That's the whole point. But it's also a significant attack surface if misconfigured, and an easy way to have the agent do something irreversible because it misread an ambiguous instruction.

## The core principle

**Scope permissions to what's actually needed.** Not "give the agent access to everything and restrict later." Start locked down, open up intentionally.

## Channel access control

Not everyone who can message your bot should be able to invoke the agent. OpenClaw supports allowlisting by user ID for each channel. Set this before you configure any sensitive skills.

For Discord: configure which users and channels the agent responds to. A public bot that responds to everyone is a security problem.

For Telegram: use allowlisted chat IDs. Anyone who finds your bot token can message your agent otherwise.

## Skill permissions

Each skill has an access scope. Review what each installed skill can actually do:
- Read-only vs. read-write (files, email, calendar)
- Scoped vs. global (which directories, which accounts)
- Confirmation required vs. silent action

The `elevated` flag in exec calls requires explicit permission. Don't run with elevated by default.

## What to review before going live

- [ ] Channel allowlist configured — only intended users can invoke the agent
- [ ] Each installed skill reviewed for write permissions
- [ ] `dangerous` or `elevated` commands require confirmation
- [ ] Sensitive files (API keys, credentials, personal data) are outside the workspace directory
- [ ] The agent knows to ask before sending any external communication (email, social posts, messages to third parties)
- [ ] Memory files don't contain credentials (they're plaintext, treat them accordingly)

## The "external actions" rule

A clean heuristic from production experience:

**Free to do without asking**: read files, explore, search the web, write drafts, run read-only commands, organize notes.

**Ask first**: send emails, post publicly, message people, run destructive commands, anything that leaves the machine and can't be undone.

This is a `SOUL.md` rule, not just a config rule. Write it explicitly so the agent doesn't have to infer it.

## API key hygiene

If you're running multiple agents or sharing a machine, use separate API keys:
- Each workload gets its own key — limits blast radius if one goes wrong
- Separate keys have separate rate limit buckets — one heavy workload doesn't block another
- You can revoke one key without disrupting everything else

## Related

- [[guides/getting-started|Getting Started]] — when to set this up (before anything else)
- [[concepts/prompt-file-governance|Prompt File Governance]] — memory files are auto-loaded and plaintext; don't store secrets in them

## Sources

Alex Finn ("100 Hours of OpenClaw Lessons") — Security chapter (31:44); "the chapter most first-time users miss at their peril"; execution permissions, channel access control, what to lock down first. Matthew Berman ("5 Billion Tokens Perfecting OpenClaw") — Security Review council pattern for ongoing auditing.
