---
title: Subscription Token Account Risk
description: Why using Claude subscription tokens for agent automation risks account termination — and why API keys are the only safe path for production workloads
tags: [concepts, security, anthropic, infrastructure, openclaw]
---

Anthropic has been terminating accounts that use Claude subscription tokens to power automated agents. For any production agent workload, a proper API key is the only safe path.

## The distinction

Claude offers two ways to authenticate:

**Subscription tokens** (`sk-ant-oat01-...`) — OAuth tokens tied to a Claude.ai subscription. Intended for browser-based interactive use. Not for programmatic automation.

**API keys** (`sk-ant-api03-...`) — Keys issued through console.anthropic.com. Explicitly designed for programmatic access, with usage-based billing.

## Why it matters for agent stacks

Subscription tokens are cheaper in the short term — a flat monthly fee instead of per-token charges. This makes them tempting for agent workloads that run 24/7.

The risk: Anthropic monitors usage patterns. Agents making hundreds of calls per day look nothing like a human using Claude.ai interactively. When detected, accounts are terminated without warning. The entire agent fleet goes down.

## The detection surface

Signs that flag subscription-token abuse:
- High call volume (agents typically far exceed human usage patterns)
- Consistent call intervals (cron-driven agents call at predictable times)
- Long-running programmatic sessions (not typical browser use)
- Missing browser fingerprints and session metadata

## The mitigation

Get a proper API key from console.anthropic.com. Wire it into your auth config:

```bash
openclaw auth add anthropic --key sk-ant-api03-...
```

Per-token billing is more expensive at scale, but it's the only path that doesn't risk the account. Build the cost into your unit economics from the start.

## The broader lesson

Free-tier or subscription-tier workarounds for production agent workloads are a form of technical debt that compounds quickly. The cost of an unplanned account termination — downtime, lost work, migration overhead — almost always exceeds the savings from the workaround.

## Related

- [[concepts/pipeline-cost-per-run|Pipeline Cost Per Run]] — establishes concrete cost benchmarks for API-priced workloads
- [[concepts/llm-cost-comparison-tools|LLM Cost Comparison Tools]] — tools for comparing API pricing across providers
- [[concepts/dead-mans-switch|Dead-Man's Switch]] — monitoring pattern for when agent infrastructure goes down unexpectedly
