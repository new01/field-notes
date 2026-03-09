---
title: Brains and Muscles
description: The two-layer model that explains every agent system
tags: [concepts, architecture, openclaw]
---

Every agent system has two layers. The **brain** is the LLM — Claude in OpenClaw's case. It handles reasoning, decisions, and language. The **muscles** are everything else: the tools, skills, and integrations that let the agent take real-world actions. Send a message. Read a file. Run a command. Browse a URL. Call an API.

Upgrading the brain means a better model or better prompts. Upgrading the muscles means new skills, new channels, new integrations.

## Why it matters

When something goes wrong, this model gives you a diagnostic framework immediately. Was it a brain problem — wrong reasoning, bad prompt, hallucination — or a muscle problem — tool error, integration down, permission denied? These have completely different fixes.

When planning new capabilities, ask "what muscle does this need?" before writing any code. Often the answer is "it already exists as a skill" or "it's a one-line shell command." The brain can handle the reasoning; you just need to give it the right action surface.

This framing also helps when onboarding someone new to OpenClaw. People understand it immediately because they already think about AI and tools as separate things.

## In practice

A well-muscled OpenClaw setup has:
- File read/write (built-in)
- Shell command execution (built-in)
- Web search and fetch (built-in)
- Message channels: Discord, Telegram, Signal (via skills or config)
- Browser automation (built-in browser tool)
- Cron scheduling (via OpenClaw cron system)

The brain stays the same. The muscles expand as you add integrations.

## Related

- [[concepts/agent-teams|Agent Teams]] — running multiple brains in parallel on the same task
- [[concepts/agent-memory|Agent Memory]] — how the brain persists state across sessions
- [[concepts/prompt-file-governance|Prompt File Governance]] — what auto-loads into the brain on every request

## Sources

Coined by Alex Finn in his "100 Hours of OpenClaw Lessons" video, used to explain how OpenClaw works to newcomers. Matthew Berman implicitly uses the same model throughout his 22-prompt system — separating model quality (brain) from integration depth (muscles) in every recommendation.
