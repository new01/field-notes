---
title: Claw Field Notes
description: Production knowledge for OpenClaw builders — patterns, infrastructure, and hard-won lessons
---

Real-world patterns and infrastructure for people building with [OpenClaw](https://openclaw.ai).

Everything here came from running actual systems — not tutorials written from docs. If something is documented here, it's because we built it, broke it, and figured it out.

## What's here

- **[[guides/index|Guides]]** — start here if you're new. Installation, model setup, first-week onboarding, security.
- **[[concepts/index|Concepts]]** — the mental models that make OpenClaw click. Start with [[concepts/brains-and-muscles|Brains and Muscles]].
- **[[infrastructure/index|Infrastructure]]** — patterns that keep autonomous systems reliable: notification batching, cron logging, cost tracking, decision gates.
- **[[tools/index|Tools]]** — practical scripts and pipelines we run in production.

## What is OpenClaw

[OpenClaw](https://openclaw.ai) is a self-hosted gateway that connects your chat apps — WhatsApp, Telegram, Discord, iMessage, and more — to AI agents. You run a single Gateway process on your own machine or a server. It bridges your messaging apps to an always-available AI assistant that can use tools, maintain sessions, remember context, and run autonomously.

It supports multiple model providers: Anthropic, OpenAI, Google, and others. You bring your own API key.

The short version: a persistent, self-hosted AI agent connected to every communication channel you use.

## New

- [[concepts/agent-memory|Agent Memory]] — how to give your agent continuity across sessions
- [[infrastructure/notification-batching|Notification Batching]] — stop getting spammed by your own automations
- [[concepts/self-improvement-system|Self-Improvement System]] — building an agent that gets better over time
