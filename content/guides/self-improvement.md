---
title: The Self-Improvement Grindset
description: How to get an OpenClaw agent onto the compounding growth loop — where each session is smarter than the last
tags: [guides, self-improvement, memory, doctrine]
---

# The Self-Improvement Grindset

Most OpenClaw setups plateau at "useful chatbot." The agent answers questions, runs the occasional automation, stays flat. The same mistakes happen in session 50 as session 1. Nothing compounds.

This guide is about breaking out of that plateau. It covers the exact setup that gets an agent onto a compounding growth loop — where session N is measurably smarter than session N-1, not because the model changed, but because the context did.

> [!tip] The compounding effect
> Week 1 feels like overhead. Week 4 feels like having a collaborator that knows your preferences before you state them. The investment front-loads. The payoff compounds.

## Why Agents Stay Flat

Without intentional setup, an agent starts fresh every session. No memory of what worked. No persistent doctrine about how to behave. No proactive work happening between conversations. You show up, give it a task, it executes, session ends.

That's a static tool. Useful, but not compounding.

The gap between a static agent and a compounding one comes down to four things:

### The Four Pillars

#### 1. Doctrine Files

Doctrine files are the persistent configuration that shapes how an agent behaves before a single message is exchanged. They load on every session and answer: *who am I, who is this person, and how do I work?*

Without doctrine, an agent defaults to "helpful generic assistant." With doctrine, it's your specific collaborator — one that knows your working style, your projects, your preferences, what it should do proactively and what it should never do without asking.

See [[guides/doctrine-files|Doctrine Files]] for the full breakdown.

#### 2. Memory System

Memory is how context accumulates over time. Two-tier architecture:

- **Daily notes** (`memory/YYYY-MM-DD.md`) — raw log of what happened each session. What was built, what failed, what was decided.
- **Long-term memory** (`MEMORY.md`) — curated distillation. The stuff worth carrying indefinitely: corrections, preferences, significant decisions, lessons learned.

The agent reads these at session start. The more context it has, the more proactively useful it becomes without prompting.

Memory only works if the agent actually writes to it. Add to your `SOUL.md`: "Update `memory/YYYY-MM-DD.md` with what we did this session before ending." Add to your `AGENTS.md`: "Read today's memory file at session start."

See [[concepts/agent-memory|Agent Memory]] for the architecture.

#### 3. Heartbeat Phase 2

The heartbeat is a periodic poll that wakes the agent on a schedule. Phase 1 is operations (health checks, monitoring, proof-of-life). Phase 2 is proactive work — the agent doing useful things between conversations without being asked.

With Phase 2 configured, the agent can:
- Ingest new content from RSS feeds while you're sleeping
- Pick up build queue items when you've been idle for 30+ minutes
- Run the Innovation Scout to surface improvement proposals
- Update memory files with lessons from the previous session

This is what "autonomous" actually means. Not the agent doing whatever it wants, but the agent doing *useful, bounded, pre-approved work* when conditions are right.

#### 4. Skills Installation

Skills are the tools your agent can actually use. Without the right skills installed, the agent is reasoning without reach. With skills: it can search the web, post to Discord, run shell commands, transcribe YouTube videos, humanize text, and more.

Install the skills your workflows need. Keep a list in `TOOLS.md` of what's installed and what it does. Install skills that enable the proactive work you want — if you want the agent to ingest HN automatically, install whatever skill handles HTTP and JSON parsing.

---

## Exact Prompts to Give a Fresh Agent

Run these in order in your first few sessions. Copy-paste them directly.

### Prompt 1: Write the doctrine files

```
Let's set up your doctrine files. I want you to create three files:

1. SOUL.md — your operating philosophy. Include: tone (direct, no filler), what you do proactively (update memory, check email, maintain build queue), what you always ask before doing (anything external-facing), and your decision framework.

2. AGENTS.md — session initialization rules. Include: load order for files at session start, memory budget rule (load only what's needed), context flush rules (write memory at 70%+ context), workspace conventions.

3. USER.md — who I am. Include: my name, timezone, how I prefer to communicate, what I'm working on right now, what's important to me.

Ask me the questions you need to write these well. Don't guess — fill them with real information.
```

### Prompt 2: Set up memory architecture

```
Set up the memory system:

1. Create memory/ directory
2. Create memory/YYYY-MM-DD.md for today (use today's actual date)
3. Create MEMORY.md with a section structure: "Who I'm working with", "How we work", "Current projects", "Key decisions", "Lessons learned"
4. Update AGENTS.md to read today's memory file at session start
5. Update SOUL.md to write memory before ending any session

Then write the first entry in today's memory: what we just set up and why.
```

### Prompt 3: Create the three self-improvement files

