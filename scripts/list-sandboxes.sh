#!/bin/bash
set -e

echo "📋 Active Claude Agent Sandboxes with Resource Usage"
echo "===================================================="
echo ""

if ! command -v devpod &> /dev/null; then
    echo "❌ DevPod is not installed."
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed."
    exit 1
fi

# Function to colorize high resource usage
colorize_usage() {
    local value=$1
    local threshold=${2:-80}
    
    if [[ $value =~ ^[0-9]+\.?[0-9]*% ]]; then
        local numeric_value=${value%\%}
        if (( $(echo "$numeric_value > $threshold" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "\033[31m$value\033[0m"  # Red for high usage
        elif (( $(echo "$numeric_value > 50" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "\033[33m$value\033[0m"  # Yellow for medium usage
        else
            echo -e "\033[32m$value\033[0m"  # Green for low usage
        fi
    else
        echo "$value"
    fi
}

# Cache for DevPod containers to avoid repeated calls.
# Includes stopped containers so we can still report CONTAINER_ID/NAME for
# STOPPED workspaces — join key is dev.containers.id label ↔ workspace.json `uid`.
DEVPOD_CONTAINERS=""
CACHE_POPULATED=""

get_devpod_containers() {
    if [[ -n "$CACHE_POPULATED" ]]; then
        echo "$DEVPOD_CONTAINERS"
        return
    fi

    DEVPOD_CONTAINERS=$(docker ps -a --filter "label=dev.containers.id" \
        --format "{{.ID}}|{{.Names}}|{{.State}}|{{.Label \"dev.containers.id\"}}")
    CACHE_POPULATED="1"
    echo "$DEVPOD_CONTAINERS"
}

# Read the DevPod workspace UID (e.g. "default-cs-3cc1c") from its workspace.json.
# This value is written by DevPod at workspace creation and labels its container.
get_workspace_uid() {
    local workspace_name=$1
    local ws_json
    ws_json=$(ls "$HOME"/.devpod/contexts/*/workspaces/"$workspace_name"/workspace.json 2>/dev/null | head -1)
    if [[ -z "$ws_json" ]]; then
        echo ""
        return
    fi
    python3 -c "import json,sys; print(json.load(open('$ws_json')).get('uid',''))" 2>/dev/null
}

# Find the container (running or stopped) whose dev.containers.id label matches
# the workspace's uid. Returns "id|name|state" or empty string.
find_container_for_workspace() {
    local workspace_name=$1
    local uid
    uid=$(get_workspace_uid "$workspace_name")

    if [[ -z "$uid" ]]; then
        echo ""
        return
    fi

    local containers
    containers=$(get_devpod_containers)

    while IFS='|' read -r cid cname cstate clabel; do
        if [[ "$clabel" == "$uid" ]]; then
            echo "$cid|$cname|$cstate"
            return
        fi
    done <<< "$containers"

    echo ""
}

# Emits 9 pipe-separated fields: cpu|mem|mem%|net|disk|pids|container_id|container_name|status
get_container_stats() {
    local workspace_name=$1

    local container_info
    container_info=$(find_container_for_workspace "$workspace_name")

    if [[ -z "$container_info" ]]; then
        echo "N/A|N/A|N/A|N/A|N/A|N/A|N/A|N/A|NO_CONTAINER"
        return
    fi

    local container_id container_name container_state
    IFS='|' read -r container_id container_name container_state <<< "$container_info"

    if [[ "$container_state" != "running" ]]; then
        echo "N/A|N/A|N/A|N/A|N/A|N/A|${container_id:0:12}|${container_name}|STOPPED"
        return
    fi

    local stats_output
    stats_output=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}|{{.PIDs}}" "$container_id" 2>/dev/null || echo "")

    if [[ -z "$stats_output" ]]; then
        echo "N/A|N/A|N/A|N/A|N/A|N/A|${container_id:0:12}|${container_name}|ERROR"
        return
    fi

    echo "${stats_output}|${container_id:0:12}|${container_name}|RUNNING"
}

# Get list of claude sandboxes (both old and new naming)
sandbox_data=$(devpod list | grep -E "(claude-sandbox-|csb-)" || echo "")

if [[ -z "$sandbox_data" ]]; then
    echo "No active sandboxes found."
    exit 0
fi

# Print header
printf "%-30s %-35s %-8s %-12s %-6s %-12s %-12s %-5s %-13s %-15s %s\n" \
    "NAME" "SOURCE" "STATUS" "MEMORY" "CPU%" "NET I/O" "DISK I/O" "PIDS" "CONTAINER_ID" "CONTAINER_NAME" "AGE"
echo "$(printf '%.0s-' {1..170})"

# Process each sandbox
while IFS= read -r line; do
    if [[ -z "$line" ]]; then
        continue
    fi
    
    # Parse devpod list output - extract workspace name, source, and age
    workspace_name=$(echo "$line" | awk '{print $1}')
    
    # Extract source (between first and second |)
    source=$(echo "$line" | awk -F'|' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Extract age (second to last column)
    age=$(echo "$line" | awk '{print $(NF-1)}' | sed 's/^[[:space:]]*//')
    
    # Clean up and format source for display
    display_source="$source"
    
    # Extract repo name and branch for better display
    if [[ $source =~ git:https://github.com/([^/]+)/([^@\s]+)(@([^\s]+))? ]]; then
        repo_owner="${BASH_REMATCH[1]}"
        repo_name="${BASH_REMATCH[2]}"
        branch="${BASH_REMATCH[4]:-main}"
        
        # Format as owner/repo@branch
        display_source="${repo_owner}/${repo_name}@${branch}"
    elif [[ $source =~ local:(.+) ]]; then
        # For local sources, show just the directory name
        local_path="${BASH_REMATCH[1]}"
        display_source="local:$(basename "$local_path")"
    fi
    
    # Truncate if still too long
    if [[ ${#display_source} -gt 34 ]]; then
        display_source="${display_source:0:31}..."
    fi
    
    # Get container stats (now includes container_id and container_name)
    IFS='|' read -r cpu_perc mem_usage mem_perc net_io block_io pids container_id container_name status <<< "$(get_container_stats "$workspace_name")"
    
    # Format and display
    printf "%-30s %-35s %-8s %-12s %-6s %-12s %-12s %-5s %-13s %-15s %s\n" \
        "${workspace_name:0:29}" \
        "${display_source}" \
        "$status" \
        "$mem_usage" \
        "$(colorize_usage "$cpu_perc")" \
        "$net_io" \
        "$block_io" \
        "$pids" \
        "$container_id" \
        "$container_name" \
        "$age"
        
done <<< "$sandbox_data"

echo ""

# Resource usage summary
echo "📊 Resource Summary:"
echo "=================="

total_containers=$(docker ps --filter "label=dev.containers.id" --quiet | wc -l | tr -d ' ')
echo "   Active DevPod Containers: $total_containers"

# Get system-wide stats if available
if command -v free &> /dev/null; then
    system_memory=$(free -h | awk '/^Mem:/ {print $2}')
    echo "   System Memory: $system_memory"
fi

echo ""
echo "💡 Commands:"
echo "   SSH into sandbox: devpod ssh <workspace-name>"
echo "   Stop sandbox: devpod stop <workspace-name>"
echo "   Delete sandbox: devpod delete <workspace-name>"
echo "   View logs: devpod logs <workspace-name>"
echo "   Real-time stats: docker stats <container-name>"
echo "   Show all containers: docker ps --filter \"label=dev.containers.id\""
echo "   Direct container access: docker exec -it <container-id> /bin/bash"