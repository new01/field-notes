---
title: Claude Code MCP Headless Regression
description: Cloud MCP connectors configured at claude.ai silently fail to load when Claude Code runs in headless or subprocess mode — a recurring bug pattern that creates a dangerous discrepancy between interactive and automated agent sessions.
tags: [concepts, mcp, claude-code, headless, agent-tooling, bugs, regression]
---

Claude Code supports cloud MCP connectors — tools configured at claude.ai/settings/connectors that are synced to your Claude Code sessions automatically. In interactive (TUI) mode, these work. In headless mode (`claude -p`, or launched via `subprocess.run` from Python), they silently fail to load.

This is a recurring failure pattern across multiple Claude Code versions, most clearly documented in v2.1.72 but present in adjacent versions. As of v2.1.79/2.1.80, no fix has been confirmed.

## What cloud MCP connectors are

Claude.ai allows users to connect external services — GitHub, Notion, Atlassian, DeepWiki, Gmail, and others — as MCP servers from the web UI at claude.ai/settings/connectors. Claude Code is supposed to pick these up automatically by fetching them from `https://api.anthropic.com/v1/mcp_servers` at startup using your OAuth token.

This is separate from MCP servers you configure locally in `~/.claude.json` or via `claude mcp add`. Cloud connectors come from the cloud; local servers come from disk.

## The failure mode

When Claude Code runs headlessly, the cloud connector fetch silently fails:

- Gate check (`tengu_claudeai_mcp_connectors`) passes ✓
- OAuth token with `user:mcp_servers` scope is valid ✓
- Manual curl to the same API endpoint returns the connectors successfully ✓
- Claude Code internal fetch: **fails silently**

The internal binary contains log messages including `[claudeai-mcp] Fetch failed`. Nothing surfaces to the user. The session starts normally, but with zero cloud connectors available. Only local MCP servers appear in `/mcp`.

This was diagnosed in depth in GitHub issue #32955 (v2.1.72). The reporter extracted internal log messages from the binary via `strings`, confirmed every prerequisite passes, and demonstrated the same token works in manual curl but not inside Claude Code.

## Why headless mode is different

Interactive sessions have more slack at startup — the UI loads asynchronously, auth can be re-prompted, and partial failures are recoverable. Headless sessions don't have this:

- When spawned as a subprocess (e.g., Python's `subprocess.run`), the process may start before keychain token retrieval completes — creating a race condition where the connector fetch starts with no valid token
- The fetch may omit the required `anthropic-beta: mcp-servers-2025-12-04` header internally
- Without a UI, there's no mechanism to surface the failure or retry

The result: cloud connectors work in the REPL but disappear when the same setup runs in automation.

## Related failure patterns

The cloud connector subsystem has several related bugs open simultaneously:

**OAuth prompts on every headless session start** (issue #31618): Disconnected Atlassian connectors keep triggering browser OAuth prompts even after the connector is fully removed and the auth cache is cleared. The `~/.claude/mcp-needs-auth-cache.json` repopulates automatically on each session. For headless agents, this means unexpected browser windows opening on the host machine.

**Auth lost after context compaction** (issue #34832): Cowork MCP connectors lose their auth state when the session undergoes context compaction — not just on server restart. The Cowork VM's cached session state is dropped and never re-established. Agents running long sessions discover their tools have silently become unavailable mid-task.

**Headless mode ignores locally-configured MCP servers** (older, Reddit): Even with locally-configured MCP servers, Claude Code in `-p` mode doesn't pass the tools to the model even when the server is running and connected. A different failure surface but the same general pattern: headless sessions lose access to MCP tools that work fine interactively.

## Why this matters for agent workflows

Headless Claude Code is the dominant pattern for automation:

- CI/CD pipelines that invoke `claude -p` for code review, PR generation, or analysis
- Python orchestrators that spawn Claude Code as a subprocess
- Scheduled agent tasks run without a human at the terminal
- Multi-agent systems where Claude Code is a worker node

In all of these, cloud MCP connectors are simply unavailable — not because they're not configured, not because the user lacks permissions, but because of a startup timing/fetch issue. Worse: the failure is invisible. The agent doesn't know it's missing tools. It proceeds, produces output, and the difference only shows up in what it couldn't do.

## Versioning notes

- v2.1.79 fixed `claude -p` hanging when spawned as a subprocess without explicit stdin — directly adjacent, but not the connector fetch failure
- v2.1.77 improved headless mode plugin installation — also adjacent
- No changelog entry in 2.1.79 or 2.1.80 addresses cloud MCP connector loading in headless mode

The fixes in this window suggest Anthropic is aware of headless mode reliability issues broadly, but the cloud connector subsystem appears to be a separate path that hasn't been addressed.

## Workaround

Until a fix ships, the reliable approach is to duplicate cloud connectors locally:

1. Find the server URLs from a working interactive session via `/mcp`
2. Add them as local MCP servers: `claude mcp add <name> --url <url>`
3. Local servers load from `~/.claude.json` directly and aren't subject to the startup fetch race

This loses the convenience of the claude.ai connector sync, but gives headless agents consistent tool access.

## Related

- [[concepts/mcp-protocol-adoption|MCP Protocol Adoption]] — the broader context of why MCP connector reliability matters
- [[concepts/agent-last-mile-failure|Agent Last-Mile Failure]] — the pattern of agents failing at the edges of execution, not in core logic
- [[concepts/agent-debugging-infrastructure|Agent Debugging Infrastructure]] — why silent failures in agent infrastructure are particularly costly

## Sources

GitHub issue #32955: Claude.ai MCP servers not loading in v2.1.72 (March 2026). GitHub issue #31618: Disconnected cloud MCP connectors triggering OAuth prompts (March 2026). GitHub issue #34832: Cowork MCP connectors losing auth after compaction (March 2026). Reddit r/ClaudeAI: Headless Claude Code with MCP (March 2025). Claude Code changelog (code.claude.com/docs/en/changelog). Research date: 2026-03-19.
