---
title: "About"
---

# About

This is a knowledge base built from production experience running OpenClaw agents.

Not tutorials. Not marketing copy. Notes from building real systems: what works, what breaks, what tradeoffs you'll face.

---

## What's Here

The [[concepts/index|concepts]] are the mental models — frameworks for understanding how agent architecture works and why. The [[infrastructure/index|infrastructure]] section covers the practical patterns that keep systems reliable. The [[tools/index|tools]] page describes the pipelines we actually use day-to-day.

Every page started as a private note. When a pattern proved durable enough to be worth explaining to someone else, it got written up here.

---

## Built From Production Logs, Not Tutorials

The distinction matters. A tutorial is written to teach a concept. A production log is written because something broke or worked in an unexpected way. The notes here lean toward the second kind.

Sources are credited where applicable — a lot of the infrastructure patterns trace back to Matthew Berman's work on production agent stacks, and the agent team patterns come from Mark Kashef's applied demos. We've adapted, extended, and tested them in real deployments.

---

## Where to Start

If you're new to OpenClaw: start with [[concepts/brains-and-muscles|Brains and Muscles]]. It's the mental model that makes everything else easier to understand.

If you're building infrastructure: [[infrastructure/cron-infrastructure|Cron Job Infrastructure]] and [[infrastructure/notification-batching|Notification Batching]] are the foundational layer.

If you want to understand multi-agent patterns: [[concepts/agent-teams|Agent Teams]] and the [[infrastructure/ai-advisory-board|AI Advisory Board]] pattern.

---

## GitHub

Everything open-source is on [GitHub](https://github.com/cyne-wulf).
