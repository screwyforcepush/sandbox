#!/bin/bash
set -euo pipefail

echo "🔒 Setting up secure sandbox environment..."

# Validate required environment variables
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo "❌ Error: GITHUB_TOKEN environment variable is not set"
    exit 1
fi

if [ -z "${REPO_URL:-}" ]; then
    echo "❌ Error: REPO_URL environment variable is not set"
    exit 1
fi

# Set default branch if not specified
BRANCH_NAME="${BRANCH_NAME:-main}"

# Configure git to use token for authentication via helper
git config --global user.email "claude-agent@anthropic.com"
git config --global user.name "Claude Agent"

# Use a more secure credential helper configuration
git config --global credential.helper 'cache --timeout=3600'
git config --global credential.https://github.com.username oauth2

# Store token using git credential helper (more secure than .git-credentials file)
printf "protocol=https\nhost=github.com\nusername=oauth2\npassword=%s\n\n" "${GITHUB_TOKEN}" | git credential-cache store

# Determine workspace directory
WORKSPACE_DIR="/workspaces/${REPO_NAME:-sandbox}"

# Check if we're already in a git repository (DevPod might have cloned it)
if [ -d "${WORKSPACE_DIR}/.git" ] || [ -d "/workspace/.git" ]; then
    echo "📦 Repository already exists..."
    # Try both possible locations
    if [ -d "$WORKSPACE_DIR" ]; then
        cd "$WORKSPACE_DIR"
    else
        cd "/workspace"
    fi
    
    # Fetch latest changes
    echo "📥 Fetching latest changes..."
    git fetch origin
    
    # Check if branch exists
    if git rev-parse --verify "origin/${BRANCH_NAME}" > /dev/null 2>&1; then
        echo "🌿 Checking out existing branch: ${BRANCH_NAME}"
        git checkout "${BRANCH_NAME}"
        git pull origin "${BRANCH_NAME}"
    else
        echo "🌿 Creating new branch: ${BRANCH_NAME}"
        git checkout -b "${BRANCH_NAME}"
        echo "📤 Branch '${BRANCH_NAME}' created locally. Push when ready with:"
        echo "   git push -u origin ${BRANCH_NAME}"
    fi
else
    # Clone the repository
    echo "📦 Cloning repository..."
    # Ensure REPO_URL uses HTTPS (not SSH)
    if [[ "${REPO_URL}" == git@github.com:* ]]; then
        # Convert SSH URL to HTTPS
        REPO_PATH="${REPO_URL#git@github.com:}"
        REPO_PATH="${REPO_PATH%.git}"
        CLONE_URL="https://github.com/${REPO_PATH}.git"
    else
        # Already HTTPS
        CLONE_URL="${REPO_URL}"
    fi
    
    # Clone using the credential helper
    git clone "${CLONE_URL}" "${WORKSPACE_DIR}"
    cd "${WORKSPACE_DIR}"
    
    # Handle branch
    if git rev-parse --verify "origin/${BRANCH_NAME}" > /dev/null 2>&1; then
        echo "🌿 Checking out existing branch: ${BRANCH_NAME}"
        git checkout "${BRANCH_NAME}"
    else
        echo "🌿 Creating new branch: ${BRANCH_NAME}"
        git checkout -b "${BRANCH_NAME}"
        echo "📤 Branch '${BRANCH_NAME}' created locally. Push when ready with:"
        echo "   git push -u origin ${BRANCH_NAME}"
    fi
fi

# Install commonly needed tools
echo "📦 Installing essential development tools..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y --no-install-recommends \
    curl \
    wget \
    jq \
    tree \
    htop \
    build-essential \
    > /dev/null 2>&1

echo ""
echo "✅ Sandbox environment ready!"
echo ""
echo "📋 Environment details:"
echo "   Repository: ${REPO_OWNER}/${REPO_NAME}"
echo "   Branch: ${BRANCH_NAME}"
echo "   Working directory: $(pwd)"
echo ""
echo "🔒 Security features enabled:"
echo "   - Running as non-root user (with sudo in container)"
echo "   - No host privilege escalation"
echo "   - Full repository access via PAT token"
echo "   - Token cached in memory (not on disk)"
echo "   - Isolated environment"
echo ""
echo "📦 Package installation:"
echo "   - System packages: sudo apt-get install <package>"
echo "   - Python packages: pip install <package>"
echo "   - Node packages: npm install [-g] <package>"
echo "   - Any other tools the agent needs!"

# Clear sensitive token from environment
unset GITHUB_TOKEN