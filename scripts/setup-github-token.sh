#!/bin/bash
set -euo pipefail

echo "🔑 GitHub PAT Token Setup for Claude Agent Sandbox"
echo "================================================"
echo ""

# Parse command line arguments
REPO_ARG=""
USE_EXISTING_TOKEN=""
CREATE_TOKEN=false
FORCE_YES=false

show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --repo owner/name              Specify repository (e.g., facebook/react)"
    echo "  --token TOKEN                  Use an existing GitHub PAT token"
    echo "  --create-token                 Create a new GitHub PAT (global scope)"
    echo "  --yes                          Skip confirmation prompts (use with caution)"
    echo "  --help                         Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Use existing PAT"
    echo "  $0 --repo owner/name --token ghp_xxxxxxxxxxxx"
    echo ""
    echo "  # Create new PAT"
    echo "  $0 --repo owner/name --create-token"
    echo ""
    echo "To create a PAT manually:"
    echo "  1. Go to https://github.com/settings/tokens/new"
    echo "  2. Select required scopes (repo, workflow)"
    echo "  3. Generate token and use with --token flag"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO_ARG="$2"
            shift 2
            ;;
        --token)
            USE_EXISTING_TOKEN="$2"
            shift 2
            ;;
        --create-token)
            CREATE_TOKEN=true
            shift
            ;;
        --yes|-y)
            FORCE_YES=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for more information"
            exit 1
            ;;
    esac
done

# Validate repository format
validate_repo_format() {
    local repo="$1"
    # Check format: owner/name with alphanumeric, dash, underscore, dot
    if ! echo "$repo" | grep -qE '^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$'; then
        echo "❌ Invalid repository format: $repo"
        echo "Expected format: owner/name (e.g., facebook/react)"
        exit 1
    fi
}

# Get repository info
if [ -n "$REPO_ARG" ]; then
    # Validate and use provided repo
    validate_repo_format "$REPO_ARG"
    REPO_OWNER="${REPO_ARG%%/*}"
    REPO_NAME="${REPO_ARG##*/}"
else
    # Use current repo with safer parsing
    GIT_URL="$(git remote get-url origin 2>/dev/null || echo "")"
    
    if [ -z "$GIT_URL" ]; then
        echo "❌ No repository specified and not in a git repository."
        echo "Usage: $0 --repo owner/name"
        exit 1
    fi
    
    # Extract owner/name from various Git URL formats
    if [[ "$GIT_URL" =~ github\.com[:/]([^/]+)/([^/\.]+)(\.git)?$ ]]; then
        REPO_OWNER="${BASH_REMATCH[1]}"
        REPO_NAME="${BASH_REMATCH[2]}"
    else
        echo "❌ Unable to parse repository from Git URL: $GIT_URL"
        echo "Please specify explicitly: $0 --repo owner/name"
        exit 1
    fi
    
    # Validate extracted values
    validate_repo_format "${REPO_OWNER}/${REPO_NAME}"
fi

echo "📦 Repository: ${REPO_OWNER}/${REPO_NAME}"
echo ""

# Function to validate token
validate_token() {
    local token="$1"
    
    # Basic format validation
    if ! echo "$token" | grep -qE '^gh[a-z]_[a-zA-Z0-9]{30,}$'; then
        echo "❌ Invalid token format"
        echo "   Expected format: ghp_xxxxxxxxxxxx or gho_xxxxxxxxxxxx (GitHub tokens)"
        return 1
    fi
    
    # Test token with GitHub API
    echo "🔍 Validating token with GitHub API..."
    if gh api user --header "Authorization: token $token" &>/dev/null; then
        echo "✅ Token is valid (global scope)"
        return 0
    else
        echo "❌ Token validation failed"
        return 1
    fi
}

