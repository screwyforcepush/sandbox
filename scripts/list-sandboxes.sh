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

# Cache for DevPod containers to avoid repeated calls
DEVPOD_CONTAINERS=""
CACHE_POPULATED=""

# Function to get DevPod containers
get_devpod_containers() {
    if [[ -n "$CACHE_POPULATED" ]]; then
        echo "$DEVPOD_CONTAINERS"
        return
    fi
    
    DEVPOD_CONTAINERS=$(docker ps --filter "label=dev.containers.id" --format "{{.ID}}|{{.Names}}")
    CACHE_POPULATED="1"
    echo "$DEVPOD_CONTAINERS"
}

# Function to find container for specific workspace using mount inspection
find_container_for_workspace() {
    local workspace_name=$1
    local containers
    containers=$(get_devpod_containers)
    
    # Check each DevPod container to see if it has a mount for this workspace
    while IFS='|' read -r container_id container_name; do
        if [[ -n "$container_id" ]]; then
            # Check if this container has a mount path containing the workspace name
            local mount_check
            mount_check=$(docker inspect "$container_id" --format '{{range .Mounts}}{{.Source}}{{end}}' 2>/dev/null | grep "$workspace_name" || echo "")
            
            if [[ -n "$mount_check" ]]; then
                echo "$container_id|$container_name"
                return
            fi
        fi
    done <<< "$containers"
    
    # No specific container found
    echo ""
}

# Function to get container stats for a workspace
get_container_stats() {
    local workspace_name=$1
    
    # Check if workspace is actually running
    local devpod_status
    devpod_status=$(devpod status "$workspace_name" 2>&1 | grep "Running" || echo "")
    
    if [[ -z "$devpod_status" ]]; then
        echo "N/A|N/A|N/A|N/A|N/A|N/A|N/A|STOPPED"
        return
    fi
    
    # Find the specific container for this workspace
    local container_info
    container_info=$(find_container_for_workspace "$workspace_name")
    
    if [[ -z "$container_info" ]]; then
        echo "N/A|N/A|N/A|N/A|N/A|N/A|N/A|NO_CONTAINER"
        return
    fi
    
    # Parse container ID and name
    local container_id container_name
    IFS='|' read -r container_id container_name <<< "$container_info"
    
    if [[ -z "$container_id" ]]; then
        echo "N/A|N/A|N/A|N/A|N/A|N/A|N/A|NO_CONTAINER"
        return
    fi
    
    # Get stats for this specific container
    local stats_output
    stats_output=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}|{{.PIDs}}" "$container_id" 2>/dev/null || echo "")
    
    if [[ -z "$stats_output" ]]; then
        echo "N/A|N/A|N/A|N/A|N/A|${container_id:0:12}|${container_name}|ERROR"
        return
    fi
    
    # Format: cpu|memory|mem%|net|disk|pids|container_id|container_name|status
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