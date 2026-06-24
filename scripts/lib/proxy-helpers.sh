#!/bin/bash
# Shared helper functions for Traefik proxy integration

DYNAMIC_CONFIG_DIR="$HOME/.sandbox-proxy/dynamic"

# Common dev server ports to pre-map
PROXY_PORTS=(3000 3001 4200 5000 5173 5174 5175 6006 8000 8080 8888 9000)

ensure_proxy_running() {
    local script_dir="$1"

    if ! docker network inspect sandbox-net &>/dev/null; then
        echo "🔀 Starting reverse proxy..."
        bash "${script_dir}/start-proxy.sh"
    elif ! docker ps --filter "name=sandbox-proxy" --filter "status=running" -q | grep -q .; then
        echo "🔀 Starting reverse proxy..."
        bash "${script_dir}/start-proxy.sh"
    fi
}

register_sandbox_with_proxy() {
    local workspace_name="$1"

    # Find container by joining workspace.json:uid with dev.containers.id label.
    # This works for stopped containers too and is stable across host restarts.
    local uid=""
    local ws_json
    ws_json=$(ls "$HOME"/.devpod/contexts/*/workspaces/"$workspace_name"/workspace.json 2>/dev/null | head -1)
    if [ -n "$ws_json" ]; then
        uid=$(python3 -c "import json; print(json.load(open('$ws_json')).get('uid',''))" 2>/dev/null)
    fi

    local container_id=""
    local container_name=""
    if [ -n "$uid" ]; then
        while IFS='|' read -r cid cname clabel; do
            if [ "$clabel" = "$uid" ]; then
                container_id="$cid"
                container_name="$cname"
                break
            fi
        done < <(docker ps -a --filter "label=dev.containers.id" \
            --format '{{.ID}}|{{.Names}}|{{.Label "dev.containers.id"}}')
    fi

    if [ -z "$container_id" ]; then
        echo "⚠️  Could not find container for workspace: ${workspace_name}"
        echo "   Proxy routing will not be configured."
        return 1
    fi

    echo "🔀 Configuring proxy for ${workspace_name}..."

    # Connect container to sandbox-net (ignore if already connected)
    docker network connect sandbox-net "$container_id" 2>/dev/null || true

    echo "   Container: ${container_id:0:12} (${container_name})"

    # Generate Traefik dynamic config. Upstream URLs use the container NAME, not
    # IP — Docker's embedded DNS on sandbox-net resolves names, and names persist
    # across host restarts while IPs can shuffle.
    mkdir -p "$DYNAMIC_CONFIG_DIR"
    local config_file="${DYNAMIC_CONFIG_DIR}/${workspace_name}.yml"

    {
        echo "# Auto-generated for workspace: ${workspace_name}"
        echo "# Container: ${container_id:0:12} (${container_name})"
        echo "http:"
        echo "  routers:"
        for port in "${PROXY_PORTS[@]}"; do
            echo "    ${workspace_name}-${port}:"
            echo "      rule: \"Host(\`${workspace_name}-${port}.localhost\`)\""
            echo "      entryPoints:"
            echo "        - web"
            echo "      service: ${workspace_name}-${port}"
        done
        echo "  services:"
        for port in "${PROXY_PORTS[@]}"; do
            echo "    ${workspace_name}-${port}:"
            echo "      loadBalancer:"
            echo "        servers:"
            echo "          - url: \"http://${container_name}:${port}\""
        done
    } > "$config_file"

    echo ""
    echo "🌐 Browser access (dev servers must bind 0.0.0.0):"
    for port in "${PROXY_PORTS[@]}"; do
        echo "   http://${workspace_name}-${port}.localhost"
    done
}

deregister_sandbox_from_proxy() {
    local workspace_name="$1"
    local config_file="${DYNAMIC_CONFIG_DIR}/${workspace_name}.yml"

    if [ -f "$config_file" ]; then
        rm -f "$config_file"
        echo "   Removed proxy config for ${workspace_name}"
    fi
}

cleanup_stale_proxy_configs() {
    if [ ! -d "$DYNAMIC_CONFIG_DIR" ]; then
        return 0
    fi

    local removed=0
    for config_file in "$DYNAMIC_CONFIG_DIR"/*.yml; do
        [ -f "$config_file" ] || continue
        local ws_name
        ws_name=$(basename "$config_file" .yml)
        if ! devpod list 2>/dev/null | grep -q "$ws_name"; then
            rm -f "$config_file"
            echo "   Removed stale proxy config: ${ws_name}"
            removed=$((removed + 1))
        fi
    done

    if [ "$removed" -gt 0 ]; then
        echo "   Cleaned up ${removed} stale proxy config(s)"
    fi
}
