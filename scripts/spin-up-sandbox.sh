#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/proxy-helpers.sh"

echo "🚀 Claude Agent Sandbox Launcher"
echo "================================"
echo ""

# Parse command line arguments
REPO_ARG=""
BRANCH_ARG="main"
ENV_FILE=".env"
TOKEN_ARG=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO_ARG="$2"
            shift 2
            ;;
        --branch)
            BRANCH_ARG="$2"
            shift 2
            ;;
        --token)
            TOKEN_ARG="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --repo owner/name    Specify repository (e.g., facebook/react)"
            echo "  --branch name        Specify branch (default: main, creates if doesn't exist)"
            echo "  --token TOKEN        Use provided GitHub PAT token (overrides .env file)"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                      # Use current repo"
            echo "  $0 --repo owner/name                    # Use specific repo"
            echo "  $0 --repo owner/name --branch feature   # Use specific repo and branch"
            echo "  $0 --repo owner/name --token ghp_xxx    # Use specific token"
            echo ""
            echo "Security:"
            echo "  - GitHub PATs have global scope (access to all repositories in your account)"
            echo "  - This is standard behavior for all GitHub Personal Access Tokens"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate branch name format
validate_branch_name() {
    local branch="$1"
    # Check for valid git branch name
    if ! echo "$branch" | grep -qE '^[a-zA-Z0-9._/-]+$'; then
        echo "❌ Invalid branch name: $branch"
        echo "Branch names should contain only alphanumeric characters, dots, dashes, underscores, and slashes"
        exit 1
    fi
}

# Validate branch name if provided
if [ -n "$BRANCH_ARG" ]; then
    validate_branch_name "$BRANCH_ARG"
fi

# Check prerequisites
check_prerequisites() {
    local missing=false
    
    # Check for DevPod
    if ! command -v devpod &> /dev/null; then
        echo "❌ DevPod is not installed."
        echo "   Install with: curl -L https://github.com/loft-sh/devpod/releases/latest/download/devpod-darwin-arm64 -o devpod && chmod +x devpod && sudo mv devpod /usr/local/bin/"
        missing=true
    fi
    
    # Check for Docker
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed."
        echo "   Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        missing=true
    fi
    
    if [ "$missing" = true ]; then
        exit 1
    fi
}

# Load environment variables
load_env() {
    # If token provided via command line, use it directly
    if [ -n "$TOKEN_ARG" ]; then
        GITHUB_TOKEN="$TOKEN_ARG"
        
        # Set repository info based on arguments or current repo
        if [ -n "$REPO_ARG" ]; then
            REPO_OWNER="${REPO_ARG%%/*}"
            REPO_NAME="${REPO_ARG##*/}"
            REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
        else
            # Try to get from current git repo
            GIT_URL="$(git remote get-url origin 2>/dev/null || echo "")"
            if [ -z "$GIT_URL" ]; then
                echo "❌ No repository specified and not in a git repository."
                echo "   Use: $0 --repo owner/name --token <token>"
                exit 1
            fi
            
            # Extract owner/name from Git URL
            if [[ "$GIT_URL" =~ github\.com[:/]([^/]+)/([^/\.]+)(\.git)?$ ]]; then
                REPO_OWNER="${BASH_REMATCH[1]}"
                REPO_NAME="${BASH_REMATCH[2]}"
                REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
            else
                echo "❌ Unable to parse repository from Git URL: $GIT_URL"
                exit 1
            fi
        fi
        
        echo "🔑 Using provided token"
        echo "✅ Using GitHub PAT (global scope)"
    else
        # Load from .env file with fallback logic
        if [ -n "$REPO_ARG" ]; then
            local repo_name="${REPO_ARG##*/}"
            if [ -f ".env.${repo_name}" ]; then
                ENV_FILE=".env.${repo_name}"
                echo "🔑 Using repo-specific token (.env.${repo_name})"
            elif [ -f ".env" ]; then
                ENV_FILE=".env"
                echo "🔑 Using global token (.env) - no repo-specific token found"
            else
                echo "❌ No token file found."
                echo "   Repo-specific: .env.${repo_name} (not found)"
                echo "   Global: .env (not found)"
                echo ""
                echo "   Setup options:"
                echo "   - Repo-specific: ./scripts/setup-github-token.sh --repo ${REPO_ARG}"
                echo "   - Global: ./scripts/setup-github-token.sh --token <your-token>"
                echo "   - Or use: $0 --repo ${REPO_ARG} --token <your-token>"
                exit 1
            fi
        else
            if [ -f ".env" ]; then
                ENV_FILE=".env"
                echo "🔑 Using global token (.env)"
            else
                echo "❌ .env file not found."
                echo "   Run: ./scripts/setup-github-token.sh --token <your-token>"
                echo "   Or use: $0 --token <your-token>"
                exit 1
            fi
        fi
        
        # Load the environment file securely
        set -a
        # shellcheck source=/dev/null
        source "${ENV_FILE}"
        set +a
        
        # Override with command line args if provided
        if [ -n "$REPO_ARG" ]; then
            REPO_OWNER="${REPO_ARG%%/*}"
            REPO_NAME="${REPO_ARG##*/}"
            REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}.git"
        fi
        
    fi
}

