---
title: Getting Started with OpenClaw
description: What to set up first and what to do in your first week
tags: [guides, setup, openclaw]
---

# Getting Started with OpenClaw

OpenClaw takes about 5 minutes to install. Getting it actually useful takes a week of deliberate onboarding. This guide covers both.

## What You're Building Toward

By the end of your first week, you should have:

- An agent that knows who you are and what you're working on
- At least one running automation (the morning brief is the canonical first one)
- Memory and doctrine files that persist context across sessions
- A mental model for how to extend what the agent can do

The install is trivial. The onboarding is where the value gets built.

---

## Installation

### Prerequisites and install

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

### Where to host

#### Local machine

Zero latency, no monthly cost, uses your hardware. Fine for personal use where the machine is always on. Not ideal if you want the agent available when your laptop is closed.

#### VPS / cloud server

Always available, accessible from anywhere. Standard choice for production setups. Oracle Cloud Always Free tier (4 OCPU ARM A1, 24GB RAM) is the best free option. Most people run OpenClaw here once they want 24/7 availability.

#### Raspberry Pi / home server

Good if you want local hosting without keeping a laptop on. Documented extensively in the community — the [OpenClaw Pi setup guide](https://openclaw.ai) covers it. Latency is local, cost is electricity.

---

## Model Configuration

### Which provider to use

OpenClaw supports multiple providers. You bring your own API key:

- **Anthropic** — Claude models (Sonnet, Opus, Haiku). Most popular choice for production setups.
- **OpenAI** — GPT models. Strong alternative, especially if you're already paying for GPT-4.
- **Google** — Gemini models. Competitive on cost, strong on context length.

Set the model:

```bash
openclaw models set anthropic/claude-sonnet-4-5
```

Or configure in `openclaw.json` using `provider/model` format.

### Which model tier to use

For best results: use the strongest available model. The cost difference between Haiku and Sonnet is real but the capability gap is larger.

#### Haiku-tier (cheap, fast)

Use for: relevance scoring in pipelines, quick single-turn answers, anything where speed matters more than depth.

#### Sonnet-tier (balanced)

Use for: most production work. Strong reasoning, reasonable cost, available as a default.

#### Opus-tier (expensive, thorough)

Use for: complex builds, architecture decisions, anything where getting it wrong is expensive. Not for routine operations.

---

## Channel Setup

OpenClaw connects to your messaging apps. WhatsApp, Telegram, Discord, iMessage, Signal. Configure which channels you want in `openclaw.json`.

### Telegram

Easiest setup. Create a bot via BotFather, get the token, add one line to config. Done in 2 minutes.

### Discord

Requires a bot application setup, but has more features: reactions, threads, embeds, multiple channels. Worth the extra setup time if Discord is your primary interface.

Most people start with Telegram for speed, then add Discord when they want richer formatting and multi-channel routing.

---

## Your First Week

The install takes 5 minutes. The first week is about **onboarding the agent** — not building features.

### Day 1: Write the doctrine files

Before anything else, write the three files that shape every session.

#### Write `USER.md`

Name, timezone, how you want to be addressed, what you're working on, how you think about things. The agent reads this on every session. More context = more useful without prompting.

#### Write `SOUL.md`

How you want the agent to behave. Tone, what it should do proactively, what it should always ask before doing. This is your first real prompt engineering exercise. Keep it under 500 words.

#### Write `AGENTS.md`

Session initialization order, memory budget rules, workspace conventions, safety rules. The operational manual for the agent.

See [[guides/doctrine-files|Doctrine Files]] for exactly what to put in each.

### Day 2-3: Set up memory

#### Create the memory directory

```bash
mkdir -p ~/.openclaw/workspace/memory
```

#### Write the first daily note

Create `memory/YYYY-MM-DD.md` with what you set up and what you want the agent to remember.

#### Create `MEMORY.md`

Long-term curated memory. Sections: "Who I'm working with", "Current projects", "Key decisions", "Lessons learned". The agent reads this in every main session. Keep it curated — not a dump of everything.

The agent should update both files at the end of every session. Add this to `SOUL.md`: "Write memory/YYYY-MM-DD.md before ending any session."

See [[concepts/agent-memory|Agent Memory]] for the full architecture.

### Day 4-5: Run your first automation

The morning brief. A cron-triggered script that assembles a digest each morning and delivers to Telegram or Discord.

This proves:
- The cron system works
- The messaging channel delivers correctly
- Something runs without you triggering it

See [[guides/first-automation|Your First Automation]] for the full setup.

### Day 6-7: Review [[concepts/prompt-file-governance|Prompt File Governance]]

Before your auto-loaded files grow large. Every line costs tokens on every request. The doctrine files you wrote on Day 1 are now your baseline — review them. What's too vague? What's contradictory? What can be removed?

The agent becomes proactively useful as context accumulates. The first week of intentional onboarding pays out in every session that follows.

---

## Security Before Anything Else

Before giving your agent any external access — email, social accounts, any API with write permissions — read the security section. The agent can act on your behalf. That's a significant surface area if misconfigured.

### The short version

#### Scope skills to what they actually need

Don't grant write access to everything at once. Install skills one at a time and test what access they actually use.

#### Review channel access

Who can message your agent? On Discord, this is configurable per-channel. On Telegram, only users who know the bot link can message it. Review this before connecting sensitive integrations.

#### Read [[concepts/security-hygiene|Security Hygiene]]

Covers credential handling, what to never put in committed files, how to scope API access, and what the common attack surfaces are.

Alex Finn flagged this as the chapter most first-time users skip. Don't skip it.

---

## What's Next

Once you're through the first week:

- [[guides/self-improvement|The Self-Improvement Grindset]] — get the agent onto the compounding growth loop
- [[concepts/heartbeat-system|The Heartbeat System]] — autonomous proactive work between conversations
- [[concepts/build-queue-pattern|The Build Queue Pattern]] — persistent task backlog

---

## Related

- [[concepts/brains-and-muscles|Brains and Muscles]] — the mental model for understanding what OpenClaw is doing
- [[concepts/agent-memory|Agent Memory]] — how to make value compound over time
- [[concepts/prompt-file-governance|Prompt File Governance]] — keeping your prompt files lean and effective
