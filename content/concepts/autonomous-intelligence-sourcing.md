---
title: Autonomous Intelligence Sourcing
description: How OpenClaw agents find, evaluate, and subscribe to real-world data streams without paywalls or manual configuration.
tags: [intelligence, rss, ingestion, autonomous, free-tier]
---

# Autonomous Intelligence Sourcing

Most "intelligence platform" products hit the same wall: the useful tier costs $99/month and requires a sales call. An OpenClaw agent doesn't need their UI — it goes directly to the source.

> [!tip] The core insight
> RSS is still the web's open data bus. Most platforms that matter either expose it natively or can be queried without authentication. The agent's job is to know where to look.

## The Zero-Auth Stack

These endpoints return structured data with a plain HTTP GET. No key, no signup.

### Hacker News — Algolia API

```
https://hn.algolia.com/api/v1/search_by_date?query=<topic>&tags=story
```

Full text search, scores, timestamps, URLs. Filter by `points >= N` after fetch. Covers 30+ years of HN content, updated in real time.

### GitHub Search

```
https://api.github.com/search/repositories?q=<query>&sort=updated
```

60 requests/hour unauthenticated — enough to monitor a topic area continuously. Detects breakout repos by star velocity and recent push activity.

### Reddit via Arctic Shift

Reddit's official API now requires OAuth and $100/month for serious use. [Arctic Shift](https://arctic-shift.photon-reddit.com) provides a free public archive API that covers all subreddits with near-real-time data.

```
https://arctic-shift.photon-reddit.com/api/posts/search?subreddit=<sub>&sort=desc
```

### Mastodon Public Timelines

```
https://mastodon.social/api/v1/timelines/tag/<hashtag>?limit=20
```

No auth required for public timelines. Tech-focused instances like fosstodon.org and hachyderm.io carry high-quality posts on `#llm`, `#claudeai`, and `#opensource`.

### OpenAlex — Academic Papers

```
https://api.openalex.org/works?search=<query>&filter=publication_year:>2024
```

The richest free academic source that exists. 29,000+ papers on "autonomous AI agents" published in 2025 alone. No key required, no rate limit drama, free forever.

---

## RSS Everywhere

RSS never died. It became invisible. Almost every platform that matters exposes it — most users just don't know the URL.

### Auto-discovery from any URL

```python
import urllib.request, re

def find_feed(url):
    html = urllib.request.urlopen(url).read().decode()
    feeds = re.findall(
        r'<link[^>]+type="application/(rss|atom)\+xml"[^>]+href="([^"]+)"',
        html, re.I
    )
    return [f[1] for f in feeds]
```

Fetch any URL, parse the HTML `<head>` for `<link rel="alternate">` tags. Works on most news sites, blogs, and developer publications.

### Platform RSS patterns (no auth)

| Platform | Feed URL pattern |
|----------|---------|
| YouTube channel | `youtube.com/feeds/videos.xml?channel_id=<ID>` |
| Any Substack | `<handle>.substack.com/feed` |
| GitHub releases | `github.com/<user>/<repo>/releases.atom` |
| ArXiv by category | `export.arxiv.org/rss/cs.AI` |
| Lobsters by tag | `lobste.rs/t/<tag>.rss` |
| Product Hunt | `producthunt.com/feed` |
| Any Ghost blog | `<domain>/rss/` |

> [!note] Finding YouTube channel IDs
> Fetch `https://www.youtube.com/@channelname`, grep the HTML source for `"channelId":"UC..."`. The RSS feed URL follows directly from that ID.

---

## The Eval Step

Raw ingestion without scoring is just noise. Every item passes through a Haiku eval after fetch:

```
Score 0-10 for relevance to: <user's domain and goals>

8-10: directly actionable → build queue
5-7:  worth keeping → Obsidian research log
0-4:  noise → discard
```

At $0.80/M tokens (Haiku), evaluating 1,000 items/day costs roughly $0.04. The eval pays for itself in the first minute of saved reading time.

> [!important] Batch your eval calls
> Score 10 items per API call. Single-item eval is 10× more expensive with identical quality. The prompt overhead is the same either way.

---

## The Autonomous Setup Pattern

The agent reads `USER.md`, infers the user's domain and interests, then discovers sources automatically:

1. Extract topics, project names, and URLs from `USER.md`  
2. Run FeedSearch API to find RSS feeds for each topic  
3. Add HN and GitHub search queries for the same topics  
4. Write the full config to `data/intelligence-sources.json`  
5. Start ingesting — no human intervention needed

```bash
# Discover sources for a new topic
node scripts/intelligence-setup.js --topic "model context protocol"

# Discover feeds from a specific URL
node scripts/intelligence-setup.js --url https://simonwillison.net
```

Source quality self-evaluates over time: sources with < 10% high-signal rate after 7 days get flagged for replacement.

---

## What Doesn't Work

> [!warning] Walls worth knowing about
> Some platforms have genuinely closed off free access. Don't waste time fighting them.

| Source | Status | Why |
|--------|--------|-----|
| Twitter/X API | Dead for free use | $100/month minimum since 2023 |
| LinkedIn | Completely walled | No public API exists |
| DEV.to | Blocks server-side | Both RSS and API return 403 |
| Discord servers | ToS prohibits scraping | Your own server via bot = fine |
| Reddit JSON API | Blocked server-side | Use Arctic Shift instead |

---

## Related

- [[concepts/continuous-ingestion|Continuous Ingestion]] — the broader ingestion architecture
- [[concepts/self-improvement-system|Self-Improvement System]] — how intelligence feeds drive agent growth
- [[concepts/agent-memory|Agent Memory]] — where high-signal findings get persisted
- [[infrastructure/mission-control|Mission Control]] — the dashboard that surfaces intelligence findings
