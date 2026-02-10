# scripts/

## Why: DevPod lifecycle management and monitoring

## Decisions

**Workspace naming**: DevPod enforces 48-char limit. Format: `claude-sandbox-{repo}-YYYYMMDD-HHMMSS`. Repo name truncated to 17 chars. Timestamp prevents collisions.

**Enhanced list-sandboxes.sh**: Integrates Docker stats API for real-time metrics (CPU%, memory, network/disk I/O, PIDs). Uses `docker ps --filter "label=dev.containers.id"` to find DevPod containers, `docker stats --no-stream` for one-shot collection.

**Token fallback logic** (spin-up-sandbox.sh): `--token` flag > `.env.<repo-name>` > `.env`. Fine-grained PATs (`github_pat_`) for secure mode, classic PATs (`ghp_`) for standard.

## Gotchas
- DevPod generates random container names (e.g., `funny_morse`) - can't match workspace to container by name alone
- Multiple concurrent sandboxes may show same container stats in list view (acceptable)
- External repo flow: clones to temp dir, copies .devcontainer in, then creates DevPod workspace
