#!/bin/bash
# Ralph Template Installer
# Run: curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/ralph-template/main/install.sh | bash

set -e

echo "🤖 Installing Ralph Template..."

# Create directories
mkdir -p scripts
mkdir -p .agent/workflows

# Download template files
REPO="https://raw.githubusercontent.com/YOUR_USERNAME/ralph-template/main"

echo "📥 Downloading files..."

curl -sSL "$REPO/templates/PROMPT.md" -o PROMPT.md
curl -sSL "$REPO/templates/@fix_plan.md" -o @fix_plan.md
curl -sSL "$REPO/templates/@AGENT.md" -o @AGENT.md
curl -sSL "$REPO/templates/status.json" -o status.json
curl -sSL "$REPO/scripts/safety-check.js" -o scripts/safety-check.js
curl -sSL "$REPO/workflows/feature.md" -o .agent/workflows/feature.md
curl -sSL "$REPO/workflows/verify.md" -o .agent/workflows/verify.md
curl -sSL "$REPO/playwright.config.ts" -o playwright.config.ts

echo "📦 Installing Playwright..."
pnpm add -D @playwright/test
pnpm exec playwright install chromium

echo ""
echo "✅ Ralph installed!"
echo ""
echo "Next steps:"
echo "  1. Add verify scripts to package.json (see README)"
echo "  2. Edit scripts/safety-check.js with your prod project refs"
echo "  3. Use /feature to start developing"
echo ""
