#!/bin/bash
set -euo pipefail

echo "🔐 Claude Token Setup"
echo "===================="
echo ""

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Parse command line arguments
REPO_ARG=""
ENV_FILE=".env"
CREATE_TOKEN=false
IMPORT_TOKEN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO_ARG="$2"
            shift 2
            ;;
        --create-token)
            CREATE_TOKEN=true
            shift
            ;;
        --token)
            IMPORT_TOKEN="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --repo owner/name    Specify repository (stores in .env.<repo-name>)"
            echo "  --create-token       Authenticate with Claude to create new token"
            echo "  --token TOKEN        Import existing Claude OAuth token"
            echo "  --help               Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --create-token                        # Authenticate and store in .env"
            echo "  $0 --repo owner/name --create-token      # Auth for specific repo"
            echo "  $0 --token <token>                       # Import existing token"
            echo ""
            echo "Note: Claude tokens are user-specific and work across all repositories"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Determine which .env file to use
if [ -n "$REPO_ARG" ]; then
    REPO_NAME="${REPO_ARG##*/}"
    ENV_FILE=".env.${REPO_NAME}"
fi

# Function to check if vibekit is installed
check_vibekit() {
    if ! npm list @vibe-kit/auth >/dev/null 2>&1; then
        echo "📦 Installing @vibe-kit/auth package..."
        npm install @vibe-kit/auth >/dev/null 2>&1 || {
            echo -e "${RED}❌ Failed to install @vibe-kit/auth${NC}"
            echo "   Please ensure npm is installed and try again"
            exit 1
        }
    fi
}

# Function to update or add a variable in .env file
update_env_var() {
    local var_name="$1"
    local var_value="$2"
    local file="$3"
    
    # Create file if it doesn't exist
    touch "$file"
    
    # Check if variable exists
    if grep -q "^${var_name}=" "$file"; then
        # Update existing variable (macOS compatible)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^${var_name}=.*|${var_name}=${var_value}|" "$file"
        else
            sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" "$file"
        fi
    else
        # Add new variable with newline
        echo "" >> "$file"
        echo "${var_name}=${var_value}" >> "$file"
    fi
}

# Main execution
cd "$ROOT_DIR"

if [ -n "$IMPORT_TOKEN" ]; then
    # Import provided token
    echo "📥 Importing Claude token..."
    update_env_var "CLAUDE_CODE_OAUTH_TOKEN" "$IMPORT_TOKEN" "$ENV_FILE"
    echo -e "${GREEN}✅ Claude token imported successfully!${NC}"
    echo ""
    echo "📋 Token stored in: $ENV_FILE"
    echo ""
    echo "🚀 You can now create sandboxes with Claude authentication:"
    if [ -n "$REPO_ARG" ]; then
        echo "   ./scripts/spin-up-sandbox.sh --repo $REPO_ARG"
    else
        echo "   ./scripts/spin-up-sandbox.sh"
    fi
elif [ "$CREATE_TOKEN" = true ]; then
    # Check for vibekit
    check_vibekit
    
    echo "🌐 Starting Claude authentication..."
    echo ""
    
    # Run the Node.js authentication script with timeout handling
    echo "⏳ Starting interactive authentication process..."
    echo "   This will open your browser for OAuth authentication."
    echo "   You'll need to paste an authentication code when prompted."
    echo "   Process will timeout after 5 minutes of inactivity."
    echo ""
    
    # Setup timeout handler
    (
        sleep 300
        echo -e "\n${RED}❌ Authentication timed out after 5 minutes${NC}"
        echo "   Process was killed due to timeout."
        pkill -f "setup-claude-auth.js" 2>/dev/null
        exit 124
    ) &
    TIMEOUT_PID=$!
    
    # Setup interrupt handler to clean up timeout
    trap 'kill $TIMEOUT_PID 2>/dev/null; wait $TIMEOUT_PID 2>/dev/null; exit 130' INT
    
    # Create temp file to capture token output while preserving interactivity
    TEMP_OUTPUT=$(mktemp)
    
    # Run authentication interactively, only capturing token output
    node "$SCRIPT_DIR/setup-claude-auth.js" | tee "$TEMP_OUTPUT" || {
        AUTH_RESULT=$?
        kill $TIMEOUT_PID 2>/dev/null
        wait $TIMEOUT_PID 2>/dev/null
        rm -f "$TEMP_OUTPUT"
        
        if [ $AUTH_RESULT -eq 124 ]; then
            echo -e "${RED}❌ Authentication timed out${NC}"
            exit 1
        else
            echo -e "${RED}❌ Authentication failed${NC}"
            exit 1
        fi
    }
    
    # Clean up timeout process
    kill $TIMEOUT_PID 2>/dev/null
    wait $TIMEOUT_PID 2>/dev/null
    
    # Read the captured output
    AUTH_OUTPUT=$(cat "$TEMP_OUTPUT" 2>/dev/null || echo "No output captured")
    rm -f "$TEMP_OUTPUT"
    
    # Extract token from output and trim whitespace
    TOKEN=$(echo "$AUTH_OUTPUT" | grep -o 'TOKEN:.*' | cut -d':' -f2- | tr -d '\n\r' | xargs)
    
    if [ -z "$TOKEN" ]; then
        echo -e "${RED}❌ No token received from authentication${NC}"
        echo "Debug: AUTH_OUTPUT was:"
        echo "$AUTH_OUTPUT"
        exit 1
    fi
    
    echo "🔍 Token extracted successfully (length: ${#TOKEN})"
    
    # Store token in .env file
    update_env_var "CLAUDE_CODE_OAUTH_TOKEN" "$TOKEN" "$ENV_FILE"
    
    echo -e "${GREEN}✅ Claude authentication successful!${NC}"
    echo ""
    echo "📋 Token stored in: $ENV_FILE"
    echo ""
    echo "🚀 You can now create sandboxes with Claude authentication:"
    if [ -n "$REPO_ARG" ]; then
        echo "   ./scripts/spin-up-sandbox.sh --repo $REPO_ARG"
    else
        echo "   ./scripts/spin-up-sandbox.sh"
    fi
else
    # Check existing token
    if [ -f "$ENV_FILE" ] && grep -q "^CLAUDE_CODE_OAUTH_TOKEN=" "$ENV_FILE"; then
        echo -e "${GREEN}✅ Claude token found in $ENV_FILE${NC}"
        echo ""
        echo "To create a new token, use:"
        echo "   $0 --create-token"
    else
        echo -e "${YELLOW}⚠️  No Claude token found in $ENV_FILE${NC}"
        echo ""
        echo "To set up Claude authentication, use one of:"
        echo "   $0 --create-token        # Authenticate with browser"
        echo "   $0 --token <token>       # Import existing token"
    fi
fi