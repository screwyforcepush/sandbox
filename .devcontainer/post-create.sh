#!/bin/bash
set -euo pipefail

echo "🔒 Setting up secure sandbox environment..."

# Configure git
git config --global user.email "claude-agent@anthropic.com"
git config --global user.name "Claude Agent"

# Switch to the requested branch if BRANCH_NAME is set
if [ -n "${BRANCH_NAME:-}" ]; then
    echo "🌿 Switching to branch: ${BRANCH_NAME}"
    # Find the git repository directory
    REPO_DIR=$(find /workspaces -name .git -type d 2>/dev/null | head -1 | xargs dirname)
    if [ -n "${REPO_DIR}" ] && [ -d "${REPO_DIR}" ]; then
        cd "${REPO_DIR}"
        # Fetch latest refs in case branch exists on remote
        git fetch origin 2>/dev/null || true
        # Try to checkout existing branch or create new one
        if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
            echo "   → Checking out existing branch: ${BRANCH_NAME}"
            git checkout "${BRANCH_NAME}"
        elif git show-ref --verify --quiet "refs/remotes/origin/${BRANCH_NAME}"; then
            echo "   → Checking out remote branch: origin/${BRANCH_NAME}"
            git checkout -b "${BRANCH_NAME}" "origin/${BRANCH_NAME}"
        else
            echo "   → Creating new branch: ${BRANCH_NAME}"
            git checkout -b "${BRANCH_NAME}"
        fi
    else
        echo "⚠️  Could not find git repository in /workspaces"
    fi
fi

echo "✅ Sandbox environment ready!"
echo "📋 Working directory: $(pwd)"