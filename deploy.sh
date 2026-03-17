#!/bin/bash
set -e

PIPELINE_ID="website-deploy"
MC_URL="http://localhost:7474"
START=$(date +%s%3N)
QUARTZ_ENGINE="/tmp/quartz-engine"
SITE_DIR="$(cd "$(dirname "$0")" && pwd)"

log_event() {
  curl -s -X POST "$MC_URL/api/pipelines/$PIPELINE_ID/event" \
    -H "Content-Type: application/json" \
    -d "{\"status\":\"$1\",\"message\":\"$2\"}" > /dev/null 2>&1 || true
}

log_event "running" "Build started"

# Push source to origin/main first
echo "📤 Pushing source to origin/main..."
cd "$SITE_DIR"
git add -A
git diff --cached --quiet || git commit -m "chore: pre-deploy sync $(date '+%Y-%m-%d %H:%M')"
git push origin main 2>&1 | tail -3

# Ensure quartz engine exists
if [ ! -f "$QUARTZ_ENGINE/quartz/bootstrap-cli.mjs" ]; then
  echo "🔧 Setting up Quartz engine..."
  rm -rf "$QUARTZ_ENGINE"
  git clone --depth 1 https://github.com/jackyzha0/quartz.git "$QUARTZ_ENGINE" 2>&1 | tail -2
  cd "$QUARTZ_ENGINE" && npm install --silent 2>&1 | tail -2
fi

# Sync content + config + component overrides into quartz engine
echo "📁 Syncing content..."
cp -r "$SITE_DIR/content/." "$QUARTZ_ENGINE/content/"
cp "$SITE_DIR/quartz.config.ts" "$QUARTZ_ENGINE/quartz.config.ts" 2>/dev/null || true
cp "$SITE_DIR/quartz.layout.ts" "$QUARTZ_ENGINE/quartz.layout.ts" 2>/dev/null || true
# Copy component overrides (patches to quartz internals)
if [ -d "$SITE_DIR/overrides/components" ]; then
  cp "$SITE_DIR/overrides/components/"*.tsx "$QUARTZ_ENGINE/quartz/components/" 2>/dev/null || true
fi
# Copy style overrides
if [ -d "$SITE_DIR/overrides/styles" ]; then
  cp "$SITE_DIR/overrides/styles/"*.scss "$QUARTZ_ENGINE/quartz/styles/" 2>/dev/null || true
fi
# Copy util overrides (e.g. patched theme.ts for Google Fonts URL encoding)
if [ -d "$SITE_DIR/overrides/util" ]; then
  cp "$SITE_DIR/overrides/util/"*.ts "$QUARTZ_ENGINE/quartz/util/" 2>/dev/null || true
fi

# Build
echo "🔨 Building..."
cd "$QUARTZ_ENGINE"
node quartz/bootstrap-cli.mjs build 2>&1 | tail -5
log_event "running" "Build complete — pushing to gh-pages"

# Deploy to gh-pages
echo "🚀 Deploying to gh-pages..."
GH_DEPLOY="/tmp/gh-deploy-$$"
git clone --depth 1 --branch gh-pages https://github.com/new01/field-notes.git "$GH_DEPLOY" 2>&1 | tail -2
rm -rf "$GH_DEPLOY"/*
cp -r "$QUARTZ_ENGINE/public/." "$GH_DEPLOY/"
touch "$GH_DEPLOY/.nojekyll"

cd "$GH_DEPLOY"
git add -A
COMMIT_REF=$(git -C "$SITE_DIR" log --oneline -1 main 2>/dev/null || echo "local")
FILE_COUNT=$(find "$QUARTZ_ENGINE/public" -name "*.html" | wc -l)
git commit -m "deploy: $(date '+%Y-%m-%d %H:%M') — $FILE_COUNT pages — $COMMIT_REF"
git push origin gh-pages

rm -rf "$GH_DEPLOY"

DURATION=$(( $(date +%s%3N) - START ))

# Verification — wait for GitHub Pages to propagate, then spot-check 3 pages
echo "🔍 Verifying deployment..."
sleep 15
VERIFY_PASS=0
VERIFY_FAIL=0
VERIFY_URLS=()

# Pick index + 2 most recently modified concept pages
VERIFY_URLS+=("https://new01.github.io/field-notes/")
RECENT=$(find "$SITE_DIR/content" -name "*.md" -not -name "index.md" | xargs ls -t 2>/dev/null | head -2)
for f in $RECENT; do
  slug=$(basename "$f" .md)
  dir=$(basename $(dirname "$f"))
  VERIFY_URLS+=("https://new01.github.io/field-notes/$dir/$slug")
done

for url in "${VERIFY_URLS[@]}"; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")
  if [ "$STATUS" = "200" ]; then
    echo "  ✅ $STATUS $url"
    VERIFY_PASS=$((VERIFY_PASS+1))
  else
    echo "  ❌ $STATUS $url"
    VERIFY_FAIL=$((VERIFY_FAIL+1))
  fi
done

if [ "$VERIFY_FAIL" -gt 0 ]; then
  log_event "warning" "Deployed but $VERIFY_FAIL/$((VERIFY_PASS+VERIFY_FAIL)) spot checks failed — pages may not be live yet"
  echo "⚠️  $VERIFY_FAIL page(s) returned non-200 — GitHub Pages may still be propagating"
else
  log_event "success" "Deployed + verified in ${DURATION}ms — https://new01.github.io/field-notes/"
  echo "✅ Deployed + verified — https://new01.github.io/field-notes/ (${DURATION}ms)"
fi
