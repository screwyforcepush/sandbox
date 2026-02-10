#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SANDBOX_ROOT="$(dirname "$SCRIPT_DIR")"
DYNAMIC_CONFIG_DIR="$HOME/.sandbox-proxy/dynamic"

echo "🔀 Starting sandbox reverse proxy..."

# Create dynamic config directory
mkdir -p "$DYNAMIC_CONFIG_DIR"

# Create Docker network if it doesn't exist
if ! docker network inspect sandbox-net &>/dev/null; then
    echo "   Creating Docker network: sandbox-net"
    docker network create sandbox-net --driver bridge --subnet 172.30.0.0/16
else
    echo "   ✓ Docker network sandbox-net exists"
fi

# Check if Traefik is already running
if docker ps --filter "name=sandbox-proxy" --filter "status=running" -q | grep -q .; then
    echo "   ✓ Traefik already running"
    echo ""
    echo "   Dashboard: http://localhost:8080"
    exit 0
fi

# Start Traefik
echo "   Starting Traefik..."
docker compose -f "$SANDBOX_ROOT/traefik/docker-compose.yml" up -d

echo ""
echo "✅ Reverse proxy started!"
echo "   Dashboard: http://localhost:8080"
echo "   Sandbox URLs: http://{workspace}-{port}.localhost"
