#!/bin/bash
# ============================================================
# Convertix — Repository Setup Script
# Run this ONCE after cloning the repo locally.
# It stages all documentation files and pushes the first commit.
# ============================================================

set -e  # exit on any error

echo ""
echo "=============================="
echo " Convertix Repo Setup"
echo "=============================="
echo ""

# Check we're inside a git repo
if [ ! -d ".git" ]; then
  echo "ERROR: Run this script from inside the cloned convertix repo directory."
  echo "Example:"
  echo "  git clone https://github.com/bbethical010-glitch/convertix.git"
  echo "  cd convertix"
  echo "  bash setup_repo.sh"
  exit 1
fi

echo "Git repo detected. Proceeding..."
echo ""

# Check git identity is set
if [ -z "$(git config user.email)" ]; then
  echo "WARNING: git user.email is not set."
  echo "Run: git config --global user.email 'you@example.com'"
  echo "Then re-run this script."
  exit 1
fi

# Stage everything
git add .

# Commit
echo "Creating initial documentation commit..."
git commit -m "docs: initialize Convertix project — 8 core docs + agent prompts

- README.md: project overview, tech stack, status
- SETUP.md: dev environment, signing, AdMob, API 36 requirement
- SPEC.md: full feature specification with all 10 tools
- ARCHITECTURE.md: system design, folder structure, patterns
- CONTRIBUTING.md: git workflow, commit rules, doc sync
- AGENTS.md: AI agent guardrails, hard rules, context
- STATE.md: current blockers (keystore + API 36 deadline)
- ROADMAP.md: phased milestones
- AGENT_PROMPTS.md: phase-by-phase coding agent prompts
- .gitignore: Flutter-appropriate ignore rules

Active blockers (see STATE.md):
- Play Store upload key reset required before v1.0.9 submission
- targetSdkVersion must be 36 before Aug 31 2026"

echo ""
echo "Pushing to origin/main..."
git push origin main

echo ""
echo "=============================="
echo " Done. Repository is ready."
echo "=============================="
echo ""
echo "Next steps:"
echo "1. Verify Play App Signing in Play Console (see STATE.md)"
echo "2. Submit upload key reset request if needed"
echo "3. Open AGENT_PROMPTS.md and give the PHASE 0 prompt to your coding agent"
echo ""
