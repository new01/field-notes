---
title: "The Intelligence Stream Kit"
description: One prompt. Always-on signal from the web. How to build a private, self-running intelligence feed with zero ongoing maintenance.
tags: [guides, ingestion, automation, information, research, pipelines]
---

# The Intelligence Stream Kit

Most AI setups are reactive. You ask something, you get an answer. You ask again, you get another answer. The agent never learns anything between sessions because it's not wired to anything.

Information streams fix this. Instead of the agent waiting to be asked, it continuously pulls from the web, scores what it finds, and surfaces the things that matter. You stop asking "what's happening?" and start waking up to a brief that already answers it.

The full kit — a multi-domain polling pipeline — can be set up with a single prompt. No manual configuration, no API accounts, no ongoing maintenance. OpenClaw handles source discovery, tool installation, pipeline scaffolding, cron scheduling, and delivery.

---

## The One-Prompt Setup

Paste this into any OpenClaw session:

```
Act as my data engineer. Build me a World Intelligence Kit:

- Discover 5-10 no-auth public RSS feeds and JSON APIs covering: tech news, crypto/finance, 
  science/space, and weather.
- Install any needed skills (RSS parser, API poller, cron scheduler, DuckDB handler).
- Write and deploy an hourly poller that fetches, deduplicates, LLM-filters for high signal, 
  stores locally in DuckDB, and alerts me on anything important.
- Make it self-healing and background-running.

Output status when live.
```

What happens next: OpenClaw browses public API lists, installs skills via `clawhub install`, writes the polling scripts, sets up a local DuckDB store, schedules a cron job, and reports when the pipeline is live. You don't touch any of it.

This is the differentiator. Most agents stop at responding. OpenClaw turns a prompt into an always-on real-world data engine.

---

## What to Monitor (Free, No Auth, No Keys)

These sources work immediately. No accounts, no API keys, no negotiations.

### Tech & Startups

| Source | Endpoint | What You Get |
|--------|----------|--------------|
| Hacker News (Show HN) | `https://hn.algolia.com/api/v1/search?tags=show_hn&hitsPerPage=30` | New launches, tools, projects |
| Hacker News (Ask HN) | `https://hn.algolia.com/api/v1/search?tags=ask_hn&hitsPerPage=30` | Pain points, "how do you X" threads |
| Dev.to | `https://dev.to/api/articles?top=7&per_page=20` | Developer trends, tutorials |
| GitHub Trending | `https://api.github.com/search/repositories?q=created:>YESTERDAY&sort=stars` | New breakout repos |
| Lobste.rs | `https://lobste.rs/t/ai.rss` | High-signal technical community |
| Product Hunt | `https://www.producthunt.com/feed` | New product launches |

### Crypto & Finance

| Source | Endpoint | What You Get |
|--------|----------|--------------|
| CoinGecko Markets | `https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd` | Crypto prices, volume |
| CoinGecko Trending | `https://api.coingecko.com/api/v3/search/trending` | Social momentum early signal |
| CoinCap | `https://api.coincap.io/v2/assets` | Live prices, alternative source |
| Binance Public | `https://api.binance.com/api/v3/ticker/24hr` | 24h tickers, volume spikes |
| ExchangeRate-API | `https://open.er-api.com/v6/latest/USD` | 170+ currency rates |

No rate limits that block reasonable polling. All JSON, all real-time.

### Weather & Environment

| Source | Endpoint | What You Get |
|--------|----------|--------------|
| Open-Meteo | `https://api.open-meteo.com/v1/forecast?latitude=X&longitude=Y&hourly=temperature_2m` | Highly accurate global forecast |
| USGS Earthquakes | `https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_week.geojson` | Live significant earthquake events |
| OpenAQ | `https://api.openaq.org/v2/latest?limit=20` | Global air quality data |

### Science & Space

| Source | Endpoint | What You Get |
|--------|----------|--------------|
| NASA Near-Earth Objects | `https://api.nasa.gov/neo/rest/v1/feed?api_key=DEMO_KEY` | Asteroid tracking (DEMO_KEY works) |
| Open Notify ISS | `http://api.open-notify.org/astros.json` | Astronauts in space, ISS position |
| SpaceX Launches | `https://api.spacexdata.com/v5/launches/latest` | Latest launch data |
| ArXiv AI | `https://arxiv.org/rss/cs.AI` | New AI research papers daily |

### News

| Source | Endpoint | What You Get |
|--------|----------|--------------|
| Hacker News Firebase | `https://hacker-news.firebaseio.com/v0/topstories.json` | Top story IDs (fetch each) |
| BBC News | `http://feeds.bbci.co.uk/news/rss.xml` | World headlines |
| TechCrunch | `https://techcrunch.com/feed/` | Tech news |
| Reuters | `https://feeds.reuters.com/reuters/topNews` | Top news |

---

## The Storage Layer: DuckDB

For anything beyond a one-day signal, you want a local database that persists findings across runs. DuckDB is the right choice — it's a single-file database, needs no server, runs in any script, and handles analytical queries well.

Install the skill: `clawhub install duckdb-en`

Schema for an intelligence store:

