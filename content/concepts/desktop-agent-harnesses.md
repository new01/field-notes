---
title: Desktop Agent Harnesses
description: Open-source desktop applications that wrap CLI-based AI coding agents — Claude Code, Codex, Gemini CLI — adding multi-agent side-by-side views, tool call visualization, integrated terminals, browser panels, and git interfaces on top of agents that were designed for the command line.
tags: [concepts, agents, ux, desktop, tooling, multi-agent, visualization]
---

Desktop agent harnesses are native applications built on top of CLI-based AI coding agents. They take tools like Claude Code and Codex — which are fundamentally terminal-driven — and add a GUI layer that exposes what the agent is doing, enables parallel agent sessions, and integrates the supporting toolchain (terminal, browser, git) into a single workspace.

The category emerged as a response to a specific limitation: powerful agents, poor visibility. Running Claude Code in a terminal gives you the output but loses the context — what tools were called, in what order, with what arguments, and what was returned. Desktop harnesses make that machinery visible.

## What they add over raw CLI

The CLI agents handle the intelligence. The harness handles everything around it:

**Tool call visualization** — displaying each tool invocation (file read, web search, shell command, MCP call) as it happens, with inputs and outputs. This turns an opaque stream of text into an inspectable execution trace. See [[Real-Time Agent Work Visualization]] for the broader pattern.

**Multi-agent side-by-side** — running two or more agent sessions simultaneously in split-pane views. Useful for running the same task with different models, parallelizing independent subtasks, or comparing approaches before committing to one.

**Integrated terminal** — a built-in shell panel so you can run commands, check output, and interact with the system without leaving the application or losing context from the agent window.

**Integrated browser** — an embedded browser for previewing web output, testing apps, and letting vision-capable agents interact with live pages without switching windows.

**Integrated git** — staging, diffing, committing, and reviewing changes without leaving the agent workspace. Particularly valuable since coding agents generate large diffs that benefit from visual diffing tools.

**MCP integration panels** — surfacing the MCP servers connected to the agent, their available tools, and recent call logs.

## Architecture pattern

Most desktop harnesses follow a similar pattern:

1. **Process wrapper** — the harness spawns the CLI agent as a subprocess, capturing its stdin/stdout/stderr
2. **Event parsing** — structured output from the agent (tool calls, status updates, results) is parsed and indexed in real time
3. **State management** — the harness maintains a session model: current task, active files, tool call history, agent status
4. **UI layer** — renders the session state as panels, panes, and interactive visualizations

The underlying agent is unchanged. The harness is a presentation and orchestration layer on top of it.

## Cross-agent support

The more capable harnesses are model-agnostic: they support Claude Code, Codex, Gemini CLI, and other agents through a plugin or adapter system. This allows teams to run a mixed fleet — using the best model for each task — from a single interface.

This maps to the [[LLM Gateway Abstraction]] pattern at the UI level: one interface, many backends.

## Self-hosted vs cloud-hosted variants

Desktop harnesses come in two deployment shapes:

- **Local desktop apps** — Electron or Tauri applications running entirely on the developer's machine. No external dependencies beyond the CLI agent and any MCP servers. Maximum privacy; works offline.
- **Self-hosted web UIs** — a server component that proxies agent communication, with a web frontend accessible from any device including mobile. Enables team access to shared agent sessions and remote work from tablets or phones.

Both variants maintain the core property that the agent itself runs locally or on infrastructure the user controls — differentiating them from cloud-based agent platforms where the agent runs on the provider's servers.

## Relationship to agent observability

Desktop harnesses solve a developer-experience version of the observability problem: making agent behavior legible to the human operating it in real time. They're the interactive counterpart to logging-based observability pipelines, which capture the same events for later analysis.

See [[Agent Debugging Infrastructure]] for how the two approaches complement each other, and [[Real-Time Agent Work Visualization]] for the general architecture of live agent state rendering.

## Related concepts

- [[Real-Time Agent Work Visualization]] — the UI pattern for displaying agent execution state
- [[Agent Orchestration Platforms]] — broader coordination systems for agent fleets
- [[Agent Debugging Infrastructure]] — tooling for diagnosing agent failures
- [[LLM Gateway Abstraction]] — model-agnostic routing at the infrastructure level
- [[Multi-User Agent Instance Management]] — managing agent sessions across users and teams
