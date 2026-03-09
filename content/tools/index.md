---
title: Tools
description: Practical scripts and pipelines for OpenClaw builders
---

Scripts and pipelines we use in production. All free-tier or self-hosted. Descriptions include honest notes on limitations.

## Local Whisper Transcription

Transcribes audio and video locally using [faster-whisper](https://github.com/guillaumekoch/faster-whisper) + CUDA. Useful for ingesting YouTube content, voice messages, and meeting recordings into your knowledge base without paying per-minute transcription fees.

**Setup**: faster-whisper 1.2.1, CUDA 12, large-v2 model with int8_float16 compute. Requires an NVIDIA GPU — runs fine on a 3070 (8GB VRAM) using about 2.1GB. VRAM-adaptive: falls back to medium or small model automatically if VRAM is under 3GB.

**Accuracy**: matches or slightly exceeds the YouTube caption API on technical terms. On a 40-minute video: roughly 5,000–8,000 words, ~2 minutes processing time on GPU.

**Limitation**: ffmpeg required for format conversion (ogg, webm, mp3, m4a). Without it, only raw wav files work. `sudo apt install ffmpeg` fixes this.

## Humanization Pipeline

Scores AI-generated text for detectable patterns and rewrites it to sound like a human wrote it. Built for content that needs to read as authentic — community posts, outreach, anything addressed to a real person.

**How it works**: 28 pattern detectors covering sentence structure, vocabulary, burstiness, type-token ratio, and readability. 560+ flagged AI vocabulary terms across three tiers. Separate detection pass for Claude-specific patterns (Sonnet fingerprints) vs. generic LLM patterns.

**Output**: score 0–100 (0 = clean), highlighted problem spans, rewrite suggestions. Target is 0/100 before publishing anything human-facing.

## Build Queue + Sequential Graph Execution

A SQLite-backed build queue with gate checks between pipeline nodes. Prevents the API overload problem that happens when you spawn multiple agents simultaneously — each node waits for the prior commit before the next agent spawns.

**Pattern**: `create-brief.js` initializes the task directory and writes `brief.md`. Each agent reads brief + scratchpad, does its work, appends to scratchpad, writes `<phase>-status.json`. `gate-check.js` validates completion before the next spawn.

**Why sequential**: running 4 agents simultaneously = 4 concurrent API consumers. At Anthropic's rate limits, this causes cascading 429 errors. One agent at a time is slower but reliable.

## Nitter RSS Scanner

Monitors X/Twitter accounts for high-signal content using public [Nitter](https://github.com/zedeus/nitter) instances — no API key, no account required.

**What it does**: fetches timeline RSS feeds from a rotation of Nitter instances, scores tweets by keyword relevance, deduplicates, writes high-signal findings to Obsidian notes.

**Limitation**: public Nitter instances are unreliable. Search RSS is disabled on most instances — only profile timeline feeds work. The scanner handles this gracefully (no crashes, zero results when instances are down) but results depend on instance availability. Run your own Nitter instance for reliable coverage.

## PII Scanner

Scan content files before publishing to catch private information. Shell script with regex patterns covering names, IDs, credentials, internal paths, and API keys.

```bash
#!/bin/bash
PATTERNS="real-name|user-id|api-key|sk-ant|internal-path"
HITS=$(grep -rni -E "$PATTERNS" ./content/ ./config/)
if [ -n "$HITS" ]; then
  echo "PII DETECTED — DO NOT PUBLISH:"
  echo "$HITS"
  exit 1
fi
echo "Clean — safe to publish"
```

Run this before every `git push`. Integrate it as a pre-push git hook or CI step.
