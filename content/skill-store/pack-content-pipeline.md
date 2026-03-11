---
title: "Skill Pack: Content Pipeline"
description: Draft blog posts, run SEO analysis, and cross-post to social platforms with OpenClaw skills.
tags: [skill-store, skill-pack, content, marketing, openclaw]
---

# Skill Pack: Content Pipeline

A pack of 3 skills for solo creators and small marketing teams. Turns a topic or outline into a published blog post with SEO metadata and social media variants — all from your terminal.

---

## What's Inside

### 1. Blog Post Drafter
Takes a topic, target audience, and optional outline. Produces a structured blog post draft in markdown with frontmatter, headings, and a call-to-action. Adapts tone by reading existing posts in the target directory to match the site's voice.

### 2. SEO Analyzer
Reads a draft markdown file and evaluates: title tag length, meta description quality, heading hierarchy, keyword density, readability score, and internal link opportunities. Outputs a checklist of actionable improvements.

### 3. Social Cross-Poster
Takes a published blog post URL and generates platform-specific variants: a Twitter/X thread (280-char chunks with hooks), a LinkedIn post (professional tone, 1300 chars), and a Hacker News submission title. Each variant links back to the original post.

---

## Details

| Field | Value |
|-------|-------|
| Price | $12 one-time |
| Skills included | 3 |
| Target user | Solo creators, indie hackers, small marketing teams |
| Requires | OpenClaw v0.2+ |
| Install | `openclaw skill install store:content-pipeline` |

---

## Pack Structure

```
content-pipeline/
├── SKILL.md                # Pack manifest and metadata
├── blog-drafter/
│   └── SKILL.md            # Blog post generation instructions
├── seo-analyzer/
│   └── SKILL.md            # SEO audit instructions
├── social-crossposter/
│   └── SKILL.md            # Social media variant generation
└── tests/
    ├── blog-drafter.test.md
    └── seo-analyzer.test.md
```

---

## Related

- [[skill-store/index|OpenClaw Skill Store]]
- [[concepts/skill-based-agent-architecture|Skill-Based Agent Architecture]]
