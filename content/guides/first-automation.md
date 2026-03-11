---
title: Your First Automation — The Morning Brief
description: Step-by-step guide to building a daily digest that runs autonomously and delivers to Telegram or Discord
tags: [guides, automation, cron, morning-brief, telegram, discord]
---

# Your First Automation — The Morning Brief

The morning brief is the canonical first OpenClaw automation. It's a daily digest that assembles while you sleep and delivers to your phone before you're out of bed. Simple enough to build in a session. Complex enough to prove the full stack works.

More importantly: it's useful. Unlike "hello world" scripts that exist to demonstrate a capability, the morning brief is something you'll actually check every morning.

## What the Morning Brief Is

A cron-triggered script that runs at a fixed time each morning, assembles a digest of relevant information, and delivers it to Discord or Telegram.

A basic brief covers:

- **Yesterday's build activity** — what was committed, what was queued, what completed
- **Top HN stories** — 3-5 relevant to what you're building (filtered by keyword)
- **Weather** — only if it's relevant (travel, outdoor work, etc.)
- **Calendar events** — next 24 hours
- **Outstanding items** — anything flagged for your attention, stuck queue items, failed cron jobs

The content mix is yours to define. Start minimal — you can always add more after proving it works.

## The Cron Setup

### Step 1: Create the brief script

Create `scripts/morning-brief.js` in your workspace:

```javascript
#!/usr/bin/env node
// Morning Brief — runs daily via cron

const { execSync } = require('child_process');
const fs = require('fs');
const https = require('https');

async function fetchHN(query) {
  const url = `https://hn.algolia.com/api/v1/search_by_date?query=${encodeURIComponent(query)}&hitsPerPage=10&tags=story`;
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

async function buildBrief() {
  const lines = [];
  const now = new Date();
  lines.push(`**Morning Brief — ${now.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}**`);
  lines.push('');

  // HN digest
  try {
    const hn = await fetchHN('AI agents autonomous');
    const cutoff = Date.now() - (24 * 60 * 60 * 1000);
    const recent = hn.hits
      .filter(h => new Date(h.created_at).getTime() > cutoff && h.points > 10)
      .slice(0, 3);

    if (recent.length > 0) {
      lines.push('**📰 HN Today**');
      recent.forEach(h => lines.push(`• [${h.title}](${h.url || 'https://news.ycombinator.com/item?id=' + h.objectID}) (${h.points} pts)`));
      lines.push('');
    }
  } catch (e) {
    lines.push('*HN fetch failed*');
    lines.push('');
  }

  // Build queue status
  const queuePath = process.env.QUEUE_PATH || `${process.env.HOME}/.openclaw/workspace/build-queue.json`;
  if (fs.existsSync(queuePath)) {
    try {
      const queue = JSON.parse(fs.readFileSync(queuePath, 'utf8'));
      const inProgress = queue.filter(i => i.status === 'in-progress');
      const pending = queue.filter(i => i.status === 'queued' || i.status === 'pending');
      lines.push('**🏗️ Build Queue**');
      if (inProgress.length > 0) lines.push(`• In progress: ${inProgress.map(i => i.title).join(', ')}`);
      if (pending.length > 0) lines.push(`• Queued: ${pending.length} item${pending.length > 1 ? 's' : ''}`);
      lines.push('');
    } catch (e) {
      // queue parse error — skip
    }
  }

  return lines.join('\n');
}

buildBrief().then(brief => {
  process.stdout.write(brief);
}).catch(err => {
  process.stderr.write(`Morning brief failed: ${err.message}\n`);
  process.exit(1);
});
```

### Step 2: Create the cron wrapper

OpenClaw's cron infrastructure expects a wrapper script. Create `cron/morning-brief.sh`:

```bash
#!/bin/bash
# Morning Brief cron wrapper

WORKSPACE="$HOME/.openclaw/workspace"
LOG_DIR="$WORKSPACE/logs/cron"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/morning-brief-$TIMESTAMP.log"

echo "[$(date)] Morning brief starting" >> "$LOG_FILE"

# Run the brief script and capture output
BRIEF=$(node "$WORKSPACE/scripts/morning-brief.js" 2>> "$LOG_FILE")

if [ $? -ne 0 ]; then
  echo "[$(date)] Brief script failed" >> "$LOG_FILE"
  exit 1
fi

# Send to Discord or Telegram via openclaw CLI
openclaw message --channel discord --target "user:YOUR_USER_ID" --message "$BRIEF"

