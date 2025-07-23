# Secure Claude Agent Sandbox

A secure, isolated development environment for Claude agents with full repository management capabilities.

## Features

- 🔒 **Secure Isolation**: Rootless containers with no host privilege escalation
- 🚀 **Multiple Sandboxes**: Run multiple isolated environments simultaneously
- 🌿 **Branch Management**: Each sandbox can work on different branches
- 📦 **Package Installation**: Agents can install any tools they need
- 🔑 **Scoped Access**: Repository-specific PAT tokens with full Git permissions
- 🛠️ **Fast Setup**: Optimized container builds for quick sandbox creation

## Architecture

- **Container Runtime**: Docker rootless mode or Podman for unprivileged containers
- **Environment Management**: DevPod for spinning up isolated environments
- **Access Control**: GitHub PAT tokens with repository-specific permissions
- **Security**: Complete host isolation, container-only sudo, explicit environment variables

## Quick Start

```bash
# One-command setup
./quickstart.sh

# Or step by step:
# 1. Generate GitHub PAT token for your repository
./scripts/setup-github-token.sh --repo owner/name

# 2. Spin up sandbox with specific repo and branch
./scripts/spin-up-sandbox.sh --repo owner/name --branch feature-branch
```

## Usage Examples

### Working with Current Repository

```bash
# Generate token for current repo
./scripts/setup-github-token.sh

# Launch sandbox
./scripts/spin-up-sandbox.sh
```

### Working with External Repository

```bash
# Generate token for specific repo
./scripts/setup-github-token.sh --repo facebook/react

# Launch sandbox with specific branch
./scripts/spin-up-sandbox.sh --repo facebook/react --branch main
```

### Working with Multiple Sandboxes

Create multiple sandboxes for different features or branches:

```bash
# Create sandbox for feature A
./scripts/spin-up-sandbox.sh --branch feature-a
# Creates: claude-sandbox-<repo>-<timestamp>

# Create sandbox for feature B
./scripts/spin-up-sandbox.sh --branch feature-b
# Creates: claude-sandbox-<repo>-<timestamp>

# List all active sandboxes
./scripts/list-sandboxes.sh

# Access specific sandbox
devpod ssh <sandbox-name>

# Stop a sandbox
devpod stop <sandbox-name>

# Clean up all sandboxes
./scripts/cleanup-sandboxes.sh
```

## Security Features

- **Rootless containers**: No root privileges on host
- **Container-only sudo**: Package installation without host impact
- **Isolated network namespace**: Controlled network access
- **No host filesystem access**: Only workspace mounted
- **Repository isolation**: Each token limited to one repository
- **Time-limited tokens**: 30-day expiration
- **Explicit environment variables**: No secrets leakage

## GitHub Permissions

The PAT tokens have the following scopes:
- `repo`: Full repository control (branch, commit, push, PR management)
- `workflow`: GitHub Actions management (edit workflows, view logs)
- Repository secrets management

## Package Installation

Agents can install packages within the sandbox:

```bash
# System packages
sudo apt-get update && sudo apt-get install -y redis-server

# Python packages
pip install numpy pandas

# Node packages
npm install -g typescript

# Any other tools
curl -fsSL https://deno.land/install.sh | sh
```

## Advanced Usage

### Environment Variables

Create `.env` files for different repositories:
- `.env` - Default for current repository
- `.env.repo-name` - For specific external repository

### Docker Compose Alternative

For simpler setups without DevPod:

```bash
# Load environment variables
source .env

# Start sandbox
docker-compose up -d

# Access sandbox
docker-compose exec claude-sandbox bash
```

## Prerequisites

- Docker Desktop or Docker Engine
- GitHub CLI (`gh`)
- DevPod (recommended) or Docker Compose
- macOS, Linux, or Windows with WSL2

## Installation

```bash
# Clone this repository
git clone git@github.com:screwyforcepush/sandbox.git
cd sandbox

# Run quick start
./quickstart.sh
```

## Security Considerations

- Tokens are repository-specific and time-limited
- Agents have full access to the specified repository
- Package installations are isolated to containers
- Network access enabled by default (configurable)
- See [SECURITY.md](SECURITY.md) for detailed security architecture

## Troubleshooting

### DevPod Issues

```bash
# Check DevPod version
devpod version

# View logs
devpod logs <workspace-name>

# Reset DevPod
devpod provider delete docker
devpod provider add docker
```

### Token Issues

```bash
# Regenerate token
rm .env.<repo-name>
./scripts/setup-github-token.sh --repo owner/name

# Check token permissions
gh api user -H "Authorization: token $GITHUB_TOKEN"
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test security implications
4. Submit a pull request

## License

MIT License - See LICENSE file for details