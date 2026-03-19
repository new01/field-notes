---
title: OpenClaw 2026.3.11 — Security Depth, Multimodal Memory, and ACP Session Continuity
description: A review of the 2026.3.11 release — notable for layered security hardening across privilege separation, sandbox integrity, and auth boundaries, plus multimodal memory indexing and ACP session resumption.
tags: [concepts, openclaw, security, memory, acp, agents, release]
---

OpenClaw 2026.3.11 is a broad release, but three themes stand out as architecturally significant: a major sweep of privilege-separation hardening across the agent runtime, multimodal memory indexing via Gemini embeddings, and improved continuity for ACP-based coding agent sessions. Each of these reflects a pattern worth understanding beyond the specific fixes.

## Security: privilege separation as a first-class concern

The most striking thing about this release is how many distinct privilege boundaries it tightens simultaneously. This is not a single CVE with a patch — it's a coordinated hardening of the entire trust model. Understanding where the attack surfaces were reveals something important about how agent platforms need to think about security differently from traditional web services.

**Cross-site WebSocket hijacking (GHSA-5wcw-8jjv-m286)** — gateway browser WebSocket connections now enforce origin validation unconditionally, including when trusted-proxy headers are present. The exploit path was that proxy-mode configurations could be tricked into granting `operator.admin` access to an origin that never should have had it. WebSocket connections don't follow CORS semantics the same way HTTP requests do, so browser-originated gateway connections need their own origin check that can't be bypassed by injecting proxy headers.