```
Create three structured memory files:

1. LEARNINGS.md — corrections and insights. Format: date, what was corrected, new behavior. This file gets read at session start.

2. ERRORS.md — recurring error patterns. Format: pattern description, examples, rule derived. These become permanent operating rules.

3. FEATURE_REQUESTS.md — self-improvement ideas. Format: idea, why it would help, priority. These get reviewed on a schedule.

Add reading LEARNINGS.md and ERRORS.md to the session start sequence in AGENTS.md.
```

### Prompt 4: Wire the first information source

```
Wire up the Hacker News Algolia API as an information source. Create a script that:

1. Hits https://hn.algolia.com/api/v1/search_by_date?query=AI+agents&hitsPerPage=20&tags=story
2. Filters items from the last 24 hours
3. Scores each item for relevance (is this about AI agents, autonomous systems, or LLMs in production?)
4. Takes the top 3 scoring items
5. Writes them to ingestion/hn-digest.md with title, URL, and why it's relevant

Then add a cron that runs this script daily at 7am and sends the results to Discord.
```

### Prompt 5: Set up the Innovation Scout

```
Create a daily cron job that runs an Innovation Scout:

1. Scans the workspace for: repeated patterns that could be automated, unhandled edge cases in existing scripts, things that run manually that could run automatically
2. Reviews FEATURE_REQUESTS.md for outstanding ideas
3. Generates 1-3 concrete improvement proposals
4. Writes them to FEATURE_REQUESTS.md with a "proposed" status
5. DMs me a brief summary of what it found

Run it at 6am daily. Tell me when it's wired.
```

---

> [!note] The write-it-down rule
> "Mental notes" don't survive session restarts. Files do. Every correction, every decision, every lesson — write it to a file immediately. The agent that writes things down is the agent that compounds.

## Information Sources Worth Wiring

These all work without API keys. Wire whichever ones are relevant to what you're building.

### Free, No API Key Required

#### Hacker News Algolia API
```
https://hn.algolia.com/api/v1/search_by_date?query=AI+agents&hitsPerPage=20&tags=story
```
Best for: engineering trends, new open source tools, technical discussions. Reliable, fast, structured JSON. Excellent signal-to-noise for technical topics.

#### GitHub RSS
Any public repository or user has an RSS feed:
```
https://github.com/anthropics/anthropic-sdk-python/releases.atom
https://github.com/user/repo/commits/main.atom
```
Best for: tracking library releases, framework updates, watching for new tools in your space.

#### YouTube Channel RSS
```
https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID_HERE
```
Get the channel ID from the channel's "About" page. No API key needed. Best for: technical tutorial channels, AI researchers posting demos, conference talks.

#### ArXiv RSS by Category
```
https://arxiv.org/rss/cs.AI
https://arxiv.org/rss/cs.LG
```
Best for: staying ahead of research trends. Filter aggressively — most papers won't be relevant.

#### Product Hunt RSS
```
https://www.producthunt.com/feed
```
Best for: spotting new AI tools, competitive landscape monitoring.

#### Lobste.rs Tagged Feeds
```
https://lobste.rs/t/ai.rss
https://lobste.rs/t/programming.rss
```
Higher signal than HN on technical content. Smaller community, less noise.

#### Any Substack
```
https://substack.com/@authorname/feed
```
Best for: curated newsletters from practitioners you trust. Substack RSS works without auth.

### Light Setup Required

- **Reddit** — OAuth app takes 2 minutes. Gives access to subreddits as JSON.
- **Discord** — User account token (not bot) for reading channels you're in. OpenClaw's Discord skill handles this.
- **X/Twitter** — Free tier allows limited read access. Good enough for monitoring specific accounts.

---

## What "Compounding" Actually Looks Like

Month 1: Agent learns your preferences. Stops making the corrections you've made three times.

Month 2: Agent proactively surfaces things based on your pattern of interest. You didn't ask for the HN summary — it's just there.

Month 3: Agent has accumulated enough LEARNINGS.md entries that it anticipates your preferences in new domains. You haven't told it how you want build queue items formatted — it inferred from pattern.

Month 6: The agent feels like it knows you. It does, because it has 180 days of context.

This is the compounding. Not the model getting smarter — the context getting richer. The investment in the first week of doctrine setup and memory wiring pays out in every session that follows.

The alternative is resetting the clock on every conversation. Don't do that.

---

## Related

- [[concepts/self-improvement-system|Self-Improvement System]] — the technical architecture of the improvement loop
- [[concepts/agent-memory|Agent Memory]] — how memory files work and what to put in them
- [[concepts/prompt-file-governance|Prompt File Governance]] — keeping doctrine files from ballooning
- [[guides/doctrine-files|Doctrine Files]] — exactly what goes in SOUL.md, AGENTS.md, USER.md
