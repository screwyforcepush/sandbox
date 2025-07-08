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
    echo "❌ GitHub CLI is not installed"
    echo "   👉 Install with: brew install gh"
    missing_deps=true
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
    echo "🔑 Creating GitHub PAT token..."
    ./scripts/setup-github-token.sh
fi

echo ""

# Step 3: Choose setup method
echo "📋 Step 3: Choose your setup method..."
echo ""
echo "1) DevPod (Recommended - Better isolation and management)"
echo "2) Docker Compose (Simple, traditional approach)"
echo ""
read -p "Select option (1 or 2): " -n 1 -r
echo ""
echo ""

case $REPLY in
    1)
        echo "🚀 Launching sandbox with DevPod..."
        if ! command_exists devpod; then
            echo "❌ DevPod is required for this option. Please install it first."
            exit 1
        fi
        ./scripts/spin-up-sandbox.sh
        ;;
    2)
        echo "🚀 Launching sandbox with Docker Compose..."
        source .env
        docker-compose up -d
        echo ""
        echo "✅ Sandbox is running!"
        echo ""
        echo "🖥️  Access your sandbox:"
        echo "   Shell: docker-compose exec claude-sandbox bash"
        echo "   Logs: docker-compose logs -f"
        echo "   Stop: docker-compose down"
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "📚 Next steps:"
echo "   - Read SECURITY.md for security details"
echo "   - Check scripts/ directory for management tools"
echo "   - Run ./scripts/list-sandboxes.sh to see active sandboxes"
echo ""
echo "Happy coding! 🎉"