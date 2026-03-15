---
title: MCP Security Gateways
description: Proxy layers that intercept every JSON-RPC message between AI agents and MCP servers, enforcing authentication, authorization, injection detection, and audit logging without modifying either side.
tags: [concepts, security, mcp, agents, infrastructure, proxy, runtime]
---

MCP security gateways are transparent proxy layers that sit between AI agents and the MCP servers exposing their tools. Every JSON-RPC message — tool calls, responses, schema definitions — passes through the gateway before reaching either side. The gateway enforces policy without requiring changes to the agent or the tool server.

The pattern emerged from a structural gap in the MCP ecosystem: agents are gaining access to powerful tools (file systems, databases, external APIs, code execution), and MCP is the protocol wiring them together, but there is no built-in security enforcement layer in the protocol itself.

## Why the gap exists

MCP was designed as a connectivity standard, not a security standard. It defines how agents discover and invoke tools — not who is allowed to call what, under what conditions, or what constitutes a suspicious invocation pattern.

As enterprise deployments scaled, the absence of centralized policy enforcement created three compounding problems:

1. **No default-deny posture** — any connected agent can invoke any exposed tool by default
2. **No injection surface monitoring** — tool arguments are trusted input; prompt injection via tool responses goes undetected
3. **No tamper-evident audit trail** — logging, when present, is an afterthought in individual server implementations

Gateways solve all three at the transport layer, applying controls uniformly regardless of which agent or which MCP server is involved.

## Core capabilities

### Policy engine
Rules defined in configuration (commonly TOML) determine which identities can invoke which tools, under what conditions. Effective implementations support time-window filtering (block file writes after hours), day-of-week rules, and hot-reload — policy changes apply without restarting the gateway.

The default posture is deny-unless-permitted, inverting the MCP default of permit-unless-blocked.

### Injection detection
Tool call arguments and tool responses are scanned for prompt injection patterns before passing through. This includes:
- Regex pattern matching with Unicode normalization (NFKC, homoglyph transliteration, zero-width character stripping)
- Recursive scanning of nested JSON structures
- Heuristic analysis: entropy scoring, Base64 detection, suspicious length thresholds

A tool response can instruct an agent to take harmful actions — the gateway intercepts before the agent processes it.

### Schema pinning
Tool definitions (the schemas describing what each tool accepts and returns) are hashed on first contact. Subsequent connections verify the hash. A changed schema — whether from a compromised server, a "rug pull," or tool shadowing — triggers a block and alert.

This closes the tool shadowing attack vector, where a malicious MCP server presents a different tool interface than the one the agent was designed to use.

### Audit logging
Hash-chained NDJSON logs provide tamper-evident records of every intercepted message. Each log entry includes a SHA-256 link to the previous entry, making retroactive log modification detectable. Full inbound and outbound coverage means both the agent's requests and the server's responses are recorded.

### Rate limiting
Token-bucket rate limits apply at three levels: globally, per-identity, and per-tool. This prevents runaway agents from burning through API quotas or causing unintended side effects at scale.

## The credential scope problem

A gateway controls what tool calls are permitted — but not what credentials the MCP server uses to fulfill them. A tool call can pass every gateway rule cleanly, and the server still executes it using a broad-permission API key.

This is a known limitation of transport-layer security: if a compromised tool is authorized to call an endpoint, the gateway cannot stop it. The complementary solution is scope enforcement at the credential level — each agent gets credentials valid only for its specific operations, with short TTLs so extracted keys go stale quickly.

MCP security gateways and scoped credential systems are complementary, not substitutes.

## Deployment topology

```
┌──────────┐    ┌─────────┐    ┌────────────┐
│ AI Agent │───>│ Gateway │───>│ MCP Server │
│ (Client) │<───│ (Proxy) │<───│  (Tools)   │
└──────────┘    └────┬────┘    └────────────┘
                     │
                ┌────┴────┐
                │ Policy  │
                │  TOML   │
                └─────────┘
```

The gateway is transparent — agents and servers communicate using standard MCP protocol on both sides. No code changes required to either.

## Relation to broader agent security

MCP security gateways address the tool-call surface specifically. They complement but do not replace:

- **[[Runtime Control Layer]]** — broader middleware that governs agent actions beyond MCP tool calls
- **[[AI Pipeline Security Layers]]** — upstream PII detection, firewall rules, and compliance monitoring
- **[[Agent Sandboxing Environments]]** — OS-level isolation for agents executing code or accessing the file system
- **[[LLM Gateway Abstraction]]** — model-layer routing and access control, orthogonal to tool-call security
- **[[Deterministic Agent Action Layer]]** — pre-execution validation of agent intent before any tool is invoked

A mature agent security posture applies controls at multiple layers: prompt ingress, model routing, tool call authorization, credential scope, and execution environment.
