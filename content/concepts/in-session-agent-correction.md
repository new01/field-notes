---
title: In-Session Agent Correction
description: A pattern where a background review daemon hooks into an agent's stop event, critiques the just-written code, and feeds findings back to the same agent session on the next turn — enabling autonomous self-correction while the agent still holds full context.
tags: [concepts, agents, quality, code-review, hooks, self-correction, autonomous]
---

In-session agent correction is a quality loop where an agent reviews and fixes its own work without human input — by keeping the feedback cycle inside a single session, while the agent still knows exactly why it made each decision.

The key insight is timing: most AI code review happens *after* the agent session closes, when a human spots the problem in review. At that point, the agent has lost its reasoning context and must re-derive it from scratch. In-session correction closes the loop while context is still hot.

## The problem with post-session review

AI coding agents ship code quickly. They also introduce subtle issues — logic errors, security gaps, dead code, quiet regressions — that aren't always obvious during generation but surface during human review.

The typical workflow:
1. Agent writes code, session closes
2. Human reviews, catches a problem
3. Human reopens a new session, describes the problem
4. Agent re-examines the code with no memory of why it wrote it that way

Step 4 is inefficient. The agent is starting fresh, without the reasoning trace that led to the original decisions. It may re-introduce the same pattern, apply a surface-level fix, or miss the real issue.

## The in-session correction pattern

Instead of deferring review to the human, a background daemon monitors agent output and injects critique back into the live session:

```
Agent writes code
  └─▶ Stop hook fires → background review daemon activates
        └─▶ Critique generated (bugs, security, regressions, dead code)
              └─▶ Findings injected into next agent turn
                    └─▶ Agent: "I see issues with my approach" → self-corrects
                          └─▶ Human never types anything
```

The agent's response to its own critique is natural reasoning — not a mechanical patch. Because it still has the original context, it can evaluate whether each finding is legitimate, what trade-off it was making, and how to fix it correctly.

## How stop hooks enable this

Modern AI coding agents expose lifecycle hooks — callbacks that fire at defined points in the session (tool use, turn completion, stop). A background daemon can register as a stop hook listener:

- After each agent turn, the hook fires
- The daemon analyzes the files changed in that turn
- Findings are formatted and returned as the next user-side message
- The agent processes them on its next turn without any human interaction

This is non-blocking: the user sees nothing while the daemon runs. On the next prompt (or as an automatic continuation), findings appear and the agent responds.

## Rules engine for precision

The base behavior — reviewing like a senior engineer for general quality issues — works out of the box with no configuration. A rules engine layer adds team-specific precision:

- Rules are markdown files with YAML frontmatter specifying scope (file globs, language, project area)
- Examples: "never use eval() in `src/api/**`", "all database queries must use parameterized statements in `*.sql`"
- Rules load selectively per file (similar to [[Dynamic Rule Loading]]), not as a global payload

This lets teams enforce project-specific invariants that generic review would miss.

## Relationship to other self-review patterns

[[Agent Self-Review Loop]] describes a simpler checklist-based approach where the agent scores its own output against explicit criteria. In-session correction differs in two ways:

1. **External critique source** — a separate daemon performs the review, using different heuristics than the agent used during generation; avoids the echo-chamber problem
2. **Context preservation** — by staying in the same session, the agent can reason about *why* it made decisions, not just *what* to patch

Both patterns share the one-retry discipline: self-correction loops that run indefinitely tend to over-optimize for the reviewer rather than the actual goal. Correction should happen once, cleanly.

## Deployment model

- Daemon runs as a background process on the developer's machine
- Self-spawning: activates on demand when an agent session starts
- Auto-shutdown after a configurable idle period (default: 30 minutes)
- Uses the developer's existing LLM subscription — no additional API key
- All review happens locally; no code sent to external services

## Related concepts

- [[Agent Self-Review Loop]] — checklist-based single-agent review without external daemon
- [[Code Review Feedback Loops]] — how review findings improve agent behavior over time
- [[Self-Hosted Code Review Agents]] — PR-level review daemons for post-session quality gates
- [[Dynamic Rule Loading]] — selective rule injection to keep context focused
- [[Deterministic Agent Action Layer]] — separating review from execution for safety
