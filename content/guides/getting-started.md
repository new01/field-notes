---
title: Getting Started with OpenClaw
description: What to set up first and what to do in your first week
tags: [guides, setup, openclaw]
---

OpenClaw takes about 5 minutes to install. Getting it actually useful takes a week of deliberate onboarding. This guide covers both.

## Install

Node 22+ required. OpenClaw runs on any OS — Linux, macOS, Windows.

```bash
npm install -g openclaw
openclaw gateway start
```

That starts the Gateway process — the persistent daemon that manages channels, sessions, and routing. It runs in the background and stays running between sessions.

From there, run the setup wizard:

```bash
openclaw onboard
```

This walks through model provider configuration, channel connections, and initial settings. The [official docs](https://openclaw.ai) have the full step-by-step.

## Where to host

**Local machine** — zero latency, no monthly cost, uses your hardware. Fine for personal use where the machine is always on. Not ideal if you want the agent available when your laptop is closed.

**VPS / cloud server** — always available, accessible from anywhere. Standard choice for production setups. Oracle Cloud Always Free tier (4 OCPU ARM A1, 24GB RAM) is the best free option available.

**Raspberry Pi / home server** — good if you want local hosting without keeping a laptop on. Alex Finn documented this path in detail — the [OpenClaw Pi setup guide](https://openclaw.ai) covers it.

## Model providers

OpenClaw supports multiple providers. You bring your own API key:

- **Anthropic** — Claude models (Sonnet, Opus, Haiku). Most popular choice.
- **OpenAI** — GPT models
- **Google** — Gemini models
- And others via the pi-ai catalog

Set the model via `openclaw models set anthropic/claude-sonnet-4-5` or configure it in `openclaw.json`. Use `provider/model` format.

For best results: use the strongest available model. The cost difference between Haiku and Sonnet is real but the capability gap is larger.

## Channels

OpenClaw connects to your messaging apps. WhatsApp, Telegram, Discord, iMessage, Signal. You configure which channels you want in `openclaw.json` — each channel module handles its own auth and connection.

Most people start with Telegram or Discord — both have clean bot setup flows. Telegram is one `botToken` config line. Discord requires a bot application, but has more features (reactions, threads, embeds).

## Your first week

The install takes 5 minutes. The first week is about **onboarding the agent** — not building features.

What to do before anything else:

1. **Write `USER.md`** — name, timezone, how you want to be addressed, what you're working on, how you think about things. The agent reads this on every session. The more context it has, the more useful it becomes without prompting.

2. **Write `SOUL.md`** — how you want the agent to behave. Tone, what it should do proactively, what it should always ask before doing. This is your first prompt engineering exercise.

3. **Set up memory files** — `memory/YYYY-MM-DD.md` for daily logs, `MEMORY.md` for long-term curated memory. Tell the agent to update these. See [[concepts/agent-memory|Agent Memory]].

4. **Run one automation end-to-end** — the morning brief (daily digest via Telegram) is the canonical first automation. It proves the cron system works, gives you something tangible, and is genuinely useful. Details in [[concepts/self-improvement-system|Self-Improvement System]].

5. **Review [[concepts/prompt-file-governance|Prompt File Governance]]** — before your auto-loaded files grow large. Every line costs tokens on every request.

The agent becomes proactively useful as context accumulates. The first week of intentional onboarding pays out in every session that follows.

## Security before anything else

Before giving your agent any external access — email, social accounts, any API with write permissions — read the security section. The agent can act on your behalf. That's a significant surface area if misconfigured.

The short version:
- Scope skills to what they actually need — don't grant write access to everything at once
- Review what channels are connected and who can message the agent
- Be intentional about what the agent can do without confirmation

Alex Finn flagged this as the chapter most first-time users skip. Don't skip it.

## Related

- [[concepts/brains-and-muscles|Brains and Muscles]] — the mental model for understanding what's happening
- [[concepts/agent-memory|Agent Memory]] — how to make value compound over time
- [[concepts/prompt-file-governance|Prompt File Governance]] — keeping your prompt files lean