# Configure Docker for rootless mode (if not already configured)
setup_rootless() {
    echo "🔒 Checking Docker rootless configuration..."
    
    # Check if running on Linux (rootless mode is Linux-specific)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! docker context ls | grep -q "rootless"; then
            echo "   Setting up Docker rootless mode..."
            dockerd-rootless-setuptool.sh install
            docker context create rootless --docker "host=unix://${XDG_RUNTIME_DIR}/docker.sock"
            docker context use rootless
        else
            echo "   ✓ Docker rootless mode already configured"
        fi
    else
        echo "   ℹ️  Docker Desktop provides isolation on macOS/Windows"
    fi
}

# Initialize DevPod provider
init_devpod() {
    echo "🔧 Initializing DevPod..."
    
    # Set up Docker provider for DevPod (ignore errors if already exists)
    if ! devpod provider list 2>/dev/null | grep -q "docker"; then
        devpod provider add docker 2>/dev/null || true
    fi
    
    # Configure provider options for security (ignore errors if already set)
    devpod provider options docker set DOCKER_RUN_AS_USER=true 2>/dev/null || true
    
    # Show provider status for debugging
    devpod provider list
}

# Create temporary env file for DevPod (avoid exposing token in process list)
create_temp_env_file() {
    local temp_env_file
    temp_env_file=$(mktemp)
    
    {
        echo "GITHUB_TOKEN=${GITHUB_TOKEN}"
        echo "REPO_URL=${REPO_URL}"
        echo "REPO_OWNER=${REPO_OWNER}"
        echo "REPO_NAME=${REPO_NAME}"
        echo "BRANCH_NAME=${BRANCH_ARG}"
        # Include Claude communications server
        echo "CLAUDE_COMMS_SERVER=http://host.docker.internal:4000"
        # Include Perplexity API key if available
        if [ -n "${PERPLEXITY_API_KEY:-}" ]; then
            echo "PERPLEXITY_API_KEY=${PERPLEXITY_API_KEY}"
        fi
        # Include Codex auth JSON if available
        if [ -n "${CODEX_AUTH_JSON:-}" ]; then
            echo "CODEX_AUTH_JSON=${CODEX_AUTH_JSON}"
        fi
        # Include Convex access token if available
        if [ -n "${CONVEX_ACCESS_TOKEN:-}" ]; then
            echo "CONVEX_ACCESS_TOKEN=${CONVEX_ACCESS_TOKEN}"
        fi
        # Include Google API key if available
        if [ -n "${GOOGLE_API_KEY:-}" ]; then
            echo "GOOGLE_API_KEY=${GOOGLE_API_KEY}"
        fi
        # Include Google Vertex AI flag if available
        if [ -n "${GOOGLE_GENAI_USE_VERTEXAI:-}" ]; then
            echo "GOOGLE_GENAI_USE_VERTEXAI=${GOOGLE_GENAI_USE_VERTEXAI}"
        fi
    } > "${temp_env_file}"
    
    chmod 600 "${temp_env_file}"
    echo "${temp_env_file}"
}