echo "[$(date)] Morning brief delivered" >> "$LOG_FILE"
```

Replace `YOUR_USER_ID` with your Discord user ID. For Telegram, change the channel and target accordingly.

### Step 3: Register the cron

```bash
crontab -e
```

Add this line (delivers at 7:30 AM daily):

```
30 7 * * * bash /home/user/.openclaw/workspace/cron/morning-brief.sh >> /home/user/.openclaw/workspace/logs/cron/morning-brief-cron.log 2>&1
```

Adjust the path to match your workspace location.

---

## Connecting to Telegram or Discord

### Discord

Your brief uses the OpenClaw CLI:

```bash
openclaw message --channel discord --target "user:DISCORD_USER_ID" --message "$BRIEF"
```

Get your Discord user ID: open Discord, go to Settings → Advanced → turn on Developer Mode, then right-click your username in any message and "Copy User ID."

Make sure the Discord channel is configured in `openclaw.json` and the gateway is running.

### Telegram

```bash
openclaw message --channel telegram --target "TELEGRAM_CHAT_ID" --message "$BRIEF"
```

Your Telegram chat ID: start a conversation with the bot, then hit `https://api.telegram.org/bot<TOKEN>/getUpdates` to find the chat_id in the response.

---

## Verifying It Works End-to-End

Don't wait until 7:30 AM to find out it's broken. Test it now.

### Step 1: Run the script directly

```bash
node ~/.openclaw/workspace/scripts/morning-brief.js
```

Does it print a brief? If it errors, fix before proceeding.

### Step 2: Run the wrapper

```bash
bash ~/.openclaw/workspace/cron/morning-brief.sh
```

Does it deliver to Discord/Telegram? Check the log file for errors:

```bash
tail -f ~/.openclaw/workspace/logs/cron/morning-brief-*.log
```

### Step 3: Verify the cron is registered

```bash
crontab -l | grep morning-brief
```

If nothing returns, the cron wasn't saved.

### Step 4: Trigger a test run

Change the cron time temporarily to 2 minutes from now, wait, confirm it delivers, then set it back.

```bash
# Temporarily set to 2 min from now for testing
34 14 * * * bash /path/to/morning-brief.sh >> /path/to/log 2>&1
# After confirming delivery, set back to 7:30 AM
```

---

## What to Add Next

Once the basic brief is running reliably, layer in more signals.

### Weather

```javascript
// Add to buildBrief()
const weather = await fetch('https://wttr.in/San+Francisco?format=3');
const weatherText = await weather.text();
lines.push(`**🌤️ Weather**`);
lines.push(`• ${weatherText.trim()}`);
lines.push('');
```

### Build queue failures

Add detection for queue items stuck in "in-progress" for more than 2 hours — likely a failed run that needs attention.

### Failed cron jobs

Scan the cron log directory for recent files with error keywords:

```javascript
const logDir = path.join(workspace, 'logs/cron');
const recentLogs = fs.readdirSync(logDir)
  .filter(f => fs.statSync(path.join(logDir, f)).mtime > new Date(Date.now() - 86400000))
  .filter(f => fs.readFileSync(path.join(logDir, f), 'utf8').includes('failed'));
```

### Dead-man's switch status

Check if the proof-of-life timestamp is fresh. If the agent heartbeat hasn't fired in over 90 minutes, the brief should flag it. See [[concepts/dead-mans-switch|Dead-Man's Switch]] for how this watchdog pattern works.

### Calendar events

Use a Google Calendar API call (requires OAuth setup) or pull from a local cal file if you sync to `~/.calendar`.

---

## Common Problems

**Cron fires but message never arrives.** Check: is the gateway running? (`openclaw gateway status`). Is the channel configured? Run the `openclaw message` command manually to verify it works outside of cron.

**Brief script works locally but fails in cron.** Cron uses a minimal environment. Check that `node` is on the PATH in cron context: add `PATH=/usr/local/bin:/usr/bin:/bin` to the top of your crontab.

**Logs show success but no message.** The `openclaw message` call might be succeeding with an empty or incorrectly formatted message. Log the brief content before sending it.

**Times off by hours.** Cron runs in the system timezone, not your configured timezone. Check `date` vs what the cron delivers. You may need to set `TZ=America/Los_Angeles` in your crontab.

---

## Related

- [[infrastructure/cron-infrastructure|Cron Infrastructure]] — how OpenClaw's cron system is structured, logging patterns, failure handling
- [[infrastructure/notification-batching|Notification Batching]] — preventing your automation from becoming noise
- [[concepts/dead-mans-switch|Dead-Man's Switch]] — how to know when your automation has silently stopped
