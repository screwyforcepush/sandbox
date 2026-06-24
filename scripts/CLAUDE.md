# scripts/

## Why: DevPod lifecycle management and monitoring

## Decisions

**Workspace naming**: DevPod enforces 48-char limit. Format: `claude-sandbox-{repo}-YYYYMMDD-HHMMSS`. Repo name truncated to 17 chars. Timestamp prevents collisions.

**Enhanced list-sandboxes.sh**: Integrates Docker stats API for real-time metrics (CPU%, memory, network/disk I/O, PIDs). Uses `docker ps -a --filter "label=dev.containers.id"` to find DevPod containers (including stopped), `docker stats --no-stream` for one-shot collection.

**Workspace↔container mapping**: DevPod writes a `uid` (e.g. `default-cs-3cc1c`) into `~/.devpod/contexts/<ctx>/workspaces/<name>/workspace.json` and uses the same value as the container's `dev.containers.id` label. `list-sandboxes.sh` and `proxy-helpers.sh` join on this — more reliable than mount-path grep and works while the container is stopped.

**Token fallback logic** (spin-up-sandbox.sh): `--token` flag > `.env.<repo-name>` > `.env`. Fine-grained PATs (`github_pat_`) for secure mode, classic PATs (`ghp_`) for standard.

## Gotchas
- DevPod generates random container names (e.g., `funny_morse`) — match workspace to container via `dev.containers.id` label joined to `workspace.json:uid`, not by name
- Multiple concurrent sandboxes may show same container stats in list view (acceptable)
- External repo flow: clones to temp dir, copies .devcontainer in, then creates DevPod workspace
