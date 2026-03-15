---
title: Stateless Web Fetch for Agents
description: Lightweight APIs that return web page content without launching full browser sessions — the right primitive for agents that need to read the web, not interact with it.
tags: [concepts, agents, web, infrastructure, retrieval, browsing, tools]
---

AI agents frequently need to read content from the web — documentation, articles, product pages, GitHub repositories — before deciding what to do next. The naive implementation spins up a full browser session for every retrieval. The better primitive is a stateless fetch API: give it a URL, get back the page content, no session overhead required.

## The mismatch problem

Browser automation platforms like Playwright and Puppeteer were built for interaction — clicking, scrolling, filling forms, navigating complex flows. They solve a real problem: modern web applications are rendered by JavaScript and require a full browser engine to produce useful content.

But agents reading the web often don't need any of that. They need text. Spinning up a full browser session to read a documentation page is like taking a taxi to a destination you can reach on foot — it works, but the overhead is unnecessary. The latency is higher, the cost is higher, and the surface area for failure (browser crashes, session limits, timeouts) is larger.

Stateless fetch APIs solve the mismatch by separating *retrieval* from *interaction*.

## How stateless fetch works

A stateless web fetch API accepts a URL and returns the page content — HTML, rendered text, or a screenshot — without maintaining a persistent browser session. The infrastructure handles the complications that make naive `curl` calls unreliable:

- **Redirects** — chains of 301s, 302s, and meta-refreshes resolved transparently
- **Anti-bot detection** — browser fingerprinting and TLS handshakes that look like legitimate clients
- **Encoding normalization** — inconsistent charsets, gzip/brotli decompression
- **JavaScript rendering** — optional, for pages that require it
- **Headers** — consistent User-Agent and Accept headers that modern servers expect

The result is a single HTTP call: `POST /fetch` with a URL, response with page content. No session to create, no session to destroy.

## When to use fetch vs full browser

| Scenario | Right tool |
|---|---|
| Read a documentation page | Stateless fetch |
| Scrape structured data from a static site | Stateless fetch |
| Gather context before taking action | Stateless fetch |
| Fill a form and submit | Full browser session |
| Navigate a multi-step authentication flow | Full browser session |
| Click, scroll, interact with dynamic UI | Full browser session |
| Take a screenshot of a rendered page | Full browser session (or fetch with screenshot option) |

The rule of thumb: if the agent needs to *observe* the web, use fetch. If it needs to *act on* the web, use a browser.

## Cost and latency profile

Stateless fetch is significantly cheaper than full browser sessions. Browser platforms typically price sessions by duration and compute; a fetch-based API prices by page. At ~$1 per 1,000 pages, the cost for read-heavy agent workflows is an order of magnitude lower than the equivalent in browser sessions.

Latency follows the same pattern — a stateless fetch returns in milliseconds to low seconds, versus 2–10 seconds to provision and warm a browser session.

For agents that gather web context before reasoning (a common pattern in research and intelligence workflows), the accumulated difference across thousands of fetches is substantial. See [[Pipeline Cost Per Run]] for how this compounds at scale.

## Relationship to full browser agents

Stateless fetch and browser automation aren't competing approaches — they're complementary layers. Many agent architectures use both:

1. **Fetch first** — retrieve the page to understand what's there
2. **Browser second** — if interaction is needed, launch a session with the prior context already loaded

This mirrors how humans browse: read to orient, then act. The fetch layer handles most of the web surface; the browser layer handles the interactive minority.

For agents that do need full visual interpretation of rendered pages, see [[Vision-First Browser Agents]] — a pattern where agents interpret screenshots rather than DOM structure.

## Implications for agent design

Stateless fetch APIs encourage a cleaner separation of concerns in agent tool design:

- **Read tools** — fast, cheap, stateless (fetch)
- **Action tools** — slower, stateful, session-based (browser, APIs, CLI)

Designing agents with this separation reduces unnecessary infrastructure cost and makes the tool-use surface easier to reason about. An agent that defaults to spawning a browser for every web interaction is paying the session overhead even when it doesn't need it.

The broader principle: match the primitive to the task. Right-sizing tool use is as important in agent systems as it is in software architecture generally.

## Related concepts

- [[Vision-First Browser Agents]] — when agents need to interpret visual page state rather than just content
- [[Autonomous Intelligence Sourcing]] — pipelines that continuously fetch and process web content
- [[Continuous Ingestion]] — architectural patterns for ongoing web data collection
- [[Pipeline Cost Per Run]] — modeling and optimizing per-operation costs in agent pipelines
- [[Agent Sandboxing Environments]] — isolating agent tool use for safety and observability
