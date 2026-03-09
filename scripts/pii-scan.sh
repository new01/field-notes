#!/bin/bash
# Pre-publish quality gate — run before every git push or GitHub Pages deploy
# Two passes: PII/sensitive info + accuracy checklist

set -e

echo "======================================="
echo " Pre-publish quality gate"
echo "======================================="

# --- Pass 1: PII and sensitive info ---
echo ""
echo "Pass 1: PII scan..."
PATTERNS="adevine|awesomewesly|ashan|devine|217886|168821|monussy|swift\.me|vxvtactics|a17delta|nytfal|wesley|monolith|localhost|7474|sk-ant|api_key=|API_KEY="
HITS=$(grep -rni -E "$PATTERNS" ./content/ ./quartz.config.ts ./quartz.layout.ts 2>/dev/null || true)
if [ -n "$HITS" ]; then
  echo "❌ PII DETECTED — fix before publishing:"
  echo "$HITS"
  exit 1
fi
echo "✅ PII scan clean"

# --- Pass 2: Accuracy checklist (manual confirmation required) ---
echo ""
echo "Pass 2: Accuracy checklist"
echo ""
echo "Confirm the following before proceeding:"
echo ""
echo "  [ ] OpenClaw described as a self-hosted GATEWAY (not 'runs models locally')"
echo "  [ ] Multi-provider support mentioned (not Claude-only)"
echo "  [ ] No claims about features you haven't personally verified"
echo "  [ ] External tool descriptions (Whisper, Nitter, etc.) checked against current reality"
echo "  [ ] All wikilinks point to pages that actually exist in content/"
echo "  [ ] No internal references leaked (paths, IDs, URLs)"
echo ""
echo "Run: grep -r '\[\[' content/ | grep -v '\.md:' to list all wikilinks"
echo "Run: npm run build to confirm all links resolve"
echo ""
echo "If all items above are confirmed, the site is clear to publish."
echo ""
echo "✅ Gate script complete — manual accuracy check required above"

# --- Pass 3: Wikilink validation (automated) ---
echo ""
echo "Pass 3: Wikilink validation..."
BROKEN=0
while IFS= read -r match; do
  FILE=$(echo "$match" | cut -d: -f1)
  LINK=$(echo "$match" | grep -oP '\[\[\K[^|\]]+' | head -1)
  [ -z "$LINK" ] && continue
  TARGET="./content/${LINK}.md"
  if [ ! -f "$TARGET" ]; then
    echo "  BROKEN: $FILE -> [[$LINK]]"
    BROKEN=$((BROKEN+1))
  fi
done < <(grep -rn "\[\[" ./content/ 2>/dev/null || true)

if [ "$BROKEN" -gt 0 ]; then
  echo "❌ $BROKEN broken wikilinks — fix before publishing"
  exit 1
fi
echo "✅ All wikilinks resolve"
