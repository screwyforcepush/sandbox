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

    # Find container by DevPod label + mount inspection (same pattern as list-sandboxes.sh)
    local container_id=""
    while IFS='|' read -r cid cname; do
        if [ -z "$cid" ]; then
            continue
        fi
        local mount_check
        mount_check=$(docker inspect "$cid" --format '{{range .Mounts}}{{.Source}} {{end}}' 2>/dev/null | grep "$workspace_name" || echo "")
        if [ -n "$mount_check" ]; then
            container_id="$cid"
            break
        fi
    done < <(docker ps --filter "label=dev.containers.id" --format "{{.ID}}|{{.Names}}")

    if [ -z "$container_id" ]; then
        echo "⚠️  Could not find container for workspace: ${workspace_name}"
        echo "   Proxy routing will not be configured."
        return 1
    fi

    echo "🔀 Configuring proxy for ${workspace_name}..."

    # Connect container to sandbox-net (ignore if already connected)
    docker network connect sandbox-net "$container_id" 2>/dev/null || true

    # Get the container's IP on sandbox-net
    local container_ip
    container_ip=$(docker inspect -f '{{(index .NetworkSettings.Networks "sandbox-net").IPAddress}}' "$container_id" 2>/dev/null)

    if [ -z "$container_ip" ]; then
        echo "⚠️  Could not get container IP on sandbox-net"
        return 1
    fi

    echo "   Container: ${container_id:0:12}"
    echo "   IP: ${container_ip}"

    # Generate Traefik dynamic config
    mkdir -p "$DYNAMIC_CONFIG_DIR"
    local config_file="${DYNAMIC_CONFIG_DIR}/${workspace_name}.yml"

    {
        echo "# Auto-generated for workspace: ${workspace_name}"
        echo "# Container: ${container_id:0:12} | IP: ${container_ip}"
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
            echo "          - url: \"http://${container_ip}:${port}\""
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
