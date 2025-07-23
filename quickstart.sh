#!/bin/bash
set -e

echo "🚀 Claude Agent Sandbox - Quick Start"
echo "===================================="
echo ""
echo "This script will guide you through setting up your first sandbox."
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Step 1: Check prerequisites
echo "📋 Step 1: Checking prerequisites..."
echo ""

missing_deps=false

if ! command_exists docker; then
    echo "❌ Docker is not installed"
    echo "   👉 Install from: https://www.docker.com/products/docker-desktop"
    missing_deps=true
else
    echo "✅ Docker is installed"
fi

if ! command_exists gh; then
    echo "⚠️  GitHub CLI is not installed (used for token setup)"
    echo "   👉 Install with: brew install gh"
    echo "   Note: This will be installed inside the sandbox container"
else
    echo "✅ GitHub CLI is installed"
fi

if ! command_exists devpod; then
    echo "⚠️  DevPod is not installed (optional but recommended)"
    echo "   👉 Install with:"
    echo "      curl -L https://github.com/loft-sh/devpod/releases/latest/download/devpod-darwin-arm64 -o devpod"
    echo "      chmod +x devpod && sudo mv devpod /usr/local/bin/"
fi

if [ "$missing_deps" = true ]; then
    echo ""
    echo "Please install missing dependencies and run this script again."
    exit 1
fi

echo ""
echo "✅ All required dependencies are installed!"
echo ""

# Step 2: Set up GitHub token
echo "📋 Step 2: Setting up GitHub access..."
echo ""

if [ -f .env ]; then
    echo "✅ GitHub token already configured (.env file exists)"
    echo "   To regenerate, delete .env and run: ./scripts/setup-github-token.sh"
else
    echo "🔑 GitHub Personal Access Token (PAT) Setup"
    echo ""
    echo "You have two options:"
    echo ""
    echo "1. Use existing GitHub PAT"
    echo "   - Run: ./scripts/setup-github-token.sh --token <your-token>"
    echo ""
    echo "2. Create new GitHub PAT"
    echo "   - Run: ./scripts/setup-github-token.sh --create-token"
    echo "   - ⚠️  This gives access to ALL your repositories!"
    echo ""
    read -p "Press Enter to open GitHub token settings in your browser, or Ctrl+C to exit... "
    
    # Try to open the URL in the default browser
    if command -v open &> /dev/null; then
        open "https://github.com/settings/personal-access-tokens/new"
    elif command -v xdg-open &> /dev/null; then
        xdg-open "https://github.com/settings/personal-access-tokens/new"
    else
        echo "Please open: https://github.com/settings/personal-access-tokens/new"
    fi
    
    echo ""
    echo "After creating your token, run:"
    echo "  ./scripts/setup-github-token.sh --token <your-token>"
    exit 0
fi

echo ""

# Step 3: Launch with DevPod
echo "📋 Step 3: Launching sandbox with DevPod..."
echo ""

if ! command_exists devpod; then
    echo "❌ DevPod is not installed."
    echo ""
    echo "Please install DevPod first:"
    echo "   macOS: brew install devpod"
    echo "   Linux: See https://devpod.sh/docs/getting-started/install"
    echo ""
    echo "Alternative: You can use Docker Compose directly with 'docker-compose up -d'"
    exit 1
fi

echo "🚀 Creating your first sandbox..."
./scripts/spin-up-sandbox.sh

echo ""
echo "📚 Next steps:"
echo "   - Read SECURITY.md for security details"
echo "   - Check scripts/ directory for management tools"
echo "   - Run ./scripts/list-sandboxes.sh to see active sandboxes"
echo ""
echo "🔐 Security reminder:"
if [ -f .env ] && grep -q "^GITHUB_TOKEN=ghp_" .env 2>/dev/null; then
    echo "   ✓ GitHub PAT configured (global scope - standard for all GitHub PATs)"
fi
echo ""
echo "Happy coding! 🎉"