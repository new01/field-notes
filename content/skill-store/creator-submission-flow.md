---
title: Creator Submission Flow
description: How skill pack creators submit, get scanned, and start selling on the OpenClaw Skill Store.
tags: [skill-store, creators, submission, openclaw]
---

# Creator Submission Flow

The end-to-end process for getting a skill pack listed on the OpenClaw Skill Store. Phase 1 uses Tally for intake and Gumroad for payments — zero custom infrastructure required.

---

## Submission Form Fields (Tally)

The creator application form collects the following:

### Creator Info
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Name | Text | Yes | Display name on store listing |
| Email | Email | Yes | For review status notifications |
| GitHub username | Text | Yes | For identity verification |
| Portfolio / website | URL | No | Helps establish credibility |

### Skill Pack Details
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Pack name | Text | Yes | URL-safe slug auto-generated |
| One-line description | Text (100 chars) | Yes | Shown in browse/search |
| Full description | Long text | Yes | Markdown supported |
| Category | Dropdown | Yes | Productivity / Automation / Integrations / Agents / Other |
| Skills included | Number | Yes | Count of individual skills in the pack |
| Skill list | Long text | Yes | Name + one-line description per skill |
| Pricing model | Radio | Yes | One-time / Subscription |
| Price | Number | Yes | In USD. Range: $5–$49 one-time, $9/mo subscription |
| Target user | Text | Yes | Who is this built for? |
| OpenClaw version requirement | Text | Yes | Minimum compatible version |
| External dependencies | Long text | No | APIs, CLI tools, or services required |

### Pack Upload
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| Pack ZIP file | File upload | Yes | Must contain SKILL.md at root |
| Demo video or screenshots | File upload | No | Helps conversion; strongly recommended |
| Test results | File upload | No | Output of running pack tests |

---

## Review Pipeline

```
Creator submits form
        ↓
  Tally webhook fires
        ↓
  Manual review queue
        ↓
  VirusTotal scan (all files in ZIP)
        ↓
  ┌─── Clean? ───┐
  │              │
  Yes            No
  │              │
  Structure      Notify creator
  review         with findings
  │              │
  ┌─── Valid? ──┐  (resubmit)
  │             │
  Yes           No
  │             │
  Create        Request
  Gumroad       fixes
  listing       │
  │          (resubmit)
  ↓
  Notify creator: "Your pack is live"
  ↓
  Add to store listing page
```

### Structure Review Checklist

- [ ] SKILL.md exists at pack root
- [ ] Each skill has its own SKILL.md with clear instructions
- [ ] No hardcoded paths, API keys, or credentials
- [ ] No network calls outside of documented dependencies
- [ ] Tests exist and descriptions match actual behavior
- [ ] Pack installs cleanly on a fresh OpenClaw setup

---

## Phase 1 Payment Flow (Gumroad)

1. Approved pack gets a Gumroad product page created manually
2. Store listing links to the Gumroad purchase page
3. After purchase, buyer receives ZIP download via Gumroad
4. Buyer extracts to their OpenClaw skills directory
5. Gumroad handles payment processing, tax, and creator payouts

**Gumroad fee:** 10% — acceptable for MVP. Phase 2 moves to Stripe direct (platform takes 30%, creator gets 70%, net lower fees than Gumroad for buyers).

---

## Creator Revenue Share

| Period | Creator Share | Platform Share |
|--------|-------------|---------------|
| First 90 days | 80% | 20% |
| After 90 days | 70% | 30% |

Gumroad pays creators directly in Phase 1. Platform share is the Gumroad fee (10%) plus any difference retained.

---

## Related

- [[skill-store/index|OpenClaw Skill Store]]
- [[skill-store/virustotal-integration|VirusTotal Integration Plan]]
