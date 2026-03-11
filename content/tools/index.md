---
title: Tools
description: Practical pipelines and scripts we run in production — what they do, how they work, where they break
---

# Tools

Practical pipelines and scripts we actually use. Not polished products — these are working tools with real limitations. We describe what they do, how they work, and where they break.

## Content and Writing

### Humanization Pipeline

A scoring and rewriting system for AI-generated text. When content needs to read as natural human writing, it goes through this pipeline before publishing.

#### How it works

A detection layer scores text across 28 pattern categories: filler openers, AI vocabulary tiers, sentence structure uniformity, burstiness (variance in sentence length), type-token ratio, and readability metrics. Anything above a threshold score gets flagged. A rewrite pass targets the specific patterns that fired, not the entire text.

#### Why 28 patterns

Because "doesn't sound like AI" isn't one thing. Overuse of em dashes is different from low burstiness, which is different from Tier-1 AI vocabulary ("delve," "nuanced," "seamlessly"). The detector needs to know which patterns are present to know how to fix them.

##### Vocabulary tiers

- **Tier 1** — dead giveaways: "delve," "nuanced," "leverage," "seamlessly," "transformative"
- **Tier 2** — common but not conclusive: "utilize," "implement," "facilitate," "robust"
- **Tier 3** — borderline: "optimize," "streamline," "enhance" — context-dependent

##### Statistical signals

Beyond vocabulary, the pipeline checks:
- **Burstiness** — human writing has high variance in sentence length. AI output is uniform.
- **Type-token ratio** — humans repeat words less than AI does. Low TTR = robotic.
- **Readability score** — AI tends toward similar Flesch scores across different content types. Natural human writing varies.

#### When to use it

Community posts, outreach, sales copy, support responses — anywhere the AI-generated nature of the text would undermine the goal. Not for internal docs, infrastructure, or anything where the AI nature is the point.

#### What it doesn't do

Not a guarantee. Reduces detection likelihood, not to zero. Doesn't fix factual errors or improve weak arguments. Content still needs human review.

---

### Tweet Batch Pipeline (`tweet-batch`)

Batch generation and scheduling of tweets from seed content. Takes a list of tweet seeds (concepts, quotes, observations) and produces formatted, humanized drafts ready for review.

#### The pipeline

1. Read seeds from `data/tweet-seeds/` — one per file or from a queue JSON
2. Select format per seed using the [[concepts/tweet-format-taxonomy|Tweet Format Taxonomy]] (hook, thread-starter, quote, insight, etc.)
3. Generate draft using Sonnet-tier with format spec + seed + voice rules
4. Score draft through humanization pipeline — rescore if above threshold
5. Write final draft to `data/tweet-drafts/YYYY-MM-DD/` for review
6. Log run to `logs/tweet-batch/`

#### Review gate

The pipeline doesn't post. It produces drafts. You review and post (or the humanized version goes to a scheduled posting script you control). This is intentional — autonomous posting of AI content without human review is how brand voices go wrong.

#### Where it breaks

If seed quality is low (vague, no clear point of view), the output will be vague. The pipeline can't manufacture a strong take from "AI is changing things." Seeds need to be specific.

---

### Extract Concepts (`extract-concepts`)

Extracts structured concept notes from raw source material — YouTube transcripts, Obsidian notes, pasted articles. Produces formatted Obsidian-compatible notes with tags, links, and source attribution.

#### Input formats

- YouTube transcript (produced by local Whisper pipeline)
- Raw text or Markdown paste
- HN comment threads
- ArXiv paper abstracts

#### Output structure

```markdown
# Concept Name

Brief definition of the concept.

## How it applies to us
Specific application to our context.

## Related
- [[infrastructure/graph-orchestration|Graph Orchestration]]
- [[concepts/build-queue-pattern|Build Queue Pattern]]

## Sources
- Source attribution

## Tags
#concept #category #tag
```

#### The LLM call

Uses a structured prompt that asks the model to identify 1-3 discrete concepts in the source material and produce a note for each. Not a summary — each output should be a self-contained concept note, not a recap of the source.

---

### Score Text (`score-text`)

Standalone scoring utility. Takes text as input and returns a detailed breakdown of AI pattern detection scores. Useful for spot-checking before humanization or for understanding why the humanizer flagged something.

