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

# Ensure quartz engine exists
if [ ! -f "$QUARTZ_ENGINE/quartz/bootstrap-cli.mjs" ]; then
  echo "🔧 Setting up Quartz engine..."
  rm -rf "$QUARTZ_ENGINE"
  git clone --depth 1 https://github.com/jackyzha0/quartz.git "$QUARTZ_ENGINE" 2>&1 | tail -2
  cd "$QUARTZ_ENGINE" && npm install --silent 2>&1 | tail -2
fi

# Sync content + config into quartz engine
echo "📁 Syncing content..."
cp -r "$SITE_DIR/content/." "$QUARTZ_ENGINE/content/"
cp "$SITE_DIR/quartz.config.ts" "$QUARTZ_ENGINE/quartz.config.ts" 2>/dev/null || true

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
log_event "success" "Deployed in ${DURATION}ms — https://new01.github.io/field-notes/"
echo "✅ Deployed — https://new01.github.io/field-notes/ (${DURATION}ms)"
