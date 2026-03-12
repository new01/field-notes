---
title: Continuous Information Ingestion
description: How to wire an agent to information sources so it learns autonomously — the eval-first principle, free sources, and the pipeline pattern
tags: [concepts, ingestion, rss, information, autonomous, pipelines]
---

# Continuous Information Ingestion

An agent that never reads anything never learns anything. Without wired information sources, your agent is limited to what you bring to it in conversation — which means it's always a step behind what's happening in your field.

Continuous ingestion changes that. The agent pulls from curated sources on a schedule, evaluates what's relevant, extracts signal, and routes findings to the right destination. You wake up to a brief that synthesizes what happened while you slept.

> [!important] Ingestion without eval is just noise
> Every source needs a scoring step. Raw ingestion creates a firehose you'll ignore within a week. The eval step is what turns information into signal.

## The Eval-First Principle

Before building any ingestion pipeline: **ingestion without an eval step is just noise**.

Pulling 50 HN stories per day and dumping them into a file is not useful. The agent has 50 items. None of them have been scored for relevance. You'll never read them. The ingestion is theatre.

Useful ingestion has an evaluation step that asks, for each item: *is this relevant to what I'm building?* Items that pass get processed further. Items that don't get discarded.

The eval can be as simple as keyword matching (free, instant) or as sophisticated as a language model scoring relevance against your current project context (accurate, costs tokens).

For most setups: start with keyword matching for initial filter, then use a cheap LLM call (Haiku-tier) only on items that pass the keyword gate. You get relevance scoring at reasonable cost.

---

## Free Sources — No API Key Required

These work immediately. No account creation, no API keys, no rate limit negotiation.

### Hacker News — Algolia API

```
https://hn.algolia.com/api/v1/search_by_date?query=AI+agents&hitsPerPage=20&tags=story
```

Parameters worth knowing:
- `query` — keyword filter. Use multiple keywords with `+`: `autonomous+agents`
- `hitsPerPage` — max 100
- `tags=story` — stories only (excludes comments). Use `ask_hn` or `show_hn` for those post types
- `numericFilters=points>10` — filter by minimum upvotes

Returns JSON with `hits[]`. Each hit has `title`, `url`, `points`, `created_at`, `objectID`. Use `objectID` to construct the HN link when `url` is null (self-posts): `https://news.ycombinator.com/item?id=<objectID>`.

Best for: engineering trends, new open source releases, technical discussions. Highest signal-to-noise of the free sources for technical topics.

### GitHub RSS Feeds

Any public repository or user has an RSS feed:

```
https://github.com/{user}/{repo}/releases.atom    — release notifications
https://github.com/{user}/{repo}/commits/{branch}.atom — commit activity
https://github.com/{user}.atom                    — user's public activity
```

Best for: tracking library releases (anthropic SDK, OpenAI, LangChain), watching specific repos for changes, monitoring framework development.

**Practical pattern:** Keep a list of 10-20 repos you care about. Daily RSS scan, filter for releases only. Drop new release notes into Obsidian and flag for review.

### YouTube Channel RSS

```
https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID
```

Get the channel ID from the channel's About page (URL: `youtube.com/channel/CHANNEL_ID`) or by viewing page source and searching for `channelId`.

Returns an Atom feed with video titles, descriptions, and published dates. No API key, no quota.

**The gold standard pipeline (more below):** fetch new videos → download audio → Whisper transcription → LLM eval → extract concepts → route to Obsidian and/or build queue.

### ArXiv RSS by Category

```
https://arxiv.org/rss/cs.AI      — AI category
https://arxiv.org/rss/cs.LG      — Machine Learning
https://arxiv.org/rss/cs.MA      — Multi-agent systems
https://arxiv.org/rss/stat.ML    — Statistics / ML
```

Returns new papers posted today (updates daily). High volume — filter aggressively. Most papers won't be relevant; use title keyword matching first, then abstract scoring.

Best for: staying ahead of research trends 3-6 months before they hit blog posts. Papers on multi-agent coordination, context engineering, retrieval architectures — they appear here before anywhere else.

### Product Hunt RSS

```
https://www.producthunt.com/feed
```