# Function to save token to env file
save_token() {
    local token="$1"
    local env_file="$2"
    
    # Use printf instead of echo for better security
    printf '# GitHub Personal Access Token for Claude Agent Sandbox\n' > "$env_file"
    printf '# Generated: %s\n' "$(date)" >> "$env_file"
    printf '# Repository: %s/%s\n' "${REPO_OWNER}" "${REPO_NAME}" >> "$env_file"
    printf 'GITHUB_TOKEN=%s\n' "${token}" >> "$env_file"
    printf 'REPO_URL=https://github.com/%s/%s.git\n' "${REPO_OWNER}" "${REPO_NAME}" >> "$env_file"
    printf 'REPO_OWNER=%s\n' "${REPO_OWNER}" >> "$env_file"
    printf 'REPO_NAME=%s\n' "${REPO_NAME}" >> "$env_file"
    
    chmod 600 "$env_file"
}

# Main logic
if [ -n "$USE_EXISTING_TOKEN" ]; then
    # Option 1: Use existing token
    echo "🔐 Using provided token..."
    echo ""
    
    if validate_token "$USE_EXISTING_TOKEN"; then
        # Create or update .env file
        ENV_FILE=".env"
        if [ -n "$REPO_ARG" ]; then
            ENV_FILE=".env.${REPO_NAME}"
        fi
        
        save_token "$USE_EXISTING_TOKEN" "$ENV_FILE"
        
        echo ""
        echo "✅ Token configured successfully!"
        echo "   - Stored in: ${ENV_FILE} (git-ignored)"
        echo ""
        echo "Next steps:"
        echo "   ./scripts/spin-up-sandbox.sh --repo ${REPO_OWNER}/${REPO_NAME}"
    else
        exit 1
    fi
    
elif [ "$CREATE_TOKEN" = true ]; then
    # Option 2: Create new GitHub PAT
    echo "🔐 Creating new GitHub PAT"
    echo "==========================="
    echo ""
    echo "ℹ️  GitHub PAT Information:"
    echo "   • This token will have global scope (access to all your repositories)"
    echo "   • This is how GitHub PATs work - they cannot be limited to specific repos"
    echo "   • Token will be created with 'repo' and 'workflow' scopes"
    echo ""
    
    if [ "$FORCE_YES" != true ]; then
        read -p "Do you want to proceed with creating a GitHub PAT? (type 'yes' to continue) " -r REPLY
        echo ""
        if [[ ! "$REPLY" =~ ^yes$ ]]; then
            echo "Cancelled."
            exit 1
        fi
    fi
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        echo "❌ GitHub CLI (gh) is not installed."
        echo "Please install it first: brew install gh"
        exit 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo "🔐 Please authenticate with GitHub first..."
        gh auth login
    fi
    
    echo ""
    echo "Creating GitHub PAT..."
    echo ""
    
    # Create token with gh API
    TOKEN=$(gh api \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      /user/personal-access-tokens \
      -f note="Claude Agent Sandbox - ${REPO_NAME}" \
      -f expires_at="$(date -u -d '+30 days' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v+30d '+%Y-%m-%dT%H:%M:%SZ')" \
      -f scopes='["repo", "workflow"]' \
      --jq '.token')
    
    if [ -z "$TOKEN" ]; then
        echo "❌ Failed to create token"
        exit 1
    fi
    
    # Create or update .env file
    ENV_FILE=".env"
    if [ -n "$REPO_ARG" ]; then
        ENV_FILE=".env.${REPO_NAME}"
    fi
    
    save_token "$TOKEN" "$ENV_FILE"
    
    echo ""
    echo "✅ GitHub PAT created successfully"
    echo ""
    echo "📋 Token details:"
    echo "   - Token has global scope (standard for GitHub PATs)"
    echo "   - Expires in 30 days"
    echo "   - Stored in: ${ENV_FILE} (git-ignored)"
    echo ""
    echo "Next steps:"
    echo "   ./scripts/spin-up-sandbox.sh --repo ${REPO_OWNER}/${REPO_NAME}"
    
else
    # No option specified
    echo "❌ Please specify how to configure the token:"
    echo ""
    echo "Option 1: Use existing GitHub PAT"
    echo "   $0 --repo ${REPO_OWNER}/${REPO_NAME} --token <your-token>"
    echo ""
    echo "Option 2: Create new GitHub PAT"
    echo "   $0 --repo ${REPO_OWNER}/${REPO_NAME} --create-token"
    echo ""
    echo "Use --help for more information"
    exit 1
fi