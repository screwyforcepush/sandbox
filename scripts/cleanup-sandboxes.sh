#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/proxy-helpers.sh"

echo "🧹 Claude Agent Sandbox Cleanup"
echo "==============================="
echo ""

if ! command -v devpod &> /dev/null; then
    echo "❌ DevPod is not installed."
    exit 1
fi

echo "Finding all Claude sandboxes..."
sandboxes=$(devpod list --output json | jq -r '.[] | select(.id | contains("claude-sandbox-") or contains("csb-")) | .id' 2>/dev/null || echo "")

if [ -z "$sandboxes" ]; then
    echo "✓ No sandboxes to clean up."
    exit 0
fi

echo ""
echo "Found sandboxes:"
while IFS= read -r sandbox; do
    [ -n "$sandbox" ] && echo "  - ${sandbox}"
done <<< "$sandboxes"

echo ""
read -p "Delete all sandboxes? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    while IFS= read -r sandbox; do
        if [ -n "$sandbox" ]; then
            echo "Deleting ${sandbox}..."
            deregister_sandbox_from_proxy "${sandbox}"
            devpod delete "${sandbox}" --force || true
        fi
    done <<< "$sandboxes"
    cleanup_stale_proxy_configs
    echo ""
    echo "✅ Cleanup complete!"
else
    echo "❌ Cleanup cancelled."
fi