Daily new products. Filter by upvotes (the feed doesn't include them, so check the API for anything that makes your keyword filter). Best for: competitive landscape monitoring, spotting new AI tools, identifying market movements early.

### Crypto & Finance

These require no API key and have no meaningful rate limits for polling intervals of 30-60 minutes.

```
https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd   — prices, volume, market cap
https://api.coingecko.com/api/v3/search/trending                  — trending coins (social momentum)
https://api.coincap.io/v2/assets                                  — live prices (alternative source)
https://api.binance.com/api/v3/ticker/24hr                        — 24h tickers across 400+ pairs
https://open.er-api.com/v6/latest/USD                             — 170+ currency exchange rates
```

Volume-to-market-cap ratio from CoinGecko is the most useful single signal for crypto research: a small cap with outsized volume means something is moving before the crowd catches on. See [[concepts/dead-mans-switch|the gem hunter pattern]] for how we use this in practice.

### Weather & Environment

```
https://api.open-meteo.com/v1/forecast?latitude=37.7&longitude=-122.4&hourly=temperature_2m
https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.geojson
https://api.openaq.org/v2/latest?limit=20
```

Open-Meteo is the standout here — global weather at 1km resolution, updated hourly, no API key, no rate limits worth worrying about. More accurate than most commercial weather APIs.

### Science & Space

```
https://api.nasa.gov/neo/rest/v1/feed?api_key=DEMO_KEY          — near-earth asteroid tracking
http://api.open-notify.org/astros.json                           — astronauts in space / ISS position
https://api.spacexdata.com/v5/launches/latest                    — SpaceX launch data
https://arxiv.org/rss/cs.AI                                      — AI research papers (daily updates)
https://arxiv.org/rss/cs.MA                                      — Multi-agent systems papers
```

NASA's `DEMO_KEY` is public — you get 30 requests/hour and 50/day without any registration. That's enough for a daily polling job. For higher volume, the real key is free to get with just an email.

### Lobste.rs Tagged Feeds

```
https://lobste.rs/t/ai.rss
https://lobste.rs/t/programming.rss
https://lobste.rs/t/devops.rss
```

Curated technical community — higher signal than HN on deeply technical content. Smaller volume, less noise. Worth running in parallel with HN.

### Substack RSS

Every Substack publication has an RSS feed:

```
https://{author}.substack.com/feed
```

Also works with custom domains. Best for: practitioners writing regularly about AI agents, infrastructure, product development. Follow 5-10 curated sources rather than trying to read everything.

---

## Light Setup Required

These require minimal configuration but give significantly more access.

### Reddit (OAuth App)

Create a Reddit app at `reddit.com/prefs/apps` — takes 2 minutes, free. Gets you OAuth token. With it:

```
https://oauth.reddit.com/r/{subreddit}/new.json?limit=25
```

Useful subreddits: `r/LocalLLaMA`, `r/MachineLearning`, `r/artificial`, `r/AIAssistants`.

### Discord (User Account Read)

OpenClaw's Discord integration can read channels you're a member of. Set up a user account token (different from a bot token) to pull messages from channels you follow. Good for monitoring the OpenClaw Discord, community channels in your space, etc.

**Note:** User account API access violates Discord's ToS for bots but is fine for personal automation. Use with discretion.

### X/Twitter (Free Tier)

The free tier of X's API (Basic tier) allows reading specific accounts. Good enough for:
- Monitoring 5-10 specific accounts (researchers, founders, framework maintainers)
- Keyword search with low volume (100 requests/month on free tier)

Alternatively: use Nitter RSS for truly free access. Nitter instances expose public profiles as RSS feeds. Less reliable (instances go offline), but no API key required.

---

## The Pipeline Pattern

Every ingestion pipeline follows the same shape:

```
Fetch → Filter → Score → Extract → Route → Discard
```

### 1. Fetch

Pull raw items from the source. Keep this dumb — just HTTP requests and parsing. No LLM involvement yet.

### 2. Filter (keyword gate)

Fast, cheap deduplication and relevance filter. Check if titles/descriptions contain relevant keywords. Discard clearly irrelevant items before spending tokens on scoring.

```javascript
const KEYWORDS = ['agent', 'autonomous', 'LLM', 'pipeline', 'orchestration', 'context'];
const isRelevant = (item) => KEYWORDS.some(k => 
  item.title.toLowerCase().includes(k.toLowerCase()) ||
  (item.description || '').toLowerCase().includes(k.toLowerCase())
);
```

### 3. Score (LLM gate)

For items that pass the keyword filter, run a cheap LLM call to score actual relevance:

```
Score this item for relevance to: building autonomous AI agents for productivity.
Return JSON: {"score": 0-10, "reason": "one sentence"}
Item: {title} — {description}
```

Haiku-tier for this call. You're scoring relevance, not generating content.

### 4. Extract signal

For high-scoring items (≥7), extract what's actually useful:
- Key insight or finding
- What action it suggests (add to build queue, update Obsidian, generate tweet)
- Source credibility (HN story vs unknown blog)

### 5. Route

Based on the extracted signal:

- **Build queue** — "this describes a pattern we should implement"
- **Obsidian** — "this is a concept worth capturing"
- **Tweet seeds** — "this is quotable or shareable"
- **Morning brief** — "this is interesting but doesn't require action"
- **Discard** — scored below threshold

### 6. Discard

Log discarded items with the reason. Useful for tuning keyword filters and LLM scoring prompts over time.

---

## The YouTube Pipeline — Gold Standard Template

Transcribed video content is some of the highest-value free knowledge available. Researchers and practitioners post hours of content that never gets indexed properly. With a transcript pipeline, you can extract structured knowledge from any public video.

```
New video in watched channel RSS
    ↓
yt-dlp downloads audio only
    ↓
local Whisper transcribes (no API cost)
    ↓
LLM eval: is this worth processing further? (Haiku)
    ↓
If yes: LLM extraction — key concepts, patterns, quotes (Sonnet)
    ↓
Write Obsidian note with structured output
    ↓
If patterns found: add items to build queue
    ↓
Add to morning brief summary
```

Cost per video: ~$0.01 for the Haiku eval. ~$0.10-0.50 for full extraction on a 60-minute video (depends on transcript length and model). Zero for transcription if running local Whisper.

The Whisper step is the differentiator. Without local transcription, you'd pay OpenAI's Whisper API (cheap but adds up). With local Whisper on a GPU, 60 minutes of audio transcribes in 3-5 minutes at zero marginal cost.

---

## Local Storage: DuckDB

For pipelines that run continuously, you need a database that persists signal across runs. DuckDB is the right choice — single file, no server, fast analytics, works in any Node.js or Python script.

```sql
CREATE TABLE IF NOT EXISTS signals (
  id TEXT PRIMARY KEY,       -- sha256(source + item_id) — deduplication key
  source TEXT,               -- 'hn_show', 'coingecko_trending', 'arxiv_ai', etc.
  title TEXT,
  url TEXT,
  snippet TEXT,
  score INTEGER,             -- LLM relevance score 1-10
  reason TEXT,               -- one-line explanation from LLM
  discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  routed_to TEXT,            -- 'ideas', 'brief', 'watchlist', 'discarded'
  raw JSON                   -- full original payload
);
```

The `id` field handles deduplication automatically. Hash the source name and the item's unique identifier together — if you've seen it before, the insert silently fails. No separate seen-list to maintain.

Purge old discarded records weekly:

```sql
DELETE FROM signals 
WHERE routed_to = 'discarded' 
AND discovered_at < NOW() - INTERVAL '7 days';
```

For cross-run analysis — what sources produce the best signal:

```sql
SELECT source, COUNT(*) as items, ROUND(AVG(score), 1) as avg_score,
       COUNT(*) FILTER (WHERE score >= 7) as high_signal
FROM signals
WHERE discovered_at > NOW() - INTERVAL '30 days'
GROUP BY source ORDER BY avg_score DESC;
```

This is how you tune your source list over time. Sources with consistently low avg_score get dropped. Sources that keep producing high-signal items get more weight.

> [!note] DuckDB vs JSON files
> JSON files work fine for small pipelines (< a few thousand items). Once you want to query across runs, filter by date, or do any analysis, DuckDB pays for itself immediately. The migration is a one-time `INSERT INTO signals SELECT ... FROM read_json_auto('findings.json')`.

## Monitoring the OpenClaw Ecosystem

Keep a pulse on what's changing in the tools you depend on:

```
https://github.com/openclaw/openclaw/releases.atom   — new releases
https://github.com/openclaw/openclaw/issues.atom     — bug reports, feature requests
```

Discord channel monitoring (with user token) gives you community discussion as it happens — before it shows up anywhere else. When the community is hitting a new bug or pattern, you'll know within hours.

---

## Related

- [[guides/intelligence-stream-kit|The Intelligence Stream Kit]] — practical guide: one prompt to set up a full multi-domain intelligence pipeline
- [[guides/self-improvement|Self-Improvement Grindset]] — how ingestion feeds the compounding loop
- [[concepts/self-improvement-system|Self-Improvement System]] — the broader feedback architecture this connects to
