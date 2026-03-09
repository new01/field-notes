#!/bin/bash
# PII/sensitive info scan — run before every publish action
PATTERNS="adevine|awesomewesly|ashan|devine|217886|168821|monussy|swift\.me|vxvtactics|a17delta|nytfal|wesley|monolith|localhost|7474|mission.control|sk-ant|password|api.key"
echo "Running PII scan..."
HITS=$(grep -rni -E "$PATTERNS" ./content/ ./quartz.config.ts ./quartz.layout.ts 2>/dev/null)
if [ -n "$HITS" ]; then
  echo "❌ PII DETECTED — DO NOT PUBLISH:"
  echo "$HITS"
  exit 1
else
  echo "✅ PII scan clean — safe to publish"
  exit 0
fi