```sql
CREATE TABLE IF NOT EXISTS signals (
  id TEXT PRIMARY KEY,          -- sha256(source + item_id)
  source TEXT,                  -- 'hn_show', 'coingecko_trending', etc.
  title TEXT,
  url TEXT,
  snippet TEXT,
  score INTEGER,                -- LLM relevance score (1-10)
  reason TEXT,                  -- one-line LLM explanation
  discovered_at TIMESTAMP,
  routed_to TEXT,               -- 'ideas', 'brief', 'watchlist', 'discarded'
  raw JSON                      -- full original item
);
```

Deduplication is automatic via the primary key. The `id` field is a hash of source + item identifier — if you've seen it before, the insert silently fails.

For querying what came in this week:

```sql
SELECT source, COUNT(*) as items, AVG(score) as avg_score
FROM signals
WHERE discovered_at > NOW() - INTERVAL '7 days'
GROUP BY source
ORDER BY avg_score DESC;
```

---

## The Eval-First Rule

Every source added to the pipeline needs an eval step. Without it you have a firehose, not a signal.

The pattern: keyword gate first (cheap, instant), LLM score second (accurate, costs tokens).

```javascript
// Step 1: keyword gate (free)
const KEYWORDS = ['launched', 'pain point', 'built with', 'SaaS', 'automation', 'agent'];
const passed = items.filter(item =>
  KEYWORDS.some(k => (item.title + ' ' + item.snippet).toLowerCase().includes(k))
);

// Step 2: LLM batch score (only on items that passed the gate)
const batches = chunk(passed, 15); // 15 items per call
for (const batch of batches) {
  const scored = await scoreBatch(batch);
  // route items scoring >= 7 to ideas pipeline
  // route items scoring 5-6 to watchlist
  // discard the rest
}
```

Batch 15 items per LLM call. Use Haiku-tier — you're scoring relevance, not generating content. This keeps the cost of a full pipeline run under a few cents.

> [!tip] Tune the gate, not the model
> If you're getting too much noise, tighten the keyword gate before reaching for a more expensive model. The gate handles volume; the model handles precision.

---

## Self-Healing Patterns

Pipelines break. Sources go down, rate limits change, RSS feeds move. These patterns keep things running without manual intervention.

**Graceful source failure.** Each source runs independently. If one 429s or 404s, log it and skip — don't crash the whole run. Retry the failed source on the next cycle.

```javascript
async function pollSource(name, fn) {
  try {
    return await fn();
  } catch (e) {
    console.error(`[${name}] Skipped: ${e.message}`);
    return [];
  }
}
```

**Stale-source detection.** If a source returns zero new items for 7 consecutive runs, flag it in the brief as potentially dead. Don't silently eat the failure.

**Dead-man's switch on the pipeline itself.** Write a timestamp file at the end of each successful run. A watchdog checks the timestamp — if it's stale, it pages you. Same pattern as [[concepts/dead-mans-switch|the heartbeat watchdog]].

**Exponential backoff on rate limits.** On 429, wait 2^attempt seconds before retry. Cap at 5 retries. Most rate limits reset within a minute.

---

## What a Running Pipeline Looks Like

After setup, the daily experience is:

**Morning brief** (auto-delivered via Telegram or Discord):
```
📡 Intelligence Brief — Mar 11

Sources: 9 active | Items fetched: 142 | High signal: 7 | Watchlist: 14

🔥 TOP SIGNALS
• Show HN: "I built a no-code webhook router for n8n" — Score 8 — SaaS opportunity in workflow automation
• CoinGecko: PENGU +42% overnight on 380% vol/mcap spike — momentum alert
• GitHub: repo "agent-bench" hit 2.1k stars in 24h — framework gaining traction fast

⚠️ ANOMALIES
• USGS: 6.2M earthquake in Tonga, 2h ago
• BTC dominance at 58% — altcoin bleed continuing

📊 WATCHLIST ADDITIONS
• "Ask HN: Why is there no good..." threads × 3 (pain point signals)
• SpaceX Falcon 9 launch confirmed for Fri 18:30 UTC
```

No manual work. The pipeline ran while you slept. You wake up to what matters.

---

## Expanding the Kit

Once the base pipeline is running, add domains as needed:

- **Legal/Regulatory** — `federalregister.gov/api/v1/articles.json`, SEC EDGAR RSS
- **Job market signals** — HN "Who is Hiring" thread, key job board RSS feeds
- **Academic** — ArXiv multimodal, semantic scholar trending papers
- **Social sentiment** — Reddit comment velocity (with OAuth), Mastodon public timelines
- **Competitors** — GitHub release feeds for tools you're competing with

Each addition is the same pattern: endpoint → fetch → keyword gate → LLM score → route. Once the infrastructure is in place, adding a new source is a five-minute job.

---

## Related

- [[concepts/continuous-ingestion|Continuous Information Ingestion]] — the underlying pipeline architecture in depth
- [[concepts/heartbeat-system|Heartbeat System]] — how to schedule the pipeline to run autonomously
- [[concepts/dead-mans-switch|Dead-Man's Switch]] — monitoring pattern to detect when the pipeline stops running
- [[guides/first-automation|Your First Automation]] — simpler starting point if this feels like too much
