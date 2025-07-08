# Security Architecture

This document outlines the security measures implemented in the Claude Agent Sandbox.

## Overview

The sandbox provides multiple layers of security to ensure that Claude agents operate in a completely isolated environment with controlled access to specific repositories while maintaining host security.

## Security Layers

### 1. Container Runtime Security

- **Rootless Containers**: Uses Docker rootless mode or Podman to run containers without root privileges on the host
- **User Namespace Isolation**: Containers run in isolated user namespaces
- **Container-Only Sudo**: The `vscode` user has sudo access within the container only, with no host escalation
- **No Privileged Access**: Containers run with `no-new-privileges` security option

### 2. Filesystem Isolation

- **No Host Filesystem Access**: Only the workspace directory is mounted
- **Read-Only Options**: Can configure read-only root filesystem if needed
- **Protected Directories**: `.git` and `node_modules` use anonymous volumes
- **Temporary Workspace**: For external repos, code is cloned to isolated temporary directories

### 3. Network Security

- **Isolated Network Namespace**: Each container has its own network namespace
- **Optional Full Isolation**: Can enable `network_mode: none` for complete network isolation
- **No Container-to-Container Communication**: Containers cannot communicate with each other
- **Controlled Outbound**: Internet access for package installation (configurable)

### 4. Access Control

- **GitHub PAT Tokens**: Repository-specific access tokens with defined scopes
- **Expanded Permissions**: 
  - `repo` scope: Full repository control (branch, commit, push, PR management)
  - `workflow` scope: GitHub Actions management (edit workflows, view logs)
  - Repository secrets management
- **Token Expiry**: Tokens expire after 30 days
- **Repository Isolation**: Each token is scoped to a single repository
- **Environment Variable Control**: Only explicitly defined variables are passed

### 5. Resource Limits

- **CPU Limits**: Maximum 2 CPUs per container
- **Memory Limits**: Maximum 4GB RAM per container
- **Storage Limits**: 32GB storage limit

### 6. Package Installation

- **Container-Only Installation**: Agents can install packages using sudo within the container
- **No Host Impact**: Package installations are isolated to the container
- **Supported Package Managers**:
  - System: `apt-get` (Debian/Ubuntu packages)
  - Python: `pip`
  - Node.js: `npm`
  - Any other tools needed by the agent

## Usage Patterns

### Dynamic Repository Management

```bash
# Generate token for any repository
./scripts/setup-github-token.sh --repo owner/name

# Spin up sandbox for specific repo and branch
./scripts/spin-up-sandbox.sh --repo owner/name --branch feature-branch
```

### Multiple Repository Support

- Tokens stored as `.env.{repo-name}`
- Each repository gets its own isolated token
- Sandboxes automatically use the correct token

## Security Best Practices

### For Users

1. **Separate Tokens**: Generate separate PAT tokens for each repository
2. **Rotate Tokens**: Replace tokens every 30 days
3. **Check .gitignore**: Ensure `.env*` files are never committed
4. **Review Permissions**: Audit token scopes before generation
5. **Clean Up**: Use `./scripts/cleanup-sandboxes.sh` to remove old sandboxes

### For Developers

1. **Repository Validation**: Always verify repository URLs before cloning
2. **Branch Protection**: Use branch protection rules on important branches
3. **Audit Activity**: Monitor repository activity through GitHub audit logs
4. **Package Sources**: Be aware that agents can install packages from public repositories

## Threat Model

### Protected Against

- **Host Privilege Escalation**: Sudo only works within container
- **Cross-Repository Access**: Tokens are repository-specific
- **Container Escape**: Rootless mode prevents host root access
- **Host Filesystem Access**: No bind mounts except workspace
- **Resource Exhaustion**: CPU/memory limits prevent DoS
- **Token Theft**: Tokens are scoped, time-limited, and cleared after use

### Accepted Risks

- **Repository Access**: Full read/write access to the specified repository
- **Package Installation**: Agents can install packages from public sources
- **Network Access**: Internet access enabled for functionality
- **Workflow Modification**: Agents can modify GitHub Actions workflows

## Incident Response

If you suspect a security breach:

1. **Revoke Tokens**: 
   ```bash
   gh auth token revoke
   # Or revoke specific token in GitHub settings
   ```

2. **Clean Environment**:
   ```bash
   ./scripts/cleanup-sandboxes.sh
   rm -f .env*
   ```

3. **Audit Activity**:
   - Check GitHub audit logs
   - Review recent commits and PRs
   - Verify no unauthorized workflow changes

4. **Regenerate**: Create new tokens with updated permissions

## Configuration Options

### Maximum Security Mode

For maximum isolation, uncomment these options in `devcontainer.json`:

```json
"runArgs": ["--read-only", "--network=none"]
```

Note: This will disable package installation and network access.

### Repository Restrictions

To limit repositories the sandbox can access:

1. Use GitHub App installation tokens instead of PAT tokens
2. Configure branch protection rules
3. Use repository rulesets for additional controls

### Audit Mode

Enable detailed logging:

```bash
export DOCKER_CONTENT_TRUST=1
export DOCKER_LOG_LEVEL=debug
export DEVPOD_DEBUG=true
```

## Package Installation Security

### What Agents Can Install

- System packages via apt (Debian repositories)
- Python packages via pip (PyPI)
- Node packages via npm (npm registry)
- Tools via curl/wget from the internet

### Security Considerations

- Packages are installed with container-user privileges
- No access to host package managers
- Downloads are subject to container network policies
- Consider using private package registries for sensitive environments

## Updates and Patches

- **Base Image**: Updated monthly via Microsoft's devcontainer images
- **DevPod**: Check for updates with `devpod version`
- **Docker**: Keep Docker Desktop updated for latest security patches
- **Dependencies**: Regularly rebuild containers to get security updates

## Advanced Configurations

### Custom Base Images

For additional security, create custom base images:

```dockerfile
FROM mcr.microsoft.com/devcontainers/base:debian
# Add security scanning, monitoring tools, etc.
```

### Network Policies

Implement network policies to restrict outbound traffic:

```yaml
# In docker-compose.yml
networks:
  sandbox_net:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
```

## Contact

For security concerns or questions, please open an issue with the `security` label.