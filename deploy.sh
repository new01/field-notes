#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "🔨 Building..."
npx quartz build

echo "🚀 Deploying to gh-pages..."
rm -rf /tmp/gh-deploy
git clone --branch gh-pages https://github.com/new01/field-notes.git /tmp/gh-deploy
rm -rf /tmp/gh-deploy/*
cp -r public/. /tmp/gh-deploy/
touch /tmp/gh-deploy/.nojekyll

cd /tmp/gh-deploy
git add -A
git commit -m "deploy: $(date '+%Y-%m-%d %H:%M') — $(git -C /home/monolith/Projects/claw-website log --oneline -1 main)"
git push origin gh-pages

echo "✅ Deployed — https://new01.github.io/field-notes/"
