---
title: Doctrine Files
description: The three files that determine how your agent behaves between sessions — and how to write them well
tags: [guides, doctrine, configuration, soul, agents, user]
---

# Doctrine Files

Three files determine how your OpenClaw agent behaves before a single message is exchanged. They load on every session and shape everything: tone, memory, what the agent does proactively, how it handles uncertainty. Get them right and your agent stops being a chatbot. Get them wrong and it's unpredictable garbage.

The three files: `SOUL.md`, `AGENTS.md`, `USER.md`.

## SOUL.md — Operating Philosophy

SOUL.md is the agent's personality and decision framework. It answers: *how do I think, what do I do, and what matters?*

### What to include

**Tone and communication style.** Be specific. "Be helpful" means nothing. "Skip the filler phrases — no 'Great question!' or 'I'd be happy to help!' — just answer" is specific and actionable.

**Proactive behaviors.** What should the agent do without being asked? "Update `memory/YYYY-MM-DD.md` before ending any session." "Check email at each heartbeat and DM me if anything's urgent." "Add to build-queue.json when you identify work that should be done."

**Decision rules.** When does the agent ask versus act? A good rule: "Ask before anything external-facing — emails, tweets, public posts. Act freely on internal operations — reading, organizing, building."

**What the agent is NOT for.** The agent needs to know its scope. "Don't interrupt conversations to report minor findings. Batch them." "Don't start building something that will take an hour without checking in first."

**The prime directive.** One overriding rule everything else is subordinate to. Ours: "The chat is always open. Never block the main session with long-running inline work — spawn a subagent."

### What to avoid

Don't make SOUL.md a manifesto. Keep it under 500 words. Every line in this file costs tokens on every request. If something can be derived from a simple rule, don't spell out all the cases.

Don't contradict yourself. "Always ask before acting" and "proactively do X" need to be reconciled. Pick which takes precedence when they conflict.

Don't include specific project details here — that's USER.md. SOUL.md is about *how* the agent operates, not *what* it's working on.

### Example structure

```markdown
# SOUL.md

## Prime Directive
The chat is always open. Any task taking 3+ tool calls spawns a subagent.

## Tone
Direct. No filler. Skip the affirmations — just help.

## Proactive Work
- Update memory/YYYY-MM-DD.md before ending every session
- Check email at heartbeat, DM if urgent
- Maintain build queue — add items when you spot work to do

## Decision Framework
- Ask before: anything external (email, posts, public APIs with write access)
- Act freely on: reading, organizing, internal builds, memory updates

## Scope
Not responsible for: making judgment calls on product direction,
sending anything on behalf of Swifty without review.
```

---

## AGENTS.md — Session Initialization and Workspace Rules

AGENTS.md is the operational manual. It answers: *what do I load, in what order, and what are the rules of this workspace?*

### What to include

**Session initialization order.** What files load at session start, in what order, and what's conditional.

```markdown
## Every Session — Load in This Order
1. SOUL.md — always (tiny, loads first)
2. USER.md — always
3. memory/YYYY-MM-DD.md — today's notes
4. MEMORY.md — only in main session (direct chat), never in groups or subagents
5. LEARNINGS.md — always (recent corrections)
6. Task-specific files — only what's needed
```

**Memory budget rule.** Without this, the agent loads everything and costs a fortune. "Target 8KB session start. Do not load all memory files. Stop loading when you have enough context for the current session."

**Context flush rule.** When to write memory before context fills. "At 70% context usage, write a summary to today's memory file before compaction hits."

**Workspace conventions.** Where things live, naming patterns, which directories are off-limits.

**Safety rules.** What requires confirmation, what's forbidden, what the agent should never do autonomously.

### What to avoid

Don't make AGENTS.md a dumping ground for everything. It should contain *rules*, not documentation. If you find yourself writing a full explanation of how something works, that belongs in a separate file that AGENTS.md references.

