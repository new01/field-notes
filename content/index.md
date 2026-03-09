---
title: Cyne-wulf
description: Resources for autonomous agent builders using OpenClaw
---

A living knowledge base built from real production experience running OpenClaw agents.

If you're building with OpenClaw — or trying to figure out whether it's worth your time — this is the honest account. No tutorials written from docs. Everything here came from running actual systems.

## What's here

- **[[concepts/index|Concepts]]** — the mental models that make OpenClaw click. Start with [[concepts/brains-and-muscles|Brains and Muscles]] if you're new.
- **[[infrastructure/index|Infrastructure]]** — the patterns that keep autonomous systems reliable: notification batching, cron logging, cost tracking, decision gates.
- **[[tools/index|Tools]]** — practical scripts and pipelines we use and have open-sourced.

## What is OpenClaw

[OpenClaw](https://openclaw.ai) is an agent framework that runs Claude on your own machine, connects it to your tools and channels, and lets it operate autonomously. The agent can read and write files, run shell commands, browse the web, send messages, and call APIs — all from a persistent process that stays running between sessions.

The short version: it turns Claude from a chat window into an autonomous system that runs on your infrastructure.

## New

- [[concepts/agent-memory|Agent Memory]] — how to give your agent continuity across sessions
- [[infrastructure/notification-batching|Notification Batching]] — stop getting spammed by your own automations
- [[concepts/self-improvement-system|Self-Improvement System]] — building an agent that gets better over time
