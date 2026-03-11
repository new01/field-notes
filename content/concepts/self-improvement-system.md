---
title: Self-Improvement System
description: A feedback loop where the agent tracks its own errors and proposes improvements — the architecture for an agent that compounds over time
tags: [concepts, self-improvement, feedback-loop, openclaw]
---

# Self-Improvement System

An automated feedback loop where the agent tracks its own errors, learns from corrections, and proposes improvements to itself. The difference between an agent that makes the same mistakes forever and one that becomes more capable over time.

Most agents stay static. They do what you built them to do and nothing more. A self-improvement loop makes the agent a collaborator that grows — one that flags its own limitations, proposes fixes, and gets better at being your agent over time.

## The Three Memory Files

The foundation is three persistent files that the agent reads at session start and writes to during and after sessions.

### LEARNINGS.md

Corrections and insights. When you correct the agent or it discovers a better approach, it writes it here. On the next session, it reads this file and doesn't repeat the mistake.

Format:

```markdown
## 2026-03-10
**Correction:** When writing build specs, always include the file paths, not just the task description.
**Context:** ACP session couldn't find the right files without explicit paths in the spec.
**New behavior:** Every build spec includes full absolute paths to all relevant files.
```

This file is the agent's correction log. The key discipline: write it immediately when the correction happens, not at the end of the session when you might forget the details.

### ERRORS.md

Recurring error patterns. Not one-off failures — patterns that show up repeatedly across sessions.

```markdown
## Pattern: Marking tasks done without gate check
**Examples:**
- 2026-03-08: Pipeline audit marked done, no artifacts
- 2026-03-09: Build task "complete", status.json missing
**Rule:** Never mark a queue item done without verifying artifact existence on disk.
**Gate check:** fs.existsSync() on each requiredArtifact before status update.
```

ERRORS.md becomes permanent operating rules. The agent doesn't read it once — it reads it every session, and the entries become behavioral defaults.

### FEATURE_REQUESTS.md

Self-improvement ideas. When the agent notices something it could do better but doesn't have time to fix now, it logs it here. The Innovation Scout reviews this daily.

```markdown
## [proposed] 2026-03-10 — Auto-detect stuck cron jobs
**What:** Check if any cron job hasn't fired in 2x its expected interval. Flag it in morning brief.
**Why:** Two cron jobs silently died this week and weren't noticed for days.
**Priority:** High
**Status:** proposed
```

Status transitions: `proposed` → `accepted` → `in-progress` → `done` or `rejected`.

---

## The Automated Review Loop

### The Innovation Scout

On a daily cron, an Innovation Scout subagent scans the codebase for automation opportunities:
- Repetitive patterns that run manually but could be automated
- Unhandled edge cases in existing scripts
- Things that generate notifications but don't have rate limiting
- Missing gate checks in pipeline stages

It generates improvement proposals and writes them to FEATURE_REQUESTS.md with status `proposed`.

Each proposal goes through an accept/reject loop: you review the new proposals, mark accepted or rejected, and accepted items get added to the build queue for implementation.

The result: the agent proactively identifies work it could be doing. You don't have to think of everything.

### Security and Health Reviews

Periodic review councils run automatically on cron schedules.

#### Security Review

Multi-perspective analysis of external surface area:
- Credential handling — are API keys committed anywhere? Exposed in logs?
- Data exposure risks — what does the agent have access to that it shouldn't?
- External API calls — are inputs validated before they reach external services?
- Channel access — who can message the agent and trigger actions?

#### Platform Health Review

Reliability and integrity checks:
- Which cron jobs haven't fired in their expected window?
- Are there any scripts that consistently error?
- Is disk usage trending toward a problem?
- Test coverage — what has no tests that should?

These aren't one-shot audits. They run on schedule and surface findings as notifications. The findings feed back into FEATURE_REQUESTS.md.

---

## The Compounding Loop

The full loop connects the memory files, the review councils, and the build queue:

```
Session ends
    ↓
Agent writes LEARNINGS.md + ERRORS.md updates
    ↓
Daily: Innovation Scout scans → writes proposed items to FEATURE_REQUESTS.md
Daily: Security Review → findings routed to FEATURE_REQUESTS.md
    ↓
You review proposals: accept or reject
    ↓
Accepted items → build queue
    ↓
Build queue item executed (next session or idle dispatch)
    ↓
Implementation deployed → new behavior in SOUL.md or AGENTS.md
    ↓
Next session: agent reads updated files, behaves differently
    ↓
Repeat
```

### What compounding looks like

**Month 1:** Agent learns your preferences. Stops making corrections you've made three times. LEARNINGS.md has 20-30 entries.

**Month 3:** Innovation Scout has proposed 15+ improvements, 8 implemented. Agent handles edge cases that used to require your intervention. ERRORS.md has surfaced and eliminated 4-5 recurring failure patterns.

**Month 6:** The agent feels like it knows you. It does — 180+ days of corrections, proposals, and refinements. It anticipates preferences in new domains it hasn't been explicitly trained on, because the pattern of your preferences has been established across enough surface area.

This is a long-term investment. The first month you won't notice much. Six months in, the agent has accumulated dozens of corrections and learned to avoid mistakes that would have cost you an hour each.

---

## Connecting to Continuous Ingestion

The self-improvement system works better when it's connected to external information sources. The Innovation Scout can reference what's happening in the field — new patterns, new tools, better approaches — and propose improvements that reflect current best practice rather than just the agent's own blind spots.

Wire in information sources via [[concepts/continuous-ingestion|Continuous Information Ingestion]]: HN Algolia API, GitHub RSS for frameworks you use, YouTube channels from practitioners. High-scoring ingested items feed into FEATURE_REQUESTS.md as inspiration for proposals.

---

## Connecting to the Heartbeat

The review loops (Innovation Scout, Security Review, Platform Health Review) run as Phase 2 heartbeat tasks or dedicated cron jobs. See [[concepts/heartbeat-system|The Heartbeat System]] for the execution model.

The key: these reviews don't run inline in the main session. They spawn as separate sessions with minimal context — just the task definition and the files to review. This keeps the main session unblocked and keeps the review output clean.

---

## Connecting to the Build Queue

Accepted FEATURE_REQUESTS.md items go into the [[concepts/build-queue-pattern|Build Queue Pattern]]. They're real build tasks with specs, priority, and gate checks — not vague improvement ideas. The spec for an accepted proposal should include:

- What exactly to change (file paths, function names, behavior)
- What the success condition looks like
- What artifacts need to exist when done

Without this specificity, the improvement stays as "proposed" until you add detail. The proposal loop only converts ideas into real work when the spec is clear enough to execute.

---

## Related

- [[concepts/agent-memory|Agent Memory]] — the memory files this system writes to and reads from
- [[concepts/heartbeat-system|Heartbeat System]] — how the automated reviews run as scheduled tasks
- [[concepts/build-queue-pattern|Build Queue Pattern]] — where accepted proposals get queued for implementation
- [[infrastructure/ai-advisory-board|AI Advisory Board]] — decision gate before accepting any proposed improvement
