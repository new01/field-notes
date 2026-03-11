---
title: Tweet Format Taxonomy
description: A classified set of tweet formats for an AI workflow builder account, designed for systematic split-testing and format retirement
tags: [concepts, content, distribution, twitter, openclaw]
---

A classified set of tweet formats for an AI workflow builder account, designed for split-testing performance over time. Each draft is tagged with its format. Post rates are tracked. Formats with persistent low post rates get retired.

## Account positioning

Helping people building and running AI workflows. Information and resources. Content builds trust; trust converts to customers. The content is the pitch — no explicit self-promotion in individual tweets.

## The formats

### Format A — Incident → Lesson

The anchor format. First-person story: something specific happened, it surprised or broke something, here's the named lesson and what changes because of it.

**Template:** [Setup — what you tried] → [What went wrong, specific details] → [Two words: Named Lesson] → [What you do now] → [Optional humble closer]

**Rules:**
- Incident must be real and specific (dollar amounts, tool names, exact consequences)
- Lesson gets a name — capitalized like a proper noun
- Narrative connectives preserved: "About an hour later", "After that", "Turns out"
- Self-aware, not defensive

**Best for:** Hard-won lessons. The kind of tweet that makes someone think "I was about to do that exact thing."

---

### Format B — Content Ingest Insight

Processes a research or learning pipeline publicly. Something learned from a video, article, or thread — framed as a personal insight, not a summary.

**Template:** [Vague or named source reference] → [The specific thing they said] → [Why it reframes something you were already thinking] → [What you'd do differently]

**Best for:** Turning a research pipeline into content without extra work. Positions the account as someone who reads widely and synthesizes, not just builds.

---

### Format C — Sharp Take

One counterintuitive claim about AI or agent building, stated plainly. No story needed. High variance — can be ignored or hit big.

**Template:** [The claim] → [One sentence of why] → [Optional: what most people do instead]

**Example:** "Sequential agents outperform parallel swarms on almost every real benchmark. The parallelism is usually theater."

**Best for:** Standing out. These age poorly if wrong, so only post if genuinely held.

---

### Format D — What I Built / Shipped

Field report on something that now exists. Not an announcement — more like a dispatch.

**Template:** [What was built, one sentence] → [The problem it solved, specific] → [One surprising thing about building it] → [Optional link]

**Best for:** Demonstrating active building. Compounds into a visible body of work over time.

---

### Format E — Pattern With Context

A named pattern or technique, introduced through the situation that makes it necessary — not as a definition.

**Template:** [The situation where you'd need this] → [What most people do and why it breaks] → [The pattern name + what it does instead]

**Best for:** Teaching reusable concepts without reading like documentation.

---

## Starting blend (daily batch of 6)

| Slot | Format | Source |
|------|--------|--------|
| D1 | A | original |
| D2 | A | original |
| D3 | B | content-ingest pipeline |
| D4 | C | original |
| D5 | D or E | build update or pattern |
| D6 | wildcard | any |

## Performance tracking

Every draft gets logged with its format type, source (original / repurposed / content-ingest), and status (drafted → posted or killed, with kill reason).

**Review every 30 posts.** Formats with >60% kill rate after 20 samples are candidates for retirement. Winning formats get more slots.

## Humanizer rules

**Strip:** corporate AI patterns — leverage, robust, seamless, worth noting, at its core, key takeaway.

**Never strip:** narrative connectives — "About an hour later", "After that", "Because it", "Turns out", "Glad I", "So now".

The connectives are how humans tell stories. Removing them produces incoherent fragments that read like bullet points with punctuation stripped.

## Related

- [[Agent Memory]] — research pipeline that feeds Format B content
- [[Self-Improvement System]] — the broader observability loop that surfaces content opportunities
