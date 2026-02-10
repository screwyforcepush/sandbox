# .devcontainer

## Why: Isolated dev environments for AI agents via DevPod

## Decisions

**Base image**: `javascript-node:20-bookworm` (Debian 12). Upgraded from Bullseye for GLIBC 2.36 (some tools need >=2.32). Same MS devcontainer family, no breaking changes.

**uv package manager**: Installed via `curl -LsSf https://astral.sh/uv/install.sh | sh` in post-create.sh. Installs to `~/.cargo/bin`. 10-100x faster than pip. Falls back to pip if install fails.

**Locale**: `LANG=en_US.UTF-8` and `LC_ALL=en_US.UTF-8` appended to `~/.bashrc` in post-create.sh. Prevents encoding errors in CLI tools.

**Host connectivity**: `--add-host=host.docker.internal:host-gateway` in runArgs. Allows containers to reach host services without `--network=host`. Host services must bind `0.0.0.0`, not `127.0.0.1`.

**CLAUDE_COMMS_SERVER**: Optional env var for sandbox-to-host communication. Set on host before creating sandbox. Passed via `${localEnv:CLAUDE_COMMS_SERVER}` in containerEnv. Expected value: `http://host.docker.internal:4000`.

**Port forwarding**: Removed `forwardPorts` from devcontainer.json. Multiple simultaneous containers caused port conflicts. Now using Traefik reverse proxy with subdomain routing: `http://{workspace}-{port}.localhost`. Dev servers must bind `0.0.0.0`. See `traefik/CLAUDE.md`.

## Gotchas
- Dev servers binding `127.0.0.1` won't be reachable via forwarded ports - must use `0.0.0.0`
- Existing sandboxes need recreation after devcontainer.json changes
- Linux hosts need Docker 20.04+ for `host.docker.internal`; Mac/Windows get it free from Docker Desktop
