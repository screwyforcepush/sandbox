# Claude Authentication Setup

This guide explains how to set up Claude authentication for the sandbox environment, eliminating the need for manual login in each sandbox.

## Overview

The Claude authentication integration uses the **@vibe-kit/auth** package to handle OAuth authentication with Claude. Once authenticated on the host machine, the token is stored and automatically passed to all sandboxes.

## Setup Instructions

### 1. First-time Authentication

Run the authentication script to get a Claude OAuth token:

```bash
./scripts/setup-claude-token.sh --create-token
```

This will:
- Install the @vibe-kit/auth package if needed
- Open your browser for Claude authentication
- Display an authentication code to copy and paste
- Store the token in your `.env` file

### 2. Import Existing Token

If you already have a Claude OAuth token:

```bash
./scripts/setup-claude-token.sh --token <your-token>
```

### 3. Repository-specific Tokens

To store tokens for specific repositories:

```bash
./scripts/setup-claude-token.sh --repo owner/name --create-token
```

This stores the token in `.env.<repo-name>` instead of the global `.env`.

## How It Works

1. **Host Authentication**: The setup script uses @vibe-kit/auth to authenticate with Claude via OAuth
2. **Token Storage**: The OAuth token is stored in your `.env` file as `CLAUDE_CODE_OAUTH_TOKEN`
3. **Sandbox Creation**: When creating sandboxes, the token is automatically passed as an environment variable
4. **Automatic Configuration**: Inside the sandbox, Claude Code detects and uses the token automatically

## Security Notes

- Claude OAuth tokens are user-specific and work across all repositories
- Tokens are stored locally in `.env` files (gitignored)
- Tokens are passed securely to containers via environment variables
- The OAuth flow uses PKCE for enhanced security

## Troubleshooting

### Authentication Failed
- Ensure you copy the ENTIRE authentication code (format: `code#state`)
- Try running the authentication again if it fails

### Token Not Working in Sandbox
- Verify the token is in your `.env` file: `grep CLAUDE_CODE_OAUTH_TOKEN .env`
- Check that Claude Code is installed in the sandbox: `claude --version`
- Try re-authenticating with `--create-token`

### Missing Dependencies
- The script will automatically install @vibe-kit/auth when needed
- Ensure npm is installed on your host system

## Technical Details

The implementation consists of:
- `scripts/setup-claude-auth.js` - Node.js script using @vibe-kit/auth
- `scripts/setup-claude-token.sh` - Shell wrapper for token management
- Modified `spin-up-sandbox.sh` to pass tokens to containers
- Updated `.devcontainer/auth-setup.sh` to configure Claude Code

For more details, see the implementation in the `scripts/` directory.