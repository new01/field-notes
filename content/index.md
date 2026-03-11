---
title: Claw Field Notes
description: Production knowledge for OpenClaw builders — patterns, infrastructure, and hard-won lessons
---

# Claw Field Notes

Real-world patterns and infrastructure for people building with [OpenClaw](https://openclaw.ai). Everything here came from running actual systems — not tutorials written from docs. If something is documented here, it's because we built it, broke it, and figured it out.

## Start Here

Three paths depending on where you are. Each builds on the previous.

### Beginner Path — Get Useful in a Week

1. [[guides/getting-started|Getting Started]] — install, model setup, channels, first session
2. [[guides/doctrine-files|Doctrine Files]] — the three files that determine how your agent behaves
3. [[guides/first-automation|Your First Automation]] — a morning brief that runs while you sleep

### Intermediate Path — Build Autonomous Systems

1. [[concepts/heartbeat-system|The Heartbeat System]] — periodic proactive work without you asking
2. [[concepts/build-queue-pattern|The Build Queue Pattern]] — persistent work backlog the agent picks from
3. [[infrastructure/graph-orchestration|Graph Orchestration]] — sequential execution that actually produces reliable output
4. [[guides/self-improvement|The Self-Improvement Grindset]] — compounding growth loop, session over session

### Advanced Path — Production Infrastructure

1. [[infrastructure/mission-control|Mission Control]] — real-time observability dashboard for your agent fleet
2. [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — the research behind why sequential beats parallel
3. [[infrastructure/pipeline-creation-pipeline|Pipeline Creation Pipeline]] — scaffolding new pipelines automatically
4. [[skill-store/index|Skill Store]] — extend what your agent can do

---

## The Tour

Five key pages that give you the conceptual backbone of OpenClaw in production.

- **[[concepts/brains-and-muscles|Brains and Muscles]]** — the core mental model for understanding what OpenClaw is doing and why this architecture works
- **[[concepts/agent-memory|Agent Memory]]** — how to give your agent continuity across sessions so context compounds instead of resetting
- **[[concepts/dead-mans-switch|Dead-Man's Switch]]** — monitoring pattern where absence of a signal is the alarm — essential for autonomous systems you can't watch 24/7
- **[[infrastructure/graph-orchestration|Graph Orchestration]]** — why sequential execution outperforms parallel agent swarms for real build work
- **[[concepts/self-improvement-system|Self-Improvement System]]** — the feedback loop that separates agents that plateau from agents that compound

---

## What's Here

### Guides

Step-by-step walkthroughs for real tasks.

- **[[guides/index|Guides]]** — start here if you're new. Installation, doctrine files, first automation, self-improvement loop.

### Concepts

The mental models that make OpenClaw click.

- **[[concepts/brains-and-muscles|Brains and Muscles]]** — the foundational architecture model
- **[[concepts/agent-memory|Agent Memory]]** — continuity and persistence across sessions
- **[[concepts/heartbeat-system|Heartbeat System]]** — autonomous proactive work on a schedule
- **[[concepts/build-queue-pattern|Build Queue Pattern]]** — persistent task backlog with gate checking
- **[[concepts/self-improvement-system|Self-Improvement System]]** — the compounding feedback loop

### Infrastructure

Patterns that keep autonomous systems reliable.

- **[[infrastructure/index|Infrastructure]]** — cron, graph orchestration, cost tracking, notification batching, Mission Control
- **[[infrastructure/cron-infrastructure|Cron Infrastructure]]** — how to run scheduled agent work that actually stays running
- **[[infrastructure/notification-batching|Notification Batching]]** — stop getting spammed by your own automations

### Tools

Practical scripts and pipelines we run in production.

- **[[tools/index|Tools]]** — Whisper transcription, humanization pipeline, build queue runner, Nitter scanner

---

## What is OpenClaw

[OpenClaw](https://openclaw.ai) is a self-hosted gateway that connects your chat apps — WhatsApp, Telegram, Discord, iMessage, and more — to AI agents. You run a single Gateway process on your own machine or server. It bridges your messaging apps to an always-available AI assistant that can use tools, maintain sessions, remember context, and run autonomously.

It supports multiple model providers: Anthropic, OpenAI, Google, and others. You bring your own API key.

The short version: a persistent, self-hosted AI agent connected to every communication channel you use.

---

## Recent

- [[concepts/heartbeat-system|Heartbeat System]] — Phase 1 ops vs Phase 2 proactive work, proof-of-life timestamp pattern
- [[concepts/build-queue-pattern|Build Queue Pattern]] — collaborative tracker model, gate checking, idle dispatch
- [[concepts/continuous-ingestion|Continuous Information Ingestion]] — free sources, the eval-first principle, YouTube pipeline
- [[infrastructure/mission-control|Mission Control]] — dashboard setup, stuck detection, doctor report
- [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — why sequential beats parallel, phase naming, gate checks