**Subagent authority escalation** — leaf sessions (spawned subagents that don't orchestrate further) now have their control scope persisted at spawn time. Previously, a leaf session could potentially regain orchestration privileges after restore or through flat-key lookups. Orchestration authority is now locked at creation, not re-derived on each operation.

**Session reset privilege path** — conversation `/new` and `/reset` handling was separated from the admin-only `sessions.reset` control-plane RPC. Write-scoped gateway callers could previously reach the privileged reset path through the agent. This is a classic confused-deputy pattern: an API endpoint that accepts lower-privilege credentials was forwarding to a higher-privilege backend without re-checking authority at the boundary.

**Plugin admin scope inheritance** — unauthenticated plugin HTTP routes were inheriting synthetic admin gateway scopes when calling `runtime.subagent.*`. This meant admin-only methods like `sessions.delete` were reachable without authentication through the plugin route. The fix blocks admin scope inheritance for unauthenticated callers.

**`session_status` sandbox visibility** — sandboxed subagents could previously inspect parent session metadata or write parent model overrides through `session_status`. Session tree visibility now enforces sandbox boundaries before reading or mutating target session state.

**SecretRef exec traversal** — `exec` SecretRef traversal IDs are now rejected across schema, runtime, and gateway. This blocked a path where a SecretRef could be used to traverse into exec-backed secrets that should have been inaccessible.

**Sandbox filesystem bridge** — staged writes are now pinned to verified parent directories, preventing temporary write files from materializing outside the allowed mount before atomic replacement.

**Archive extraction escapes** — TAR and `tar.bz2` installs now extract into a staging directory first and merge into the canonical destination with safe file opens, blocking destination symlink and pre-existing child-symlink escape paths.

**Auth fail-closed** — when local `gateway.auth.*` SecretRefs are configured but unavailable, the gateway now fails closed instead of silently falling back to `gateway.remote.*` credentials. This is a particularly important change: systems that silently degrade to weaker security are much harder to reason about than ones that fail loudly.

**`system.run` file binding** — approval-backed interpreter and runtime commands now fail closed when OpenClaw cannot bind exactly one concrete local file operand. A fuzzy or ambiguous file match could previously cause the wrong file to be executed under an approval that was granted for something else.

**Config write scoping** — `/config` and allowlist edits now enforce `configWrites` against both the originating account and the targeted account scope, blocking sibling-account mutations.

**Nodes tool access** — the `nodes` agent tool is now treated as owner-only fallback policy, blocking non-owner senders from reaching paired-node approval or invoke paths.

**External content boundary bypass** — whitespace-delimited `EXTERNAL UNTRUSTED CONTENT` boundary markers are now treated equivalently to underscore-delimited variants. Prompt injection attempts that used whitespace in the markers to bypass sanitization no longer work.

The pattern here is *defense in depth with explicit boundary enforcement at each trust transition*. Every place where authority is delegated — from user to agent, from agent to subagent, from subagent to tool, from plugin to runtime — is now a place where authority is re-checked, not assumed. Each fix in isolation looks minor; collectively they describe a security philosophy.

## Multimodal memory indexing

Memory in agent systems has mostly meant text — conversation history, notes, documents. This release adds opt-in image and audio indexing for `memorySearch.extraPaths` using Gemini's `gemini-embedding-2-preview` model. The implications are worth thinking through.

**What it enables** — agents with access to a photo library, screenshot folder, or audio recording directory can now include those in their semantic memory search. A query for "the diagram we discussed" can surface an image. A query about a past meeting can surface an audio recording.

**How it works** — the implementation uses Gemini's multimodal embedding model to generate semantic vectors for images and audio files, alongside text. Those vectors live in the same index as text embeddings, so a single `memorySearch` call returns relevant results across modalities. Scope-based reindexing means the index stays current as new files appear.

**The gating** — multimodal indexing is opt-in and requires explicit configuration of `memorySearch.extraPaths`, plus strict fallback gating that prevents the system from silently failing when the embedding model is unavailable. Configurable output dimensions allow tuning for storage and recall tradeoffs.

This is a meaningful expansion of what "agent memory" can contain. Most agents today can recall text they've processed; multimodal memory means they can recall what they've seen and heard.

## ACP session continuity

The Agent Communication Protocol (ACP) improvements in this release address a chronic friction point: sessions that should be continuations keep starting fresh. The `sessions_spawn` command now accepts an optional `resumeSessionId` for `runtime: "acp"`, letting spawned sessions resume an existing ACPX or Codex conversation instead of always creating a new one.

Supporting improvements make this work properly in practice:

- Session restore replays stored user and assistant text on `loadSession`, so IDE clients restore context faithfully rather than seeing a blank slate
- Tool call and tool call update events are enriched with best-effort text content and file-location hints, so IDE clients can follow tool activity without opaque streaming events
- Inbound image attachments are forwarded through normalized runtime turns, preserving image prompt content in ACPX sessions
- ACP main sessions now canonicalize before lookup, so restarted sessions rehydrate instead of failing with "Session is not ACP-enabled: main"
- The implicit parent-streaming behavior for `mode="run"` spawns is restored for eligible subagent orchestrator sessions

The cumulative effect is that coding agents (Codex, Claude Code) connected via ACP can maintain meaningful session state across spawns, reconnections, and IDE restarts — which makes long-running background coding tasks substantially more reliable.

## Other notable changes

**Ollama onboarding** — first-class Ollama setup with Local and Cloud + Local modes, browser-based cloud sign-in, and curated model suggestions. Local model setups previously required manual configuration.

**OpenCode Go provider** — new OpenCode Go provider with wizard/docs treatment aligned with the existing Zen provider, sharing a single key for both profiles.

**iOS home canvas** — bundled welcome screen with a live agent overview that refreshes on connect, reconnect, and foreground return. Floating controls replaced by a docked toolbar.

**macOS chat model picker** — explicit thinking-level selections now persist across relaunch.

**Cron isolation (breaking)** — cron jobs can no longer notify through ad hoc agent sends or fallback main-session summaries. A `openclaw doctor --fix` migration handles legacy cron storage.

**Agent fallback observability** — structured, sanitized lifecycle and failover events make provider failures and model fallback decisions easier to trace in logs.

---

The security sweep in 2026.3.11 is the headline. But the multimodal memory work and ACP session continuity represent equally meaningful expansions of what agents can do and how reliably they can do it over time. The combination points toward agent systems that are simultaneously more capable and more defensible — which is the right direction.