```bash
echo "Leverage synergistic approaches to seamlessly transform..." | score-text
# Returns: overall score 8.4/10, patterns: tier1_vocab(4), low_burstiness, filler_opener
```

---

## Media Processing

### Local Whisper Transcription

A local audio transcription pipeline for ingesting YouTube content into your knowledge base.

#### Stack

`faster-whisper` with CUDA backend, `large-v2` model. VRAM-adaptive: checks available VRAM at startup and falls back to a smaller model if needed. Runs locally — no API calls, no cost per minute.

#### Why bother

Getting ideas from a 45-minute YouTube video into structured notes is normally friction. With transcription, you drop the URL, get the transcript, and an agent processes it into structured notes, extracts concepts, and links to relevant Obsidian pages automatically.

#### The full workflow

```
yt-dlp downloads audio only (--extract-audio --audio-format mp3)
    ↓
faster-whisper transcribes → transcript.txt
    ↓
transcript drops into staging/transcripts/
    ↓
extract-concepts processes transcript
    ↓
concept notes written to Obsidian vault
    ↓
relevant items added to build queue
```

#### Limitations

Requires GPU with at least 4GB VRAM for `large-v2`. CPU fallback exists but is too slow for videos over 20 minutes. Accuracy drops on heavily accented speech and technical jargon. Transcript needs a light cleanup pass for proper nouns.

---

### Media Processor (`media-processor`)

Handles the full media ingestion lifecycle: YouTube URL → download → transcribe → extract → route. Wraps `yt-dlp`, Whisper, and `extract-concepts` into a single CLI invocation.

```bash
media-processor --url "https://youtube.com/watch?v=..." --vault ~/Notes --queue build-queue.json
```

Handles deduplication (won't re-process a URL it's already seen), logs run metadata to `data/media-log.json`, and produces a report of what was extracted.

---

## Infrastructure and Operations

### Morning Brief (`morning-brief`)

Daily digest assembly script. Pulls from HN Algolia API, build queue status, and any other configured sources, formats into a Discord/Telegram-ready message, and delivers.

Covered in detail in [[guides/first-automation|Your First Automation]].

---

### Build Queue Runner

Sequential graph execution for multi-step agent tasks. Reads from `build-queue.json`, picks the highest-priority queued item, writes the spec to `builds/<id>/spec.md`, and dispatches a Claude Code session.

#### What it manages

- Status transitions: `queued` → `in-progress` → `done` / `failed`
- Gate checking: verifies artifacts exist on disk before marking done
- Failure handling: resets to `queued` with error annotation on gate check failure
- DM notification: reports completion or failure to configured Discord user ID

#### When to run it

During Phase 2 heartbeat (idle dispatch) or manually when you want to advance the queue. Not a daemon — a single-run script that processes one item then exits.

---

### Oracle Provision (`oracle-provision`)

Provisions infrastructure: sets up PM2 processes, creates directory structures, registers cron jobs, and validates the full OpenClaw stack is running correctly.

#### What it checks and creates

- Gateway daemon running (PM2)
- Mission Control server running and responding
- Dead-man's switch watchdog running
- Required directories exist (`logs/`, `builds/`, `memory/`, `data/`)
- Crontab entries for registered pipelines
- `pipelines.json` entries are consistent with actual script files

Run this when setting up a new environment or after a major configuration change.

---

## Monitoring

### Nitter RSS Scanner

Free X/Twitter monitoring via public Nitter instances.

#### What it does

Nitter is an alternative Twitter frontend that exposes RSS feeds. Any public X profile or search query can be converted to an RSS feed via Nitter. The scanner polls these feeds on a cron schedule and pipes new posts to an agent for classification and routing.

#### Why not the official API

X's API is expensive at the tier that allows useful access. Nitter instances are free, no authentication required, and expose the same public content.

#### Practical setup

Maintain a list of 5-10 public Nitter instances. Before each poll, health-check them and pick an available one. Rotate through to distribute load. Cache results with URL deduplication to avoid re-processing the same posts.

#### Limitations

Nitter instances go down frequently — community-maintained and unstable. X's ongoing crackdown on alternative frontends may reduce available instances. Rate limits apply; polling too aggressively gets instances to block you.

---

→ [[concepts/index|Concepts]] | [[infrastructure/index|Infrastructure]] | [[guides/index|Guides]]
