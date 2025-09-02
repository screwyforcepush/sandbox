# DevPod Dashboard

A modern web dashboard for monitoring and managing DevPod workspaces with real-time metrics and intuitive controls.

## Features

- **Real-time monitoring**: Live CPU, memory, network, and disk usage metrics
- **Workspace management**: Start, stop, and delete workspaces with one click
- **SSH access**: Copy SSH commands to clipboard for easy terminal access
- **Responsive design**: Modern Material-UI interface that works on all devices
- **Live updates**: WebSocket-based real-time data streaming
- **Security**: Rate limiting, input validation, and secure command execution

## Architecture

- **Backend**: Node.js/Express with WebSocket support
- **Frontend**: React with Material-UI and Zustand state management
- **Real-time**: WebSocket for metrics streaming
- **Security**: Helmet, CORS, rate limiting, and command validation

## Quick Start

1. **Install dependencies**:
   ```bash
   npm run install:all
   ```

2. **Start the dashboard**:
   ```bash
   npm start
   ```

3. **Open browser**: Navigate to `http://localhost:3001`

## Development

### Backend Development
```bash
# Start backend with auto-reload
npm run dev
```

### Frontend Development
```bash
# Start frontend development server (port 3000)
cd frontend && npm start
```

### Production Build
```bash
# Build frontend for production
npm run build
```

## API Endpoints

- `GET /api/workspaces` - List all DevPod workspaces
- `GET /api/workspaces/:name/status` - Get workspace status
- `GET /api/workspaces/:name/metrics` - Get container metrics
- `POST /api/workspaces/:name/start` - Start workspace
- `POST /api/workspaces/:name/stop` - Stop workspace
- `DELETE /api/workspaces/:name` - Delete workspace

## WebSocket Events

- **Subscribe to metrics**: `{"type": "subscribe", "workspaceName": "..."}`
- **Unsubscribe**: `{"type": "unsubscribe", "workspaceName": "..."}`
- **Receive metrics**: `{"type": "metrics", "workspaceName": "...", "data": {...}}`

## Security Considerations

- Workspace names are validated with regex patterns
- All commands use spawn with argument arrays (no shell injection)
- Rate limiting prevents API abuse
- CORS and Helmet provide additional security layers
- WebSocket connections are cleaned up properly

## Integration

The dashboard integrates with existing DevPod CLI commands and Docker containers:

- Uses `devpod list --output json` for workspace data
- Uses `docker stats` for real-time metrics
- Uses `docker inspect` for workspace-container correlation
- Executes `devpod start/stop/delete` for operations

## Troubleshooting

### No workspaces showing
- Ensure DevPod is installed: `devpod --version`
- Check you have Claude sandboxes: `devpod list`
- Verify Docker is running: `docker ps`

### Metrics not updating
- Check WebSocket connection in browser dev tools
- Ensure containers are running: `docker ps`
- Verify workspace status: `devpod status <workspace-name>`

### API errors
- Check server logs for detailed error messages
- Verify workspace names match exactly
- Ensure proper permissions for DevPod commands

## Contributing

1. Follow existing code patterns and conventions
2. Add proper error handling and logging
3. Update documentation for new features
4. Test with multiple workspace scenarios

## License

MIT License - see LICENSE file for details.