---
title: Input Validation in Skills
description: Skills declare required inputs at the top and fail loudly when inputs are missing or stale — preventing pipeline stages from running on incomplete data
tags: [concepts, architecture, skills, quality, openclaw]
---

Skills declare required inputs at the top and proactively check for missing or stale context before proceeding. When inputs aren't ready, the skill fails loudly — preventing pipeline stages from producing low-quality output silently.

## The problem with silent failures

Without input validation, a pipeline stage that's missing its source data doesn't fail — it runs anyway. A tweet drafting pipeline with no fresh signals generates generic content. A research pipeline with stale data produces outdated summaries. The output looks complete but is garbage.

Silent failures are worse than loud failures because they consume resources, produce artifacts that look valid, and only reveal their problem at review time (if at all).

## The pattern

Each skill begins with an explicit pre-flight block:

```markdown
## Pre-flight checks
Before starting, verify:
- [ ] Source scanner has run in the last 8 hours (check tier1 log age)
- [ ] Topic bank has at least 3 unused entries
- [ ] API authentication is configured

If any check fails: stop and report the specific failure. Do not proceed.
```

The pre-flight block is the first thing the agent executes. If it fails, the skill returns a structured error with the specific check that failed and what needs to happen to fix it.

## In code

For programmatic pipelines (not just markdown skills), the same pattern applies:

```js
function preflight() {
  const scanLog = `logs/tier1-${today}.log`;
  if (!fs.existsSync(scanLog)) {
    throw new Error('Source scanner has not run today — signal may be stale');
  }
  const age = Date.now() - fs.statSync(scanLog).mtimeMs;
  if (age > 8 * 60 * 60 * 1000) {
    throw new Error(`Scanner last ran ${Math.round(age / 3600000)}h ago — too stale`);
  }
}
```

The check runs before any expensive work (API calls, file writes, Discord sends).

## What to validate

Common pre-flight checks:
- **Data freshness** — is the source data recent enough to be useful?
- **Required files** — do the input files exist and are they non-empty?
- **API availability** — is the downstream API responding?
- **Token/auth** — is authentication configured and valid?
- **Queue state** — is there actually work to do, or is the queue empty?

The last one is underrated. A pipeline that runs against an empty queue wastes resources and produces confusing empty output.

## Force override

Pre-flight checks should support a `--force` flag that bypasses them for testing and manual runs. The flag should log a warning that pre-flight was skipped — never silently bypass.

## Related

- [[concepts/skill-based-agent-architecture|Skill-Based Agent Architecture]] — the architecture within which input validation lives
- [[concepts/four-role-orchestrator-chain|Four-Role Orchestrator Chain]] — each stage in the chain validates its inputs
- [[concepts/graph-orchestration-patterns|Graph Orchestration Patterns]] — the broader orchestration framework
- [[concepts/self-improvement-system|Self-Improvement System]] — validation failures feed back into the improvement loop
