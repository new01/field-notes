---
title: OpenClaw Skill Store
description: Security-scanned premium skill packs for OpenClaw. Creators earn 70%. Buyers get verified, production-ready skills.
tags: [skill-store, openclaw, marketplace, skills]
---

# OpenClaw Skill Store

The commercial layer for OpenClaw skills. Creators publish security-scanned skill packs, set their own price, and keep 70% of every sale. Buyers get verified, production-ready skills they can install in one command.

---

## The Problem

The OpenClaw ecosystem has 86,000+ free skills — but no trusted paid tier. ClawhHub has had 1,184+ malicious skills flagged. skills.sh is free-only by design. There is no place where a creator can sell a polished, security-verified skill pack and actually get paid for it.

The Skill Store fills that gap.

---

## How It Works

### For Buyers

1. **Browse** — skill packs organized by category: productivity, automation, integrations, agents
2. **Verify** — every pack carries a security scan badge (VirusTotal-verified, no malicious code)
3. **Buy** — one-time purchase ($5–$49) or creator subscription ($9/mo)
4. **Install** — `openclaw skill install store:<pack-id>`

### For Creators

1. **Build** — a skill pack is a ZIP containing SKILL.md + supporting files + tests
2. **Submit** — fill out the creator application form with your pack details
3. **Scan** — platform runs automated security scanning on every submission
4. **Earn** — 70% revenue share on every sale (80% for the first 90 days)

---

## Pricing

| Type | Price Range | Example |
|------|------------|---------|
| Individual skill | $5–$19 | Single-purpose automation |
| Skill pack (3–5 skills) | $19–$49 | Themed bundle for a workflow |
| Creator subscription | $9/mo | Ongoing updates + new skills |

**Sweet spot:** $19 one-time for a quality pack.

---

## Security First

Every submission is scanned before listing. No exceptions.

- **VirusTotal API** scans all files in every pack
- Packs with any detection flags are rejected and the creator is notified
- Published packs display a verified security badge
- 7-day refund policy for buyers

This is the core differentiator. ClawhHub's malware problem is our opportunity to build the trusted alternative.

---

## Seed Skill Packs

Launch packs built by the platform team — available at launch:

- [[skill-store/pack-git-workflow-automator|Git Workflow Automator]] — PR reviews, commit message generation, branch management
- [[skill-store/pack-codebase-onboarding|Codebase Onboarding Kit]] — architecture mapping, dependency analysis, onboarding doc generation
- [[skill-store/pack-content-pipeline|Content Pipeline Pack]] — blog post drafting, SEO analysis, social media cross-posting

---

## Submit a Skill Pack

Ready to publish? [Apply via our creator submission form](https://tally.so) (Tally form — see [[skill-store/creator-submission-flow|Creator Submission Flow]] for details on what to prepare).

---

## Related

- [[concepts/skill-based-agent-architecture|Skill-Based Agent Architecture]]
- [[skill-store/creator-submission-flow|Creator Submission Flow]]
- [[skill-store/virustotal-integration|VirusTotal Integration Plan]]
