---
title: Agentic Error Recovery Loops
description: CLI wrappers and orchestration patterns that automatically feed execution failures — test errors, build failures, lint output — back into a coding agent, enabling self-correction without human intervention.
tags: [concepts, agents, coding, self-correction, automation, feedback-loop, cli]
---

Agentic error recovery loops are the wrapper layer between a coding agent and its execution environment. When the agent produces code that fails — tests don't pass, the build breaks, a linter fires — the loop captures that output and re-invokes the agent with the failure context, asking it to diagnose and fix its own mistake. The human never has to manually relay the error.

This pattern transforms one-shot coding agents into iterative correction machines. It's a structural solution to one of the most common frustrations with AI coding tools: the agent makes an error, stops, and waits for you to copy the error message back to it.

## Why it matters

Coding agents fail at a predictable rate. Tests fail. Types don't match. An import is missing. These aren't deep reasoning failures — they're mechanical errors the agent can usually fix immediately given the error output. But without a loop, each failure requires human intervention: copy the error, paste it back, say "fix this."

Recovery loops eliminate that overhead. They run automatically, compressing multiple correction rounds into a single unattended session. The developer returns to working code, not a stuck agent.

## How it works

A basic recovery loop follows this structure:

1. **Invoke agent** — pass the task, relevant files, and any prior context
2. **Execute output** — run the tests, build, or lint command on the generated code
3. **Check result** — if exit code is 0 / all tests pass: done. If not: capture stdout/stderr
4. **Re-invoke** — pass the failure output back to the agent with an instruction to fix it
5. **Repeat** — up to a configured maximum iteration count or until success

The loop can be as simple as a shell script or as sophisticated as a stateful daemon that tracks iteration history, applies exponential backoff, and escalates to a human after N failed attempts.

## Trigger conditions

Recovery loops activate on:

- **Test failures** — `pytest`, `jest`, `go test` etc. returning non-zero
- **Build errors** — compilation failures, type errors, missing dependencies
- **Lint violations** — when the codebase enforces lint-clean commits
- **Runtime panics** — crashing the running service during integration tests
- **Custom checks** — project-specific validation scripts

The key is that the error signal is machine-readable. The loop doesn't need to understand the error — it just needs to capture it and pass it back.

## Iteration limits and escape hatches

Without a ceiling, a recovery loop can spin indefinitely on a problem the agent can't solve. Robust implementations include:

- **Max iterations** — stop after N attempts (3–5 is typical; more introduces diminishing returns)
- **Novelty check** — if the agent produces the same output twice, break the loop early
- **Escalation** — after exhausting retries, surface the failure to a human with the full iteration log
- **Timeout** — wall-clock limit to prevent runaway sessions

See also: [[Dead Man's Switch]] for timeout-based escalation patterns.

## Variants

**Test-driven recovery** — the most common form. Write failing tests first, then let the agent attempt to make them pass across multiple iterations. The test suite is the oracle.

**Diff-gated recovery** — only re-invoke if the agent's output is meaningfully different from the previous attempt. Prevents looping on equivalent-but-still-broken code.

**Context-expanding recovery** — each iteration adds more context (stack traces, related file contents, previous attempts) to help the agent converge. Effective but expensive in tokens.

**Multi-model recovery** — on repeated failure, switch to a different model for the re-attempt. If Claude generated the broken code, let Gemini or Codex try to fix it. Structurally similar to the echo chamber mitigation in [[Self-Hosted Code Review Agents]].

## Relationship to other patterns

Recovery loops are a specialized form of [[Agent Self-Review Loop]] — but where self-review has the agent check its own work before submitting, recovery loops respond to external, objective execution failures rather than the agent's own assessment.

They're also closely related to [[Self-Improvement System]] — the difference is scope. Self-improvement tracks errors across sessions and proposes architectural changes to the agent itself. Recovery loops operate within a single task, fixing tactical code-level mistakes in real time.

## Failure modes

- **Hallucinated fixes** — the agent claims to fix the error but changes unrelated code, masking the failure in a way that breaks something else
- **Context pollution** — accumulating iteration history inflates the prompt until the agent loses track of the original task
- **False convergence** — tests pass but the implementation is incorrect; the loop succeeds but delivers wrong behavior

Mitigation: run a broader test suite on final convergence, not just the failing tests from the last iteration.

## Related concepts

- [[Agent Self-Review Loop]] — pre-submission quality checks by the agent itself
- [[Self-Improvement System]] — cross-session error tracking and architectural adaptation
- [[Self-Hosted Code Review Agents]] — post-merge verification by a separate review agent
- [[Code Review Feedback Loops]] — how review signals compound into better agent defaults over time
- [[Deterministic Agent Action Layer]] — separating read/analyze from write/execute in agent pipelines
