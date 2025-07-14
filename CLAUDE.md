# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is the Claude Agent Sandbox infrastructure repository - it provides secure, isolated development environments for AI agents to work with GitHub repositories. The primary workflow uses DevPod to create multiple simultaneous sandboxes, each with its own branch and isolated environment.

## Core Commands

### Setting Up Sandboxes

```bash
# Quick start - guides you through token setup and launches first sandbox
./quickstart.sh

# Token Setup Options:
# Option 1: Use existing GitHub PAT
./scripts/setup-github-token.sh --repo owner/name --token ghp_xxxxxxxxxxxx

# Option 2: Create new GitHub PAT
./scripts/setup-github-token.sh --repo owner/name --create-token

# See all token options
./scripts/setup-github-token.sh --help

# Create a sandbox (multiple ways):
# Using token from .env file
./scripts/spin-up-sandbox.sh

# Using token directly (no .env needed)
./scripts/spin-up-sandbox.sh --repo owner/name --token ghp_xxxxxxxxxxxx

# Create a sandbox for a specific repo and branch
./scripts/spin-up-sandbox.sh --repo owner/name --branch feature-branch

# Create multiple sandboxes for different branches
./scripts/spin-up-sandbox.sh --branch feature-a  # Creates: claude-sandbox-<repo>-<timestamp>
./scripts/spin-up-sandbox.sh --branch feature-b  # Creates: claude-sandbox-<repo>-<timestamp>
```

### Managing Sandboxes

```bash
# List all active sandboxes
./scripts/list-sandboxes.sh

# Access a sandbox
devpod ssh <sandbox-name>

# Stop a sandbox
devpod stop <sandbox-name>

# Delete a specific sandbox
devpod delete <sandbox-name> --force

# Clean up all sandboxes
./scripts/cleanup-sandboxes.sh

# View sandbox logs
devpod logs <sandbox-name>
```

### Testing Security

```bash
# Test security isolation of a sandbox
./scripts/test-security.sh <sandbox-name>
```

## Architecture Overview

### Two Workflow Options

1. **DevPod (Primary)**: Supports multiple simultaneous sandboxes with full lifecycle management
   - Uses `devpod` CLI for container orchestration
   - Each sandbox gets unique name: `claude-sandbox-<repo>-<timestamp>`
   - Supports dynamic repository cloning and branch management

2. **Docker Compose (Alternative)**: Simple single-sandbox setup
   - Uses `docker-compose` commands
   - Container name: `claude-agent-sandbox`
   - Good for testing or simple use cases

### Key Components

- **`.devcontainer/devcontainer.json`**: Defines container configuration with minimal features for fast builds
- **`.devcontainer/post-create.sh`**: Simple initialization script that runs when container starts
- **`.devcontainer/seccomp-profile.json`**: Security profile for container isolation
- **Scripts in `scripts/`**: Management tools for DevPod workflow
- **`.env` files**: Store GitHub tokens and repository configuration
  - `.env` for current repository
  - `.env.<repo-name>` for external repositories

### Security Model

- Containers run as non-root user (`vscode`) with limited capabilities
- No host filesystem access except workspace directory
- **Token Security**: All GitHub PATs have global scope (access to all repositories in your account)
- Resource limits: 2 CPUs, 4GB RAM, 32GB storage (requested via hostRequirements)
- Capability drops: SYS_ADMIN, NET_ADMIN for enhanced security
- Seccomp profile available but not enforced by default

### Token Management

The `setup-github-token.sh` script supports GitHub Personal Access Tokens (PATs):

**GitHub Personal Access Tokens**
- Created via GitHub web UI: https://github.com/settings/tokens/new
- Have global scope (access to all repositories in your account)
- Required scopes: `repo` and `workflow`
- Use with: `./scripts/setup-github-token.sh --repo owner/name --token ghp_xxxxxxxxxxxx`

**Important Security Note**: All GitHub PATs have global scope and can access every repository you have access to. This is how GitHub authentication works - tokens cannot be limited to specific repositories.

Tokens are stored in `.env` files (gitignored) and passed to containers via environment variables. You can also pass tokens directly via `--token` flag to avoid storing them.

## Important Implementation Details

1. **Workspace Names**: DevPod automatically generates unique workspace names with timestamps. Don't try to set custom names via CLI flags.

2. **Pre-installed Tools**: The devcontainer includes essential development tools:
   - **GitHub CLI**: Pre-authenticated with repository PAT token
   - **Node.js v20**: Latest LTS with npm for package management
   - **Claude Code**: Anthropic's CLI tool for AI assistance
   - **Git**: Version control with automatic HTTPS authentication setup

3. **Tool Authentication**: 
   - GitHub CLI automatically authenticates using the GH_TOKEN environment variable
   - Git is configured to use HTTPS with the PAT token for push/pull operations
   - Claude Code is installed and ready (requires API key for full functionality)

4. **Environment Variables**: Containers receive: GITHUB_TOKEN, REPO_URL, REPO_OWNER, REPO_NAME, BRANCH_NAME, GH_TOKEN

5. **Git Configuration**: For external repos, the script clones to a temp directory and copies the .devcontainer config into it before creating the DevPod workspace.

## Common Issues and Solutions

### DevPod workspace creation fails
- Check Docker is running: `docker ps`
- Verify DevPod provider: `devpod provider list`
- Check logs: `devpod logs <workspace-name>`

### Token authentication issues
- Verify token exists: `cat .env.<repo-name>`
- Check GitHub CLI auth: `gh auth status`
- Classic tokens might be expired (30-day limit)
- Fine-grained tokens might lack required permissions
- Verify token format:
  - `ghp_xxx`: Standard GitHub PAT format

### Container keeps restarting
- Usually caused by post-create script errors
- Check logs: `docker logs <container-id>`
- Simplify post-create.sh if needed

### Can't access sandbox via SSH
- Use exact workspace name from `devpod list`
- Format: `devpod ssh <workspace-name>`
- Not: `ssh <workspace-name>.devpod`
- Alternative: Use `docker exec` directly with container ID from `docker ps`

### Token format verification
- Check token format in .env file:
  - GitHub PATs start with `ghp_`
- To create a new PAT:
  1. Go to https://github.com/settings/tokens/new
  2. Select required scopes (repo, workflow)
  3. Run: `./scripts/setup-github-token.sh --repo owner/name --token <new-token>`

## Development Notes

- Always test changes with both DevPod and Docker Compose workflows
- Keep devcontainer.json minimal for fast builds
- Scripts should validate inputs and provide clear error messages
- Maintain backwards compatibility with Docker Compose for simple use cases