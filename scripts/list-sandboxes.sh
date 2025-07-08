#!/bin/bash
set -e

echo "📋 Active Claude Agent Sandboxes"
echo "================================"
echo ""

if ! command -v devpod &> /dev/null; then
    echo "❌ DevPod is not installed."
    exit 1
fi

# List all workspaces
devpod list | grep -E "claude-sandbox-" || echo "No active sandboxes found."

echo ""
echo "💡 Commands:"
echo "   SSH into sandbox: devpod ssh <workspace-name>"
echo "   Stop sandbox: devpod stop <workspace-name>"
echo "   Delete sandbox: devpod delete <workspace-name>"
echo "   View logs: devpod logs <workspace-name>"