# Create and start sandbox
create_sandbox() {
    # Truncate repo name to fit DevPod's 48-character workspace name limit
    # Format: csb-{repo}-YYYYMMDD-HHMMSS (4 + repo + 16 = 20 + repo)
    local repo_name_truncated="${REPO_NAME:-local}"
    if [ ${#repo_name_truncated} -gt 28 ]; then
        repo_name_truncated="${repo_name_truncated:0:28}"
    fi
    local workspace_name="csb-${repo_name_truncated}-$(date +%Y%m%d-%H%M%S)"
    local temp_env_file
    
    echo ""
    echo "📦 Creating sandbox workspace: ${workspace_name}"
    echo "   Repository: ${REPO_URL:-Local repository}"
    echo "   Branch: ${BRANCH_ARG}"
    echo ""
    
    # Create temporary env file to avoid token exposure in process list
    temp_env_file=$(create_temp_env_file)
    
    # Determine source for DevPod
    if [ -n "$REPO_ARG" ]; then
        # Check if branch exists before using it
        echo "🔍 Checking if branch '${BRANCH_ARG}' exists..."
        if git ls-remote --heads "${REPO_URL}" "${BRANCH_ARG}" | grep -q "${BRANCH_ARG}"; then
            # Branch exists, use it
            local source_url="${REPO_URL}@${BRANCH_ARG}"
            echo "📥 DevPod will clone repository with existing branch..."
            echo "   Source: ${source_url}"
        else
            # Branch doesn't exist, clone default and inform user
            local source_url="${REPO_URL}"
            echo "⚠️  Branch '${BRANCH_ARG}' does not exist in remote repository"
            echo "📥 DevPod will clone default branch..."
            echo "   Source: ${source_url}"
            echo ""
            echo "   After sandbox starts, create the branch with:"
            echo "   devpod ssh ${workspace_name}"
            echo "   git checkout -b ${BRANCH_ARG}"
        fi
    else
        # Use current directory
        local source_url="$(pwd)"
        echo "📥 Using current directory..."
    fi
    
    # Create workspace with DevPod using repository URL
    devpod up \
        --provider docker \
        --ide none \
        --id "${workspace_name}" \
        --workspace-env-file "${temp_env_file}" \
        "${source_url}"
    
    # Clean up temp env file immediately
    rm -f "${temp_env_file}"

    # Register with reverse proxy for browser access
    register_sandbox_with_proxy "${workspace_name}" || true

    echo ""
    echo "✅ Sandbox created successfully!"
    echo ""
    echo "📋 Sandbox details:"
    echo "   Name: ${workspace_name}"
    echo "   Repository: ${REPO_OWNER:-local}/${REPO_NAME:-sandbox}"
    echo "   Branch: ${BRANCH_ARG}"
    echo "   Status: Running"
    echo ""
    echo "🔐 Security features:"
    echo "   ✓ Running as non-root user with sudo in container"
    echo "   ✓ No host privilege escalation"
    echo "   ✓ GitHub PAT (global scope - standard for all GitHub PATs)"
    echo "   ✓ Token not exposed in process list"
    echo "   ✓ Isolated network namespace"
    echo "   ✓ No host filesystem access"
    echo ""
    echo "🖥️  Access your sandbox:"
    echo "   SSH:    devpod ssh ${workspace_name}"
    echo "   Logs:   devpod logs ${workspace_name}"
    echo "   Stop:   devpod stop ${workspace_name}"
    echo "   Delete: devpod delete ${workspace_name}"
    echo ""
    echo "🌐 Browser access (dev servers must bind 0.0.0.0):"
    echo "   http://${workspace_name}-3000.localhost"
    echo "   http://${workspace_name}-5173.localhost"
    echo "   http://${workspace_name}-8080.localhost"
    echo "   Proxy dashboard: http://localhost:8080"
    echo ""
    echo "💡 To open in VS Code:"
    echo "   devpod up ${workspace_name} --ide vscode"
    echo ""
    echo "📦 The agent can install packages with:"
    echo "   apt-get update && apt-get install -y <package>"
    echo "   npm install -g <package>"
    echo "   pip install <package>"
}

# Main execution
main() {
    check_prerequisites
    load_env
    setup_rootless
    init_devpod
    ensure_proxy_running "$SCRIPT_DIR"
    create_sandbox
    
    # Clear sensitive data from environment
    unset GITHUB_TOKEN
}

# Run main function
main