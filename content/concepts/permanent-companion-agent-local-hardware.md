---
title: Permanent Companion Agent on Local Hardware
description: Lessons from running an always-on AI agent on local hardware — what works, what breaks, and how to build an agent that lives on your own machine indefinitely.
tags: [concepts, agents, local-models, infrastructure, hardware, memory, openclaw]
---

Most AI agents are ephemeral: you start a session, run a task, the session ends. A permanent companion agent is something different — an agent that runs continuously on hardware you own, has an identity that persists across months, and builds real context about your work, your preferences, and your history over time. No API bills per session. No cloud vendor required.

Building one is increasingly practical. People are doing it on Raspberry Pis, old ThinkPads, NAS boxes, and mini-PCs tucked behind their monitors. The lessons from these builds cluster around the same failure modes.

## Why local, why permanent

The appeal is straightforward. A cloud-hosted agent that you invoke through an API is powerful but transient. It forgets you between sessions unless you work to maintain memory externally. It's billed per token. Its behavior can change when the provider updates their model. And it requires internet access.

A local permanent agent inverts all of this:

- **No per-session cost** — hardware amortizes over years; inference is essentially free at small scale
- **Always available** — no API outages, no rate limits, no internet required
- **True persistence** — the agent lives on a machine you control; its memory files, configurations, and learned context persist indefinitely
- **Privacy** — sensitive data never leaves the hardware
- **Consistent behavior** — a frozen local model doesn't change behavior when the provider pushes an update

The trade-off is capability. Frontier cloud models are substantially more capable than what runs well on consumer hardware. A permanent local agent needs tasks sized for the models available to it.

## Hardware that works

The most common configurations people report success with:

**Raspberry Pi 5 (8GB)** — runs small models (1B–3B) at useful speeds with the right quantization. Best suited for routing, lightweight triage, and triggering larger systems. Draws minimal power; can run 24/7 for cents per month. Thermal throttling is a real concern under sustained inference load — active cooling is worth it.

**Mini-PC (Intel N100, N305, or equivalent)** — the sweet spot for many builds. 16–32GB RAM, 10–20W idle. Runs 7B models comfortably in Q4 quantization, 13B models at acceptable speed. Fits in a pocket, costs $100–200, silent, and efficient enough to run permanently.

**Old workstation or gaming PC** — if you have a mid-range GPU collecting dust (RTX 3060, 3070, 4060), it becomes an excellent inference machine. 7B–34B models run fast; the agent can handle substantially more complex tasks. The cost is power consumption (150–300W under load) and noise.

**NAS box** — for people already running a NAS, adding an agent to the same hardware makes sense. Limited compute means small models only, but for orchestration and lightweight tasks it works.

**Dedicated inference device** — for teams or power users, purpose-built inference hardware (e.g., devices built around neural processing units) offers better performance-per-watt than general compute. Still maturing as a product category.

## Model selection for constrained hardware

The choice of model matters more than the choice of hardware. A 7B model running well beats a 13B model thrashing memory.

Practical heuristics:

- **For a Pi or low-RAM mini-PC**: stick to 1B–3B models (Qwen2.5-1.5B, Phi-3-mini, SmolLM2). They're fast enough for routing and simple tasks.
- **For a mini-PC with 16GB RAM**: 7B models in Q4 or Q5 quantization (Llama 3.1 8B, Mistral 7B, Qwen2.5-7B) are the workhorses. Most agent tasks land here.
- **For a GPU machine**: 13B–34B models become practical, and for many tasks you approach cloud model quality. Consider a mixture: local 7B for routing, local 13B+ for complex tasks, cloud as a fallback for genuinely hard reasoning.

For long-running companion agents specifically, models with strong instruction following and consistent output format matter more than raw benchmark scores. A model that reliably writes structured JSON and respects system prompts is worth more than a higher-scoring model that goes off-script.

## The memory problem

This is where most permanent agent builds get complicated.

A cloud agent with good prompting can perform well in a single session without any persistent memory. A permanent companion agent that's been running for three months and remembers nothing about you is a failure state — it's just a local chatbot.

Real persistence requires deliberate architecture:

