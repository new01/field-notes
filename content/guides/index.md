---
title: Guides
description: Practical walkthroughs for OpenClaw builders — from first install to production autonomous systems
---

# Guides

Step-by-step guides for getting OpenClaw working in production. Three learning paths depending on where you're starting from.

## Beginner Path

Start here. These four guides take you from install to a running autonomous morning brief in under a week.

### 1. [[guides/getting-started|Getting Started]]

Install OpenClaw, connect a channel, configure a model. The guide covers where to host (local, VPS, Raspberry Pi), which model provider to pick, and what to do in your first week. Most importantly: what the first seven days of onboarding should look like.

### 2. [[guides/doctrine-files|Doctrine Files]]

The three files that determine how your agent behaves between sessions: `SOUL.md` (operating philosophy and tone), `AGENTS.md` (session init order and workspace rules), and `USER.md` (who you are and what you're working on). Covers what to include in each, common mistakes, and how to evolve them as you learn what works.

### 3. [[guides/first-automation|Your First Automation — The Morning Brief]]

Build a daily digest that assembles while you sleep and delivers to Discord or Telegram before you're out of bed. Step-by-step: the script, the cron wrapper, the delivery setup, end-to-end verification. Proves the full stack works and gives you something tangible that's actually useful.

### 4. [[guides/self-improvement|The Self-Improvement Grindset]]

How to get your agent onto the compounding growth loop — where session N is smarter than session N-1. The four pillars (doctrine files, memory system, heartbeat Phase 2, skills), exact prompts to give a fresh agent, information sources to wire in, and what "compounding" looks like over months.

---

## Intermediate Path

Once you have the basics running. These guides move from "useful assistant" to "autonomous system."

### 1. [[concepts/heartbeat-system|The Heartbeat System]]

OpenClaw's periodic heartbeat enables proactive work between conversations. Two phases: Phase 1 (operations — health checks, monitoring, proof-of-life) and Phase 2 (dispatch — picking up build queue items, running ingestion pipelines). How to configure it, when to use heartbeat vs cron, and the patterns that prevent it from becoming a cost sink.

### 2. [[concepts/build-queue-pattern|The Build Queue Pattern]]

A persistent backlog the agent picks from autonomously. The most important lesson: the build queue is a collaborative tracker for sessions with you present, not an autonomous execution queue. Covers what makes a good queue item, gate checking, and the idle-dispatch pattern for async operation.

### 3. [[infrastructure/graph-orchestration|Graph Orchestration]]

Why sequential graph execution produces better results than parallel agent swarms for deterministic build tasks. The committed artifact pattern, the blackboard model, when subagents actually help vs when they fake-complete. Research from AWS, LangGraph, AutoGen, and Anthropic all converging on the same conclusion.

### 4. [[concepts/continuous-ingestion|Continuous Information Ingestion]]

Wire your agent to information sources so it learns while you're not watching. The eval-first principle (ingestion without evaluation is noise), free sources (HN Algolia API, GitHub RSS, YouTube channel RSS, ArXiv, Product Hunt, Lobste.rs), and the full pipeline pattern: fetch → filter → score → extract → route → discard.

---

## Advanced Path

Production-grade infrastructure for agents running autonomously at scale.

### 1. [[infrastructure/mission-control|Mission Control]]

The operational observability dashboard. Real-time view of system health, build queue status (in-progress, queued, done, stuck), cron status, active agents, and failure logs. Stuck detection, the doctor report, and how to set it up from scratch. The thing that makes running agents at scale not terrifying.

### 2. [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]]

The research behind why sequential beats parallel for build work, with specific patterns: the directed graph model, blackboard pattern, phase naming convention (plan-a/build-a/audit-a), gate checking between phases, and exactly when it's correct to parallelize. Covers AutoGen, LangGraph, Confluent, AWS, and Google research through early 2026.

### 3. [[infrastructure/pipeline-creation-pipeline|Pipeline Creation Pipeline]]

Meta: a pipeline that scaffolds new pipelines. Generates the script, the cron wrapper, the PM2 config, the Obsidian doc, and the pipelines.json registration from a spec file. Covers the pattern for making new infrastructure creation cheap and consistent.

### 4. [[skill-store/index|Skill Store]]

The curated collection of OpenClaw skills. Skills are the tools your agent uses — web search, shell commands, Discord, Telegram, GitHub, YouTube transcription, humanization, and more. How to find and install skills, how to write your own, and how to submit to the store.

---

## All Guides

- [[guides/getting-started|Getting Started]] — install, model setup, channels, first week
- [[guides/doctrine-files|Doctrine Files]] — SOUL.md, AGENTS.md, USER.md
- [[guides/first-automation|First Automation]] — morning brief, cron setup, delivery
- [[guides/self-improvement|Self-Improvement Grindset]] — compounding loop, pillars, information sources
