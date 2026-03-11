---
title: Brains and Muscles
description: The two-layer model that explains every agent system
tags: [concepts, architecture, openclaw]
---

# Brains and Muscles

Every agent system has two layers. The **brain** is the LLM — Claude in OpenClaw's case. It handles reasoning, decisions, and language. The **muscles** are everything else: the tools, skills, and integrations that let the agent take real-world actions.

Send a message. Read a file. Run a command. Browse a URL. Call an API. That's muscle. Deciding *what* to send, *which* file to read, *why* — that's brain.

## Why It Matters

This model gives you an immediate diagnostic framework when something goes wrong.

### Diagnosing Failures

Was it a brain problem or a muscle problem?

#### Brain failures
Wrong reasoning, bad prompt, hallucination, misunderstood intent. Fix: better prompt, clearer instructions, stronger model, tighter context.

#### Muscle failures
Tool error, integration down, permission denied, API rate limit, malformed output. Fix: debug the tool, check credentials, handle the edge case in the skill.

These have completely different fixes. Mixing them up means you're debugging the wrong layer.

### Planning New Capabilities

Before writing any code, ask: **what muscle does this need?**

#> [!tip] Check before you build
> Most capability gaps in OpenClaw setups are muscle gaps, not brain gaps. Before writing any code, exhaust the checklist below.

### The muscle-first checklist
1. Does a built-in tool already do this? (Read, Write, Bash, Browser, WebSearch)
2. Does an existing skill handle it? Check ClawhHub before building.
3. Is it a one-line shell command the Bash tool can call?
4. Only if none of the above: build a new skill or integration.

The brain can usually handle the reasoning. The constraint is almost always on the muscle side.

### Onboarding New Users

People understand the brain/muscles model immediately because they already think about AI and tools as separate things. It makes the architecture legible without requiring deep technical knowledge.

## In Practice

### Built-in muscles (available by default)
- **File read/write** — built-in Read, Write, Edit tools
- **Shell execution** — Bash tool; runs any command with appropriate permissions
- **Web access** — WebSearch and WebFetch built-in
- **Browser automation** — full Playwright-based browser tool built-in
- **Cron scheduling** — OpenClaw's native cron system

### Muscles added through skills
- **Message channels** — Discord, Telegram, Signal, WhatsApp via channel skills
- **API integrations** — Stripe, GitHub, external services via skill definitions
- **Semantic search** — grepai integration for codebase search
- **Voice output** — TTS skill for audio delivery
- **Notifications** — custom routing and batching via notification skills

### The upgrade path

#### Upgrading the brain
Better model selection, refined prompting, tighter context management, clearer doctrine files.

#### Upgrading the muscles
New skill installs from ClawhHub, new channel connections, new API integrations, new cron automations.

The brain stays the same. The muscles expand as you add integrations. Most meaningful improvements in an established OpenClaw setup come from the muscle side — the brain is already capable, it just needs more surfaces to act on.

## Related

- [[concepts/agent-teams|Agent Teams]] — running multiple brains in parallel on the same task
- [[concepts/agent-memory|Agent Memory]] — how the brain persists state across sessions
- [[concepts/prompt-file-governance|Prompt File Governance]] — what auto-loads into the brain on every request
- [[concepts/skill-based-agent-architecture|Skill-Based Agent Architecture]] — how muscles are defined as plain text skills

## Sources

Coined by Alex Finn in his "100 Hours of OpenClaw Lessons" video. Matthew Berman implicitly uses the same model throughout his 22-prompt system — separating model quality (brain) from integration depth (muscles) in every recommendation.
