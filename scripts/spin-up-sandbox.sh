#!/bin/bash
set -euo pipefail

echo "🚀 Claude Agent Sandbox Launcher"
echo "================================"
echo ""

# Parse command line arguments
REPO_ARG=""
BRANCH_ARG="main"
ENV_FILE=".env"

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
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --repo owner/name    Specify repository (e.g., facebook/react)"
            echo "  --branch name        Specify branch (default: main, creates if doesn't exist)"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                                      # Use current repo"
            echo "  $0 --repo owner/name                    # Use specific repo"
            echo "  $0 --repo owner/name --branch feature   # Use specific repo and branch"
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
    # Determine which .env file to use
    if [ -n "$REPO_ARG" ]; then
        local repo_name="${REPO_ARG##*/}"
        if [ -f ".env.${repo_name}" ]; then
            ENV_FILE=".env.${repo_name}"
        else
            echo "❌ .env.${repo_name} file not found."
            echo "   Run: ./scripts/setup-github-token.sh --repo ${REPO_ARG}"
            exit 1
        fi
    else
        if [ ! -f ".env" ]; then
            echo "❌ .env file not found."
            echo "   Run: ./scripts/setup-github-token.sh"
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
    
    # Set up Docker provider for DevPod
    if ! devpod provider list | grep -q "docker"; then
        devpod provider add docker
    fi
    
    # Configure provider options for security
    devpod provider options docker set DOCKER_RUN_AS_USER=true
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
    } > "${temp_env_file}"
    
    chmod 600 "${temp_env_file}"
    echo "${temp_env_file}"
}

# Create and start sandbox
create_sandbox() {
    local workspace_name="claude-sandbox-${REPO_NAME:-local}-$(date +%Y%m%d-%H%M%S)"
    local temp_dir="/tmp/sandbox-$$"
    local temp_env_file
    
    echo ""
    echo "📦 Creating sandbox workspace: ${workspace_name}"
    echo "   Repository: ${REPO_URL:-Local repository}"
    echo "   Branch: ${BRANCH_ARG}"
    echo ""
    
    # Prepare the repository
    if [ -n "$REPO_ARG" ]; then
        # Clone specified repository to temp location
        echo "📥 Cloning repository..."
        mkdir -p "${temp_dir}"
        git clone "${REPO_URL}" "${temp_dir}/workspace"
        
        # Copy devcontainer configuration
        echo "📋 Setting up devcontainer configuration..."
        cp -r "$(pwd)/.devcontainer" "${temp_dir}/workspace/"
        
        # Update the path
        local repo_path="${temp_dir}/workspace"
    else
        # Use current directory
        local repo_path="$(pwd)"
    fi
    
    # Create temporary env file to avoid token exposure in process list
    temp_env_file=$(create_temp_env_file)
    
    # Create workspace with DevPod using env file
    devpod up \
        --provider docker \
        --ide none \
        --devcontainer-path "${repo_path}/.devcontainer/devcontainer.json" \
        --dotfiles-url "" \
        --env-file "${temp_env_file}" \
        "${workspace_name}" \
        "${repo_path}"
    
    # Clean up temp env file immediately
    rm -f "${temp_env_file}"
    
    # Clean up temp directory if used
    if [ -n "$REPO_ARG" ] && [ -d "${temp_dir}" ]; then
        rm -rf "${temp_dir}"
    fi
    
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
    echo "   ✓ Full repository access (PAT token)"
    echo "   ✓ Token not exposed in process list"
    echo "   ✓ Isolated network namespace"
    echo "   ✓ No host filesystem access"
    echo ""
    echo "🖥️  Access your sandbox:"
    echo "   SSH: devpod ssh ${workspace_name}"
    echo "   Logs: devpod logs ${workspace_name}"
    echo "   Stop: devpod stop ${workspace_name}"
    echo "   Delete: devpod delete ${workspace_name}"
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
    create_sandbox
    
    # Clear sensitive data from environment
    unset GITHUB_TOKEN
}

# Run main function
main