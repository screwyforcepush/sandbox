# DevPod Dashboard

## Why: Real-time monitoring and management of DevPod workspaces
The dashboard provides a modern web interface for monitoring multiple DevPod workspaces simultaneously, viewing real-time resource usage, and performing common operations without memorizing CLI commands. Built to improve developer experience for managing Claude Agent sandboxes.

## Decisions

### Architecture: React + Node.js with WebSocket real-time updates
- **React + Material-UI**: Modern, responsive frontend with dark theme
- **Express + WebSocket**: Lightweight backend with real-time metrics streaming
- **Direct CLI integration**: Wraps DevPod CLI commands safely
- **Zustand state management**: Lightweight alternative to Redux

### Metrics Collection: Direct function calls instead of HTTP requests
- **Original issue**: WebSocket handler made HTTP requests to rate-limited API endpoints
- **Problem**: Server rate-limited itself (100 req/15min, metrics every 3s = crash in 5min)
- **Solution**: Extract metrics logic into shared function, bypass HTTP for internal calls
- **Result**: Eliminates 429 errors while maintaining rate limits for external clients

## Patterns

### WebSocket Metrics Streaming
```javascript
// Direct function call pattern (avoids rate limiting)
const data = await getWorkspaceMetrics(workspaceName);
ws.send(JSON.stringify({ type: 'metrics', workspaceName, data }));

// NOT: await fetch(`/api/workspaces/${name}/metrics`) - causes 429 errors
```

### Container Discovery
- Uses Docker label filtering: `docker ps --filter "label=dev.containers.id"`
- Mount inspection to map workspace names to containers
- Handles multiple concurrent sandboxes accurately

### Multi-Core CPU Percentage Display
- **Docker behavior**: CPU can exceed 100% (100% per core, so 1600% max for 16 cores)
- **Display format**: Shows actual % / 1600% (percentage of total)
- **Progress bars**: Scale CPU percentage by dividing by 16 for visual representation
- **Example**: 370% CPU = 23.1% of total capacity (370/1600)

### Memory Calculation
- **Format parsing**: Handles "4.329GiB / 62.68GiB" format from Docker stats
- **Regex pattern**: `/([0-9.]+)\s*([A-Za-z]+)\s*\//` extracts used memory
- **Unit conversion**: Supports GiB, GB, MiB, MB, KiB, KB to GB conversion
- **Total calculation**: Sums all running container memory usage

### Security Patterns
- Workspace name validation: `^claude-sandbox-[a-zA-Z0-9_-]+$`
- Command execution via spawn with argument arrays (no shell injection)
- Rate limiting on external API endpoints only

## Issues

### Fixed: 429 Too Many Requests crash
- **Symptom**: Dashboard crashes after ~5 minutes with rate limit errors
- **Root cause**: WebSocket made HTTP requests to own rate-limited API
- **Fix**: Refactored to call metrics function directly, bypassing HTTP layer
- **Prevention**: Always use direct function calls for internal operations

### Known Limitations
- DevPod CLI only (no native HTTP API)
- Polling-based status updates (no DevPod event streams)
- Limited command whitelist for security

## Next

### Enhancement Opportunities
- Historical metrics storage for trend analysis
- Multi-workspace batch operations
- Custom application metrics integration
- GitOps webhook integration for auto-provisioning
- User authentication for multi-user access