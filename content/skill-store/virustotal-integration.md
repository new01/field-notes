---
title: VirusTotal Integration Plan
description: Security scanning pipeline for OpenClaw Skill Store submissions using the VirusTotal API.
tags: [skill-store, security, virustotal, scanning, openclaw]
---

# VirusTotal Integration Plan

Every skill pack submitted to the OpenClaw Skill Store is security-scanned before listing. Phase 1 uses the VirusTotal API (free tier) for file scanning. This document defines the integration approach, API usage, and escalation logic.

---

## Why VirusTotal

- 70+ antivirus engines scan each file
- Free tier: 4 lookups/minute, 500 lookups/day — sufficient for Phase 1 volume
- REST API with straightforward file upload and hash-based lookup
- Industry standard for malware detection

ClawhHub's 1,184+ malicious skills demonstrate the risk of unscanned skill directories. Security scanning is the store's core differentiator.

---

## Scan Flow

```
ZIP received from creator submission
        ↓
  Extract all files from ZIP
        ↓
  For each file:
    1. Compute SHA-256 hash
    2. Check VirusTotal by hash (GET /files/{hash})
    3. If unknown → upload file (POST /files)
    4. Poll for analysis completion
        ↓
  Aggregate results
        ↓
  ┌─── Any detections? ───┐
  │                       │
  Zero detections         1+ detections
  │                       │
  PASS → proceed          FAIL → notify creator
  to structure review     with detection details
```

---

## API Integration (Phase 1 — Manual/Script)

### Endpoints Used

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/v3/files/{id}` | GET | Check if file hash is already known |
| `/api/v3/files` | POST | Upload file for scanning |
| `/api/v3/analyses/{id}` | GET | Poll for scan results |

### Rate Limits (Free Tier)

| Limit | Value |
|-------|-------|
| Requests per minute | 4 |
| Requests per day | 500 |
| Max file size | 32 MB |

At Phase 1 volume (estimated 2–5 submissions per week), the free tier is more than sufficient. A typical skill pack ZIP contains 5–15 files, requiring 5–15 lookups per submission.

### Script Stub

```bash
#!/bin/bash
# scan-pack.sh — scan a skill pack ZIP against VirusTotal
# Usage: ./scan-pack.sh <path-to-zip>

VT_API_KEY="${VIRUSTOTAL_API_KEY}"
WORK_DIR=$(mktemp -d)
PACK_ZIP="$1"

if [ -z "$PACK_ZIP" ] || [ -z "$VT_API_KEY" ]; then
  echo "Usage: VIRUSTOTAL_API_KEY=<key> ./scan-pack.sh <pack.zip>"
  exit 1
fi

# Extract
unzip -q "$PACK_ZIP" -d "$WORK_DIR"

PASS=true
for FILE in $(find "$WORK_DIR" -type f); do
  HASH=$(sha256sum "$FILE" | cut -d' ' -f1)
  FNAME=$(basename "$FILE")

  # Check by hash first
  RESPONSE=$(curl -s --request GET \
    --url "https://www.virustotal.com/api/v3/files/$HASH" \
    --header "x-apikey: $VT_API_KEY")

  DETECTIONS=$(echo "$RESPONSE" | jq -r '.data.attributes.last_analysis_stats.malicious // 0')

  if [ "$DETECTIONS" = "null" ] || [ "$DETECTIONS" = "0" ]; then
    # Unknown or clean — upload if unknown
    if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
      echo "[$FNAME] Unknown — uploading for scan..."
      curl -s --request POST \
        --url "https://www.virustotal.com/api/v3/files" \
        --header "x-apikey: $VT_API_KEY" \
        --form "file=@$FILE"
      sleep 15  # Rate limit: 4/min
    else
      echo "[$FNAME] CLEAN (0 detections)"
    fi
  else
    echo "[$FNAME] FLAGGED ($DETECTIONS detections)"
    PASS=false
  fi

  sleep 15  # Rate limit
done

rm -rf "$WORK_DIR"

if [ "$PASS" = true ]; then
  echo "RESULT: PASS — all files clean"
  exit 0
else
  echo "RESULT: FAIL — one or more files flagged"
  exit 1
fi
```

---

## Decision Logic

| Detections | Action |
|-----------|--------|
| 0 | Pass — proceed to structure review |
| 1–2 | Manual review — could be false positive. Check engine names and file type. |
| 3+ | Auto-reject — notify creator with detection details |

---

## Phase 2 Upgrades

- Automated pipeline triggered by Tally webhook (no manual step)
- Premium VirusTotal API for higher rate limits
- Static analysis layer: scan SKILL.md for suspicious patterns (curl to unknown hosts, eval(), encoded payloads)
- Scan results stored in database with timestamps for audit trail
- Re-scan existing packs periodically (monthly) against updated engine signatures

---

## Related

- [[skill-store/index|OpenClaw Skill Store]]
- [[skill-store/creator-submission-flow|Creator Submission Flow]]
