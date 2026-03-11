---
title: Code Review Feedback Loops
description: Automated systems where agents generate code and human reviewers (or other agents) provide structured feedback to improve output quality and consistency over time
tags: [concepts, quality, architecture, agents, code]
---

Automated systems where agents generate code and human reviewers — or other agents — provide structured feedback that feeds back into future generations. The goal is progressive improvement: each review cycle tightens the output, and patterns from reviews compound over time into better defaults.

## Why this matters for agent systems

When a single agent writes code autonomously, quality degrades silently. There's no forcing function. Bugs accumulate, patterns drift, and inconsistencies multiply across files — often undetected until something breaks in production.

A feedback loop changes the dynamic. Review creates a correction signal that the next generation cycle can act on. Over multiple iterations, the loop filters out recurring failure modes and reinforces patterns that work.

## The basic loop

```
Generate → Review → Feedback → Refine → Generate (improved)
```

Each stage has a distinct role:

1. **Generate** — agent produces code from a spec or prompt
2. **Review** — human or reviewer agent evaluates against defined criteria (correctness, style, error handling, test coverage)
3. **Feedback** — structured notes capture what failed and why, not just what to fix
4. **Refine** — original or successor agent applies corrections
5. **Loop** — refined output becomes the baseline for the next generation

The key word is *structured*. Unstructured feedback ("this looks messy") doesn't improve future generations. Structured feedback ("missing try/catch on the database call at line 34 — all DB operations need error handling") creates a reusable signal.

## Human vs agent review

Both have distinct roles:

**Human review** catches:
- Requirement mismatches (agent solved the wrong problem)
- Security and trust issues (agent didn't know the threat model)
- Architectural concerns (the code works but doesn't fit the broader system)
- Judgment calls that require domain expertise

**Agent review** catches:
- Syntax and lint violations
- Missing test coverage
- Style guide deviations
- Repetitive patterns that should be abstracted
- Missing error handling on common failure modes

In practice, agent review handles the mechanical layer continuously, and human review handles the judgment layer periodically. This keeps human attention on decisions that actually require it.

## What makes feedback loops effective

**Feedback must be actionable.** Notes that say "improve readability" don't improve readability. Notes that say "function exceeds 40 lines — extract the validation block into a named helper" do.

**Feedback must be captured, not just communicated.** Verbal code review that doesn't get written down produces zero improvement in future agents. The review artifact is the product — not the conversation.

**Loops need a closing mechanism.** An open feedback loop that never closes is just a backlog. Each review cycle needs a defined endpoint: either the change is merged and the feedback is absorbed, or the item is explicitly deferred with a reason.

**Short loops outperform long ones.** Weekly code review that catches 50 issues at once is worse than daily review that catches 5. Smaller batches produce more precise feedback and shorter fix cycles.

## Pattern: reviewer agent as a gate

A common implementation wraps the reviewer agent as a quality gate in the pipeline:

```
Agent writes code
  → Reviewer agent checks against checklist
    → If passes: commit and continue
    → If fails: return feedback to generating agent
      → Generating agent revises (one retry)
        → Human review for anything still failing
```

The gate has a defined pass criteria, not a fuzzy quality threshold. This keeps it deterministic and auditable.

## Pattern: feedback library

Recurring feedback patterns get collected into a shared library:

```json
{
  "missing-error-handling": "All async calls need try/catch. Unhandled rejections crash the process.",
  "hardcoded-paths": "Use env vars or config constants. No hardcoded file paths in source.",
  "oversized-functions": "Functions over 40 lines need to be decomposed."
}
```

When a reviewer identifies a pattern match, they reference the library ID rather than re-explaining the issue. This creates a shared vocabulary and makes patterns visible as they accumulate.

The library also serves as training signal — agents can be prompted with the top 10 patterns before generation to proactively avoid them.

## Feedback loops vs self-review

[[Agent Self-Review Loop]] and code review feedback loops are complementary, not competing:

- **Self-review** catches issues before anything leaves the agent (one pass, immediate)
- **Code review feedback loops** catch issues the agent couldn't catch itself, and improve future generations (multi-pass, cumulative)

Self-review filters the output. Code review improves the generator.

## Related

- [[Agent Self-Review Loop]] — the intra-agent quality check that runs before code review
- [[Agent Debugging Infrastructure]] — tools for inspecting what the agent actually did when reviews surface unexpected behavior
- [[Input Validation in Skills]] — pre-flight validation that prevents obvious errors before the generate-review loop starts
- [[Graph Orchestration Patterns]] — the pipeline context in which review gates typically operate
- [[Skill-Based Agent Architecture]] — how review patterns can be packaged as reusable skills
- [[Agent Orchestration Platforms]] — managing multi-agent review workflows at scale