Don't put sensitive credentials in AGENTS.md. It loads frequently; minimize what it exposes.

### Common structure

```markdown
# AGENTS.md

## Session Initialization

Load in this order, stop when context is sufficient:
1. SOUL.md
2. USER.md
3. memory/YYYY-MM-DD.md (today)
4. MEMORY.md — main session only
5. LEARNINGS.md + ERRORS.md

Context budget: 8KB target at session start. Do not load full history.

## Context Flush Rule
At 70%+ context: write [CONTEXT FLUSH HH:MM] to today's memory.
At 85%+: full summary immediately.

## Workspace Conventions
- workspace root: /home/user/.openclaw/workspace
- builds/: active build artifacts
- memory/: daily logs (never delete)
- pipelines/: cron-triggered scripts

## Safety
Ask before: any external message, API write, file deletion
Never: rm -rf, credentials in commit messages, public posts without review
```

---

## USER.md — Who the Human Is

USER.md is the context about you that the agent needs to be useful. It answers: *who am I working with, what are they doing, how do they like to work?*

### What to include

**Identity basics.** Name, what to call you, timezone. The agent needs to know when it's late for you.

**Communication style.** How you like to receive updates. "Concise — no walls of text." "Lead with the answer, then explain if needed." "Don't check in constantly — surface things when they matter."

**Current projects.** What's actively in progress. Not a full spec — just enough for the agent to understand why things are being built and what success looks like.

**Working relationships.** If others are in the picture (business partners, collaborators, clients), who they are and their communication channel.

**Things that matter.** What the agent should treat as high priority. Revenue milestones, specific users to prioritize, deadlines that exist.

### What to avoid

Don't write this once and never update it. USER.md needs to reflect your current reality. Dead projects listed as "active" confuse the agent. Update it when circumstances change.

Don't put things in USER.md that belong in SOUL.md. USER.md is *who you are*, not *how the agent should behave*.

---

## How Doctrine Evolves

Doctrine files are living documents. The ones you write on day 1 will be wrong in useful ways — they'll be too generic, miss edge cases you haven't hit yet, or include rules that turn out to conflict in practice.

### The edit-as-you-go pattern

When the agent does something you didn't want, add a rule to the relevant file immediately. Don't just correct it in the chat — write it to the file so it persists.

```
"Remember to always [X]" → add to SOUL.md or LEARNINGS.md
"When you start a session, load [X]" → add to AGENTS.md
"I prefer [X] over [Y]" → add to USER.md or LEARNINGS.md
```

### The quarterly review

Every few months, read all three files critically. Look for:
- Rules that are too vague to mean anything
- Rules that contradict each other
- Rules for situations that no longer apply
- Behaviors that feel off but have no corresponding rule

Trim aggressively. Length is cost.

### The consistency check

Before the agent gets significantly more capability or you change your workflows, re-read all three files to make sure they're consistent. Conflicting doctrine produces erratic behavior.

---

## Common Mistakes

**Too long.** Every line costs tokens. A 2,000-word SOUL.md is expensive and contradicts itself more than a 400-word one.

**Too vague.** "Be helpful and professional" tells the agent nothing. "Skip the filler, answer first, explain second" tells it something.

**Conflicting instructions.** "Always ask before acting" and "proactively do X without prompting" need a resolution rule or the agent will apply them inconsistently.

**Wrong file.** Project details in SOUL.md, behavioral rules in USER.md. Each file has a job.

**Never updating.** Doctrine written once and left forever drifts from reality. The agent's behavior will too.

---

## Related

- [[guides/self-improvement|Self-Improvement Grindset]] — how doctrine files fit into the compounding loop
- [[concepts/prompt-file-governance|Prompt File Governance]] — keeping your auto-loaded files from becoming expensive
- [[concepts/behavioral-onboarding-sequencing|Behavioral Onboarding Sequencing]] — the order in which you teach the agent about your context
