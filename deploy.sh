#!/bin/bash
set -e

PIPELINE_ID="website-deploy"
MC_URL="http://localhost:7474"
START=$(date +%s%3N)

log_event() {
  curl -s -X POST "$MC_URL/api/pipelines/$PIPELINE_ID/event" \
    -H "Content-Type: application/json" \
    -d "{\"status\":\"$1\",\"message\":\"$2\"}" > /dev/null 2>&1 || true
}

cd "$(dirname "$0")"

log_event "running" "Build started"

echo "🔨 Building..."
npx quartz build 2>&1
log_event "running" "Build complete — pushing to gh-pages"

echo "🚀 Deploying to gh-pages..."
rm -rf /tmp/gh-deploy
git clone --branch gh-pages https://github.com/new01/field-notes.git /tmp/gh-deploy 2>&1 | tail -2
rm -rf /tmp/gh-deploy/*
cp -r public/. /tmp/gh-deploy/
touch /tmp/gh-deploy/.nojekyll

cd /tmp/gh-deploy
git add -A
COMMIT_REF=$(git -C /home/monolith/Projects/claw-website log --oneline -1 main)
git commit -m "deploy: $(date '+%Y-%m-%d %H:%M') — $COMMIT_REF"
git push origin gh-pages

DURATION=$(( $(date +%s%3N) - START ))
log_event "success" "Deployed in ${DURATION}ms — https://new01.github.io/field-notes/"

echo "✅ Deployed — https://new01.github.io/field-notes/ (${DURATION}ms)"
