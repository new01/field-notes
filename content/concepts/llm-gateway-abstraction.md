---
title: LLM Gateway Abstraction
description: A self-hosted proxy layer that provides OpenAI-compatible API endpoints with failover, load balancing, and model routing across multiple LLM providers — eliminating vendor lock-in without rewriting agent code.
tags: [concepts, infrastructure, llm, api, cost, resilience]
---

Every agent pipeline that calls an LLM has an implicit coupling to a specific provider. The API endpoint, authentication format, request schema, and error codes are all provider-specific. When you want to switch from Claude to GPT-4 — or run both in parallel, or add a local model as a fallback — you're rewriting infrastructure rather than making a product decision.

An LLM gateway breaks that coupling. It sits between your agent code and the upstream providers, exposing a single stable interface while managing provider complexity behind the scenes.

## What a gateway provides

At its core, an LLM gateway is a proxy with a contract: agents send requests to the gateway using a standard format (typically OpenAI-compatible), and the gateway handles everything downstream — routing to the right provider, handling authentication, retrying failures, and returning a response in the same standard format.

The key capabilities this enables:

**Model routing** — route different request types to different models. Fast, cheap queries go to a smaller model; complex reasoning goes to a larger one. The agent code specifies intent (or just model name); the gateway resolves it to a provider and model.

**Failover** — if Claude returns a 529 overload or OpenAI returns a 503, the gateway retries against a secondary provider automatically. From the agent's perspective, the request succeeded. No custom retry logic needed in every script.

**Load balancing** — distribute requests across multiple API keys, accounts, or provider endpoints to stay under rate limits. Particularly useful when multiple pipelines share the same key.

**Cost control** — enforce spending limits per caller, per model tier, or per time window. Route to cheaper models when within budget thresholds, escalate to premium models only when needed.

**Observability** — centralized logging of every API call: provider, model, token counts, latency, cost. A gateway gives you a single place to see what your entire agent system is spending and where it's slow.

## Why OpenAI-compatible matters

The OpenAI chat completions API format has become a de facto standard. Most providers — Anthropic (via compatibility layers), Mistral, Together AI, Ollama, and others — either natively support it or offer a compatible endpoint.

A gateway that exposes an OpenAI-compatible endpoint means agent code doesn't need provider-specific SDKs. You write the call once against the standard format and the gateway translates to whatever provider is currently handling the request. Switching providers is a gateway configuration change, not a code change.

## Self-hosted vs managed

Managed gateways (LiteLLM Cloud, OpenRouter, Portkey) handle the infrastructure for you. You get routing, failover, and logging without running anything yourself.

Self-hosted gateways (LiteLLM running locally, a custom proxy) give you:
- Data stays on your infrastructure — no request content leaving your network
- Full control over routing rules and retry logic
- No per-request markup from a third-party service
- Ability to add local models (Ollama, llama.cpp) as first-class routing targets

For agent systems handling sensitive content or running at scale, self-hosted is usually worth the operational overhead.

## The vendor lock-in problem

Without a gateway, every script that calls Claude directly is coupled to Anthropic's API format, pricing, and availability. When Anthropic changes a model name, deprecates an endpoint, or changes pricing tiers, every call site needs updating.

With a gateway, that coupling lives in one place — the gateway configuration. The rest of the codebase treats "the LLM" as an abstraction, not a specific provider. This matters more than it sounds: model selection decisions happen frequently (new model releases, pricing changes, performance benchmarks), and each one shouldn't require a codebase audit.

## Integration with cost tracking

A gateway is a natural integration point for per-call cost tracking. Because every LLM request flows through it, the gateway can:

- Record token counts and calculate cost using live pricing data
- Tag calls with a caller identifier (pipeline name, agent type) for attribution
- Surface per-pipeline spend without instrumenting each script individually

This pairs well with pipeline cost tracking — instead of each script self-reporting API usage, the gateway handles it centrally and consistently.

## Handling overload gracefully

API overload is a recurring failure mode for agent systems running multiple pipelines simultaneously. A gateway can implement graduated responses:

1. **Primary provider overloaded** → retry against secondary provider
2. **All premium providers overloaded** → route to a cheaper fallback model
3. **All providers at limit** → queue the request with backoff rather than failing immediately

Without a gateway, each script has to implement its own overload detection. With a gateway, it's handled once — and the agent code just receives a response or a clean error.

## Related

- [[LLM Cost Comparison Tools]] — tracking per-model pricing to power gateway routing decisions
- [[Pipeline Cost Per Run]] — the cost tracking pattern that gateways centralize
- [[Subscription Token Account Risk]] — why API keys (not subscription tokens) are required for production agent systems
- [[Agent Orchestration Platforms]] — the layer above that dispatches work to agents using the gateway
- [[Overload-Tolerant Event Ledger]] — recording and recovering from API failures the gateway surfaces
