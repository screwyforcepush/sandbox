# traefik/

## Why: Browser access to dev servers in multiple simultaneous sandboxes without port conflicts

## Decisions

**File provider over Docker labels**: DevPod creates containers — Docker doesn't support adding labels to running containers, and devcontainer.json `runArgs` doesn't support `${localEnv:VAR}` substitution. File provider watches `~/.sandbox-proxy/dynamic/` and hot-reloads.

**Shared network `sandbox-net`**: Containers connected post-creation via `docker network connect`. Traefik routes to container IPs on this network. Fixed subnet `172.30.0.0/16` avoids collisions.

**Subdomain routing**: `http://{workspace}-{port}.localhost`. `.localhost` TLD resolves to 127.0.0.1 in modern browsers (RFC 6761) — no `/etc/hosts` editing needed.

**Pre-mapped ports**: 12 common dev ports pre-routed per sandbox. Unused ports return 502. No dynamic port discovery needed.

**Secure sandboxes excluded**: `sec-` prefix sandboxes get no proxy routes (no port access is a security feature).

## Patterns
- Start proxy: `./scripts/start-proxy.sh` (idempotent)
- Stop proxy: `./scripts/stop-proxy.sh`
- Dashboard: `http://localhost:8080`
- Config location: `~/.sandbox-proxy/dynamic/{workspace}.yml`

## Gotchas
- Dev servers MUST bind `0.0.0.0`, not `127.0.0.1`, to be reachable via Traefik
- Container IP changes on restart — config file would need regeneration
- `host.docker.internal` still works for container→host communication (runArgs preserved)
- If port 80 is in use on host, Traefik won't start
