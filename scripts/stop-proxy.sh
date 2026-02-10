#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🛑 Stopping sandbox reverse proxy..."

if docker ps --filter "name=sandbox-proxy" -q | grep -q .; then
    docker compose -f "$SANDBOX_ROOT/traefik/docker-compose.yml" down
    echo "   Traefik stopped"
else
    echo "   Traefik is not running"
fi

# Remove network only if no containers are connected
if docker network inspect sandbox-net &>/dev/null; then
    connected=$(docker network inspect sandbox-net -f '{{len .Containers}}')
    if [ "$connected" -eq 0 ]; then
        echo "   Removing sandbox-net network"
        docker network rm sandbox-net || true
    else
        echo "   Keeping sandbox-net ($connected containers still connected)"
    fi
fi

echo ""
echo "✅ Proxy stopped"
