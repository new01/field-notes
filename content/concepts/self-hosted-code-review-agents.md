---
title: Self-Hosted Code Review Agents
description: Background daemons that run AI-powered pull request review locally — polling for open PRs, running tests, invoking LLM CLIs, and posting structured inline comments — without per-PR cloud API costs.
tags: [concepts, code-review, agents, local-first, ci, open-source, model-agnostic]
---

Self-hosted code review agents are background daemons that automate AI-driven pull request review on your own infrastructure. Instead of paying a cloud service per review, the agent polls your version control system, feeds context into a locally-installed LLM CLI (Claude, Gemini, Codex), and posts structured inline and summary comments back to the PR via API.

The concept combines the output quality of frontier LLMs with the cost and privacy profile of local execution.

## Why it matters

Cloud-based AI code review services typically price at $15–$25 per PR. For teams shipping 10+ PRs daily, that scales into thousands of dollars per month — and the cost structure creates pressure to review less, not more.

Self-hosted agents break the per-review billing model. The only compute cost is the local machine or VPS running the daemon, and the LLM usage is absorbed by developer subscriptions already in place.

Beyond cost, local execution gives teams control over what models run, what tools they can invoke, and what context is sent out of the building.

## How it works

A self-hosted review agent typically follows this pipeline:

1. **Polling** — the daemon periodically checks GitHub, GitLab, or Bitbucket for open or updated PRs
2. **Worktree creation** — creates a near-instant git worktree for the branch (no re-cloning)
3. **Pre-review execution** — optionally runs tests, linters, or build commands; the stdout/stderr becomes part of the AI context
4. **LLM invocation** — pipes the diff, test output, and instructions into the installed CLI; structured JSON output is requested
5. **Comment posting** — parses the output and posts inline file-level and PR-level summary comments via the VCS API
6. **State tracking** — uses a local database (e.g., SQLite in WAL mode) to track which PRs have been reviewed, preventing double-posting

The daemon runs headlessly, is systemd-compatible, and requires no TTY — deployable on a developer workstation or lightweight VPS.

## The echo chamber problem

A technically compelling argument for self-hosted review is model diversity. When developers use Claude to write code and Claude to review it, the reviewer inherits the same blind spots as the author — it's grading its own homework.

Self-hosted agents are typically model-agnostic: you configure which CLI handles each stage. Writing with one model and reviewing with a different one (Gemini reviewing Claude-generated code, for example) produces genuinely independent analysis. This is structurally similar to pair programming with two developers who have different training backgrounds.

See also: [[Agent Self-Review Loop]] for how single-model review loops surface this limitation.

## Comparison with cloud review services

| Dimension | Self-Hosted | Cloud Service |
|---|---|---|
| Cost model | Fixed infra + existing subscriptions | Per-PR fee ($15–$25) |
| Model control | Any installed CLI | Provider's model |
| Data residency | Your infrastructure | Provider's cloud |
| Setup overhead | High (daemon, config, deploy) | Low (GitHub App install) |
| Scalability | Linear with infra | Instant, metered |
| Model diversity | Configurable per-project | Fixed offering |

The tradeoff is operational overhead for cost control and flexibility. Teams with high PR volume and existing DevOps capacity tend to find the break-even point quickly.

## Sandboxing and safety

Running LLM CLIs locally introduces tool-use risk. Self-hosted agents typically configure CLIs with restricted tool permissions — for example, Claude's `--disallowedTools Write,Edit` flag prevents the review agent from making file system changes. The agent reads diffs and posts comments; it does not modify code.

This maps to the broader [[Deterministic Agent Action Layer]] pattern: separating read-only analysis agents from write-capable execution agents.

See also: [[Agent Sandboxing Environments]] for the general architecture.

## Infrastructure patterns

Self-hosted review agents typically deploy as:

- **Local daemon** — running on a developer machine, useful for small teams or personal use
- **VPS daemon** — lightweight VM (1–2 vCPUs) running continuously; shared by a whole engineering team
- **CI-triggered** — invoked as a step in an existing CI pipeline, skipping the polling layer

For cost breakdown and overhead modeling, see [[Pipeline Cost Per Run]].

## Related concepts

- [[Code Review Feedback Loops]] — how review outputs feed back into agent behavior over time
- [[Local-First AI Infrastructure]] — the broader architectural philosophy
- [[Agent Self-Review Loop]] — limitations of single-model review cycles
- [[LLM Gateway Abstraction]] — model-agnostic routing patterns
- [[Build Queue Pattern]] — polling and state-tracking approaches for background agents