**Daily logs** — the agent writes what it did and what it learned to dated markdown files. These are raw episodic memory. Simple, reliable, incrementally built.

**Curated long-term memory** — periodically, the agent reviews its logs and distills what's worth keeping: preferences you've expressed, decisions made, ongoing projects, people and context. This becomes the summary that gets prepended to every session.

**Vector retrieval** — for deep history (months of logs), in-context summarization doesn't scale. A local vector store (Qdrant, ChromaDB, or similar) running on the same hardware enables semantic retrieval: the agent queries for relevant past context rather than trying to hold everything in context.

**Handoff files** — when the agent restarts (power cycle, update, crash), it reads a structured handoff file that reconstructs its working context. Without this, every restart is a cold start.

The failure mode to watch: memory files that grow indefinitely without curation. An agent that's been running for a year accumulates enormous context if it never distills. The cure is a regular memory maintenance step — the agent reviews and summarizes its own history, keeping the curated layer small and relevant.

## Keeping the agent alive

Permanent means permanent — including through crashes, restarts, and updates.

**Process supervision** — the agent process needs to be managed by a supervisor that restarts it if it crashes. On Linux, `systemd` with `Restart=on-failure` is the standard approach. The agent should start automatically on boot.

**Health checks** — a simple heartbeat mechanism confirms the agent is running and responsive. If the heartbeat fails, alert or auto-restart. This is especially important for agents that run background tasks where a silent crash means tasks silently stop.

**Graceful shutdown** — when the system needs to restart (updates, power events), the agent should catch the shutdown signal and write a clean handoff file before exiting. An unclean shutdown that loses working context is annoying once; if it happens on every system update, it compounds.

**Update strategy** — local models need occasional updates. The agent framework needs occasional updates. These should be decoupled: model updates don't require agent restarts; agent updates should be tested before deployment. A staging environment (even just a second terminal) catches breaking changes before they affect the live agent.

## Thermal and power discipline

Hardware running 24/7 under load accumulates heat and power costs that an occasionally-used machine doesn't.

Inference is bursty: a prompt hits, the model runs at full load for seconds, then idles. This thermal pattern is more sustainable than continuous load, but sustained heavy use on under-cooled hardware shortens component life.

Practical mitigations:
- Adequate passive or active cooling. A Pi in a case with no heatsink will throttle; a Pi with a proper heatsink and fan won't.
- CPU/GPU temperature monitoring as part of health checks. If the agent notices it's running hot, it can throttle its own task rate.
- Appropriate model sizing. Running a model that constantly saturates memory bandwidth generates more heat than a smaller model with headroom.
- Power consumption awareness. A 150W machine running 24/7 costs ~$150/year in electricity. A 10W mini-PC costs ~$10/year. The math matters for permanent deployments.

## What a mature build looks like

After the failure modes have been worked through, a well-functioning permanent local agent:

- Boots automatically, restores context from its handoff file, resumes whatever it was doing
- Handles requests when present, runs background tasks (email triage, research, monitoring) on a schedule when idle
- Writes structured logs at the end of each significant activity
- Runs memory maintenance weekly — reviewing logs, updating its curated summary, pruning stale context
- Handles crashes and power cycles without losing more than the current in-progress task
- Routes complex tasks to a cloud model when needed, handles routine tasks entirely locally

The "permanent companion" framing matters. This isn't an assistant you invoke. It's an agent that lives on your network, knows your work, and accumulates real understanding of your context over time. That requires architectural choices that most agent frameworks don't make by default.

## Related

- [[concepts/local-first-ai-infrastructure|Local-First AI Infrastructure]] — the broader pattern of running AI on owned hardware
- [[concepts/agent-memory-systems|Agent Memory Systems]] — memory architecture for persistent agents
- [[concepts/agent-qdrant-rag-memory|Agent RAG Memory with Vector Databases]] — deep memory retrieval for long-running agents
- [[concepts/multi-day-agent-build-loops|Multi-Day Agent Build Loops]] — extended agent execution patterns and their failure modes
- [[concepts/agent-memory|Agent Memory]] — how OpenClaw specifically handles memory across sessions
