---
title: Meta Ads Library Scraper
description: A browser-based sub-skill that visits the Meta Ads Library, handles lazy-load scrolling, downloads creatives, and visits landing pages — producing per-ad analysis grouped by funnel stage
tags: [concepts, competitive-intelligence, scraping, skills]
---

A browser-based sub-skill that visits the Meta Ads Library for a given brand, handles the library's lazy-load scrolling, downloads all creatives and their copy, visits every linked landing page, and produces a structured per-ad analysis grouped by funnel stage.

## Why the Meta Ads Library

The Meta Ads Library (facebook.com/ads/library) is one of the few places where competitor ad creative is publicly accessible — a legal transparency requirement for political and social issue ads that Meta extended to all advertisers.

For competitive research, it's a window into:
- Which offers a competitor is actively running (active = spending money = working)
- How long an ad has been running (longevity = proven performance)
- How copy and creative evolve across a campaign
- Landing page strategy (CTA, offer structure, funnel stage)

## The technical challenge

The Ads Library uses infinite scroll with lazy-loaded content — standard `requests`-based scraping fails. A browser automation approach (Playwright, Puppeteer) is required to:

1. Open the library filtered by brand name
2. Scroll to trigger lazy loading until all active ads are visible
3. Extract ad creative URLs, copy text, and landing page links
4. Visit each landing page and capture its structure

This is a sub-skill that handles all of that — the orchestrator passes a brand name and receives structured ad data.

## Output structure

```json
{
  "brand": "competitor-name",
  "ads_found": 24,
  "scraped_at": "...",
  "ads": [
    {
      "ad_id": "...",
      "started_running": "...",
      "copy": "...",
      "cta": "Learn More",
      "landing_page_url": "...",
      "landing_page_summary": "...",
      "funnel_stage": "awareness | consideration | conversion",
      "creative_type": "image | video | carousel"
    }
  ]
}
```

The `funnel_stage` classification uses a light reasoning step on the copy + CTA + landing page content — awareness ads use curiosity hooks and educational content; conversion ads use urgency, social proof, and direct offers.

## Use in competitive analysis

This sub-skill feeds the broader competitive analysis pipeline: scrape ads → analyze creative patterns → benchmark against your own positioning → surface gaps and opportunities.

The most valuable signal is longevity: ads that have been running for 3+ months are working. The copy angles and creative formats in long-running ads are worth studying.

## Related

- [[Orchestrator Sub-Skill Pattern]] — this scraper is a sub-skill within a competitive analysis orchestrator
- [[Skill-Based Agent Architecture]] — the architecture that makes this sub-skill composable
- [[Graph Orchestration Patterns]] — the pipeline context this sub-skill operates in
