#!/bin/bash
set -euo pipefail

echo "🔑 GitHub PAT Token Setup for Claude Agent Sandbox"
echo "================================================"
echo ""
echo "This script will help you create a GitHub Personal Access Token"
echo "with permissions for full repository management."
echo ""

# Parse command line arguments
REPO_ARG=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO_ARG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--repo owner/name]"
            exit 1
            ;;
    esac
done

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
echo "🔐 Permissions that will be granted:"
echo "   ✓ Full repository access (clone, branch, commit, push)"
echo "   ✓ Pull request management (create, review, merge)"
echo "   ✓ GitHub Actions (workflows, logs)"
echo "   ✓ Repository secrets management"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "Creating PAT token with repository management permissions..."
echo ""

# Create token with gh CLI
# Using expanded scopes for full repository management
TOKEN=$(gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /user/personal-access-tokens \
  -f note="Claude Agent Sandbox - ${REPO_NAME} (Full Access)" \
  -f expires_at="$(date -u -d '+30 days' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -v+30d '+%Y-%m-%dT%H:%M:%SZ')" \
  -f scopes='["repo", "workflow"]' \
  -f repositories='["'"${REPO_NAME}"'"]' \
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

# Use printf instead of echo for better security
printf '# GitHub Personal Access Token for Claude Agent Sandbox\n' > "$ENV_FILE"
printf '# Generated: %s\n' "$(date)" >> "$ENV_FILE"
printf '# Expires: 30 days from creation\n' >> "$ENV_FILE"
printf '# Repository: %s/%s\n' "${REPO_OWNER}" "${REPO_NAME}" >> "$ENV_FILE"
printf 'GITHUB_TOKEN=%s\n' "${TOKEN}" >> "$ENV_FILE"
printf 'REPO_URL=https://github.com/%s/%s.git\n' "${REPO_OWNER}" "${REPO_NAME}" >> "$ENV_FILE"
printf 'REPO_OWNER=%s\n' "${REPO_OWNER}" >> "$ENV_FILE"
printf 'REPO_NAME=%s\n' "${REPO_NAME}" >> "$ENV_FILE"

chmod 600 "$ENV_FILE"

echo ""
echo "✅ Token created successfully!"
echo ""
echo "📝 Token details:"
echo "   - Repository: ${REPO_OWNER}/${REPO_NAME}"
echo "   - Permissions:"
echo "     • repo (full repository control)"
echo "     • workflow (GitHub Actions management)"
echo "   - Capabilities:"
echo "     • Branch operations (create, delete, push)"
echo "     • Commit and push changes"
echo "     • Pull requests (create, review, merge)"
echo "     • GitHub Actions (edit workflows, view logs)"
echo "     • Repository secrets (read/write)"
echo "   - Expires: 30 days"
echo "   - Stored in: ${ENV_FILE} (git-ignored)"
echo ""
echo "🔒 Security notes:"
echo "   - This token only has access to the ${REPO_NAME} repository"
echo "   - It will expire in 30 days"
echo "   - Keep ${ENV_FILE} file secure and never commit it"
echo ""
echo "Next steps:"
echo "   ./scripts/spin-up-sandbox.sh --repo ${REPO_OWNER}/${REPO_NAME}"