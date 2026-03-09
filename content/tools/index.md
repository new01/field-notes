---
title: "Tools"
---

# Tools

Practical pipelines and scripts we actually use. Not polished products — these are working tools with real limitations. We describe what they do, how they work, and where they break.

---

## Local Whisper Transcription

A local audio transcription pipeline for ingesting YouTube content into your knowledge base.

**Stack:** `faster-whisper` with a CUDA backend, `large-v2` model. VRAM-adaptive: checks available VRAM at startup and falls back to a smaller model if needed. Runs locally — no API calls, no cost per minute.

**Why bother:** Getting ideas from a 45-minute YouTube video into structured notes is normally friction. With transcription, you drop the URL, get the transcript, and an agent can summarize, extract concepts, and link to relevant notes in your knowledge base automatically.

**Limitations:** Requires a GPU with at least 4GB VRAM for `large-v2`. CPU fallback exists but is too slow to be practical for long videos. Accuracy drops on heavily accented speech and technical jargon. The transcript needs a light cleanup pass for proper nouns.

**The workflow:** `yt-dlp` downloads audio only → faster-whisper transcribes → transcript drops into a staging folder → an agent processes it into structured notes.

---

## Humanization Pipeline

A scoring and rewriting system for AI-generated text. When content needs to read as natural human writing, it goes through this pipeline before publishing.

**How it works:** A detection layer scores text across 28 pattern categories — filler openers, AI vocabulary tiers, sentence structure uniformity, burstiness (variance in sentence length), type-token ratio, and readability metrics. Anything above a threshold score gets flagged. A rewrite pass targets the specific patterns that fired, not the entire text.

**Why 28 patterns:** Because "doesn't sound like AI" isn't one thing. Overuse of em dashes is different from low burstiness, which is different from Tier-1 AI vocabulary ("delve," "nuanced," "seamlessly"). The detector needs to know which patterns are present to know how to fix them.

**What it doesn't do:** It's not a guarantee. It reduces detection likelihood, not to zero. It also doesn't fix factual errors or improve weak arguments — it's a surface-level fix for language patterns. Content still needs human review.

**When to use it:** Community posts, outreach, sales copy, support responses — anywhere the AI-generated nature of the text would undermine the goal. Not for internal docs, infrastructure, or anything where the AI nature is the point.

---

## Build Queue Pattern

Sequential graph execution for multi-step agent tasks, backed by SQLite.

**The problem it solves:** When you have a 10-step build (spec, scaffold, implement A, implement B, review, test, document...), running all steps in parallel causes conflicting edits, missed dependencies, and inconsistent context across agents. Running them purely sequentially is slow but avoids the conflicts.

The build queue is the middle path: tasks execute as a directed graph, one node at a time, but each node completes before the next starts. Gate checks between phases (does the previous phase output look correct?) prevent bad work from cascading forward.

**SQLite-backed:** Every task records its state in a `build_queue` table. Status transitions: `pending` → `running` → `done` / `failed`. If the process crashes mid-build, the queue recovers — it knows where it was.

**Why this matters for API limits:** Running 5 agents simultaneously means 5 concurrent API consumers. On high-traffic models or rate-limited API tiers, this overloads the queue and causes failures. Sequential graph execution keeps concurrency at 1, which is predictable and recoverable.

**Limitation:** It's slower than true parallel. The tradeoff is reliability and cost predictability. For most practical builds, the speed difference is not meaningful.

---

## Nitter RSS Scanner

Free X/Twitter monitoring via public Nitter instances.

**What it does:** Nitter is an alternative Twitter frontend that exposes RSS feeds. Any public X profile or search query can be converted to an RSS feed via Nitter. The scanner polls these feeds on a cron schedule and pipes new posts to an agent for classification and routing.

**Why not the official API:** X's API is expensive at the tier that allows useful access. Nitter instances are free, no authentication required, and expose the same public content.

**Limitations:** Nitter instances go down frequently — the public instances are community-maintained and unstable. You need a list of fallback instances and health-check logic before polling. Rate limits apply; polling too aggressively gets instances to block you. Private accounts and posts behind a login wall are not accessible. X's ongoing crackdown on alternative frontends may reduce available instances over time.

**Practical setup:** Maintain a list of 5-10 public Nitter instances. Before each poll, health-check them and pick an available one. Rotate through to distribute load. Cache results to avoid re-processing the same posts.

**What it's good for:** Monitoring specific accounts for brand mentions, tracking keywords in your niche, watching competitors for announcements. Not a replacement for a proper social listening tool if X data is business-critical.

---

→ [[concepts/index|Back to concepts]] | [[infrastructure/index|Back to infrastructure]]
