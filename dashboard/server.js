const express = require('express');
const { spawn } = require('child_process');
const WebSocket = require('ws');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
const http = require('http');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3001;

// Simple in-memory cache with TTL
const cache = new Map();
const CACHE_TTL = 30000; // 30 seconds

function getCached(key) {
  const item = cache.get(key);
  if (!item) return null;
  if (Date.now() > item.expiry) {
    cache.delete(key);
    return null;
  }
  return item.value;
}

function setCached(key, value, ttl = CACHE_TTL) {
  cache.set(key, {
    value,
    expiry: Date.now() + ttl
  });
}

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Serve static files from frontend build
app.use(express.static(path.join(__dirname, 'frontend/build')));

// Utility function for safe command execution
function runCommand(command, args = [], options = {}) {
  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, { 
      stdio: ['ignore', 'pipe', 'pipe'],
      ...options 
    });
    
    let stdout = '';
    let stderr = '';
    
    proc.stdout.on('data', chunk => { stdout += chunk; });
    proc.stderr.on('data', chunk => { stderr += chunk; });
    
    proc.on('close', code => {
      if (code === 0) {
        resolve({ stdout: stdout.trim(), stderr: stderr.trim() });
      } else {
        reject(new Error(`Command failed with code ${code}: ${stderr || stdout}`));
      }
    });
    
    proc.on('error', reject);
  });
}

// Validate workspace name (security)
function validateWorkspaceName(name) {
  return /^(claude-sandbox-|csb-)[a-zA-Z0-9_-]+$/.test(name);
}

// API Routes

// Parse DevPod status output
function parseDevPodStatus(statusOutput) {
  // DevPod status output format: "Workspace 'name' is 'Running'"
  const match = statusOutput.match(/Workspace\s+'[^']+'\s+is\s+'([^']+)'/);
  if (match) {
    return match[1];
  }
  return 'Unknown';
}

// Get all DevPod workspaces with enriched data
app.get('/api/workspaces', async (req, res) => {
  try {
    const { stdout } = await runCommand('devpod', ['list', '--output', 'json']);
    const workspaces = JSON.parse(stdout || '[]');
    
    // Filter for claude sandboxes only (both old and new naming)
    const claudeSandboxes = workspaces.filter(w =>
      w.id && (w.id.includes('claude-sandbox-') || w.id.includes('csb-'))
    );
    
    // Enrich workspaces with status in parallel
    const enrichedWorkspaces = await Promise.all(
      claudeSandboxes.map(async (workspace) => {
        try {
          // Check cache first
          const cacheKey = `status:${workspace.id}`;
          let status = getCached(cacheKey);
          
          if (!status) {
            // Get status for each workspace
            const { stdout: statusOut, stderr } = await runCommand('devpod', ['status', workspace.id]);
            status = parseDevPodStatus(statusOut || stderr);
            setCached(cacheKey, status);
          }
          
          // Parse source information
          let source = 'Unknown';
          let branch = 'main';
          if (workspace.source && workspace.source.gitRepository) {
            // Extract repo name from URL
            const repoMatch = workspace.source.gitRepository.match(/github\.com\/(.+?)\.git$/);
            if (repoMatch) {
              source = repoMatch[1];
            }
            if (workspace.source.gitBranch) {
              branch = workspace.source.gitBranch;
            }
            source = `${source}@${branch}`;
          }
          
          return {
            ...workspace,
            status,
            source
          };
        } catch (err) {
          // If status check fails, still return workspace with unknown status
          console.error(`Failed to get status for ${workspace.id}:`, err);
          return {
            ...workspace,
            status: 'Unknown',
            source: 'Unknown'
          };
        }
      })
    );
    
    res.json(enrichedWorkspaces);
  } catch (error) {
    console.error('Error fetching workspaces:', error);
    res.status(500).json({ error: 'Failed to fetch workspaces' });
  }
});

// Get workspace status
app.get('/api/workspaces/:name/status', async (req, res) => {
  const { name } = req.params;
  
  if (!validateWorkspaceName(name)) {
    return res.status(400).json({ error: 'Invalid workspace name' });
  }
  
  try {
    const { stdout } = await runCommand('devpod', ['status', name]);
    res.json({ status: stdout.trim() });
  } catch (error) {
    console.error(`Error getting status for ${name}:`, error);
    res.status(500).json({ error: 'Failed to get workspace status' });
  }
});

// Start workspace
app.post('/api/workspaces/:name/start', async (req, res) => {
  const { name } = req.params;
  
  if (!validateWorkspaceName(name)) {
    return res.status(400).json({ error: 'Invalid workspace name' });
  }
  
  try {
    await runCommand('devpod', ['up', name]);
    res.json({ message: 'Workspace started successfully' });
  } catch (error) {
    console.error(`Error starting ${name}:`, error);
    res.status(500).json({ error: 'Failed to start workspace' });
  }
});

// Stop workspace
app.post('/api/workspaces/:name/stop', async (req, res) => {
  const { name } = req.params;
  
  if (!validateWorkspaceName(name)) {
    return res.status(400).json({ error: 'Invalid workspace name' });
  }
  
  try {
    await runCommand('devpod', ['stop', name]);
    res.json({ message: 'Workspace stopped successfully' });
  } catch (error) {
    console.error(`Error stopping ${name}:`, error);
    res.status(500).json({ error: 'Failed to stop workspace' });
  }
});

// Delete workspace
app.delete('/api/workspaces/:name', async (req, res) => {
  const { name } = req.params;
  
  if (!validateWorkspaceName(name)) {
    return res.status(400).json({ error: 'Invalid workspace name' });
  }
  
  try {
    await runCommand('devpod', ['delete', name, '--force']);
    res.json({ message: 'Workspace deleted successfully' });
  } catch (error) {
    console.error(`Error deleting ${name}:`, error);
    res.status(500).json({ error: 'Failed to delete workspace' });
  }
});

// Get workspace ports
app.get('/api/workspaces/:name/ports', async (req, res) => {
  const { name } = req.params;
  
  if (!validateWorkspaceName(name)) {
    return res.status(400).json({ error: 'Invalid workspace name' });
  }
  
  try {
    // Find container for workspace
    const { stdout: containers } = await runCommand('docker', [
      'ps', '--filter', 'label=dev.containers.id', '--format', '{{.ID}}|{{.Names}}'
    ]);
    
    if (!containers) {
      return res.json({ ports: [] });
    }
    
    // Find container for this workspace
    const containerLines = containers.split('\n').filter(line => line.trim());
    let targetContainer = null;
    
    for (const line of containerLines) {
      const [containerId] = line.split('|');
      if (containerId) {
        try {
          const { stdout: mounts } = await runCommand('docker', [
            'inspect', containerId, '--format', '{{range .Mounts}}{{.Source}}{{end}}'
          ]);
          
          if (mounts.includes(name)) {
            targetContainer = containerId;
            break;
          }
        } catch (e) {
          // Continue to next container
        }
      }
    }
    
    if (!targetContainer) {
      return res.json({ ports: [] });
    }
    
    // Get port mappings
    const { stdout: portData } = await runCommand('docker', [
      'inspect', targetContainer, '--format',
      '{{range $port, $conf := .NetworkSettings.Ports}}{{$port}}:{{range $conf}}{{.HostPort}}{{end}},{{end}}'
    ]);
    
    const ports = [];
    const portPairs = portData.split(',').filter(p => p.trim());
    
    for (const pair of portPairs) {
      const [containerPort, hostPort] = pair.split(':');
      if (containerPort && hostPort) {
        const [port, protocol] = containerPort.split('/');
        ports.push({
          containerPort: parseInt(port),
          hostPort: parseInt(hostPort),
          protocol: protocol || 'tcp'
        });
      }
    }
    
    res.json({ ports });
    
  } catch (error) {
    console.error(`Error getting ports for ${name}:`, error);
    res.status(500).json({ error: 'Failed to get workspace ports' });
  }
});

// Execute command in workspace
app.post('/api/workspaces/:name/execute', async (req, res) => {
  const { name } = req.params;
  const { command } = req.body;
  
  if (!validateWorkspaceName(name)) {
    return res.status(400).json({ error: 'Invalid workspace name' });
  }
  
  if (!command || typeof command !== 'string') {
    return res.status(400).json({ error: 'Invalid command' });
  }
  
  // Whitelist of allowed commands for security
  const allowedCommands = [
    'git status',
    'git branch',
    'docker system df',
    'df -h',
    'free -h',
    'ps aux --sort=-%cpu | head -10',
    'ls -la'
  ];
  
  if (!allowedCommands.includes(command)) {
    return res.status(403).json({ error: 'Command not allowed' });
  }
  
  try {
    const { stdout, stderr } = await runCommand('devpod', [
      'ssh', name, '--', 'bash', '-c', command
    ]);
    
    res.json({ 
      output: stdout || stderr,
      command,
      timestamp: Date.now()
    });
    
  } catch (error) {
    console.error(`Error executing command in ${name}:`, error);
    res.status(500).json({ error: 'Failed to execute command' });
  }
});

// Get container logs
app.get('/api/workspaces/:name/logs', async (req, res) => {
  const { name } = req.params;
  const { lines = 100 } = req.query;
  
  if (!validateWorkspaceName(name)) {
    return res.status(400).json({ error: 'Invalid workspace name' });
  }
  
  try {
    // Find container for workspace (same logic as metrics)
    const { stdout: containers } = await runCommand('docker', [
      'ps', '--filter', 'label=dev.containers.id', '--format', '{{.ID}}'
    ]);
    
    if (!containers) {
      return res.json({ logs: 'No container found' });
    }
    
    const containerId = containers.split('\n')[0].trim();
    
    // Get container logs
    const { stdout: logs } = await runCommand('docker', [
      'logs', '--tail', lines.toString(), '--timestamps', containerId
    ]);
    
    res.json({ logs, containerId });
    
  } catch (error) {
    console.error(`Error getting logs for ${name}:`, error);
    res.status(500).json({ error: 'Failed to get workspace logs' });
  }
});

// Shared function to get workspace metrics
async function getWorkspaceMetrics(workspaceName) {
  if (!validateWorkspaceName(workspaceName)) {
    throw new Error('Invalid workspace name');
  }
  
  try {
    // Use our existing script logic to get container stats
    const { stdout: containers } = await runCommand('docker', [
      'ps', '--filter', 'label=dev.containers.id', '--format', '{{.ID}}|{{.Names}}'
    ]);
    
    if (!containers) {
      return { status: 'no_container', metrics: null };
    }
    
    // Find container for this workspace using mount inspection
    const containerLines = containers.split('\n').filter(line => line.trim());
    let targetContainer = null;
    
    for (const line of containerLines) {
      const [containerId] = line.split('|');
      if (containerId) {
        try {
          const { stdout: mounts } = await runCommand('docker', [
            'inspect', containerId, '--format', '{{range .Mounts}}{{.Source}}{{end}}'
          ]);
          
          if (mounts.includes(workspaceName)) {
            targetContainer = containerId;
            break;
          }
        } catch (e) {
          // Continue to next container
        }
      }
    }
    
    if (!targetContainer) {
      return { status: 'no_container', metrics: null };
    }
    
    // Get container stats
    const { stdout: stats } = await runCommand('docker', [
      'stats', '--no-stream', '--format', 
      '{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}|{{.PIDs}}',
      targetContainer
    ]);
    
    const [cpu, memUsage, memPerc, netIO, blockIO, pids] = stats.split('|');
    
    return {
      status: 'running',
      metrics: {
        cpu: cpu.trim(),
        memUsage: memUsage.trim(),
        memPerc: memPerc.trim(),
        netIO: netIO.trim(),
        blockIO: blockIO.trim(),
        pids: pids.trim(),
        containerId: targetContainer.substring(0, 12),
        timestamp: Date.now()
      }
    };
    
  } catch (error) {
    console.error(`Error getting metrics for ${workspaceName}:`, error);
    throw error;
  }
}

// Get container metrics for workspace
app.get('/api/workspaces/:name/metrics', async (req, res) => {
  const { name } = req.params;
  
  try {
    const metricsData = await getWorkspaceMetrics(name);
    res.json(metricsData);
  } catch (error) {
    if (error.message === 'Invalid workspace name') {
      res.status(400).json({ error: error.message });
    } else {
      res.status(500).json({ error: 'Failed to get workspace metrics' });
    }
  }
});

// WebSocket for real-time metrics
const activeStreams = new Map();

wss.on('connection', (ws) => {
  console.log('Client connected to metrics stream');
  
  ws.on('message', (message) => {
    try {
      const { type, workspaceName } = JSON.parse(message);
      
      if (type === 'subscribe' && workspaceName && validateWorkspaceName(workspaceName)) {
        // Start metrics stream for this workspace
        if (activeStreams.has(workspaceName)) {
          clearInterval(activeStreams.get(workspaceName));
        }
        
        const interval = setInterval(async () => {
          try {
            // Call the metrics function directly instead of making HTTP request
            const data = await getWorkspaceMetrics(workspaceName);
            
            ws.send(JSON.stringify({
              type: 'metrics',
              workspaceName,
              data
            }));
          } catch (error) {
            console.error(`Error streaming metrics for ${workspaceName}:`, error);
          }
        }, 3000); // Update every 3 seconds
        
        activeStreams.set(workspaceName, interval);
        ws.workspaceName = workspaceName;
        
      } else if (type === 'unsubscribe' && ws.workspaceName) {
        if (activeStreams.has(ws.workspaceName)) {
          clearInterval(activeStreams.get(ws.workspaceName));
          activeStreams.delete(ws.workspaceName);
        }
        ws.workspaceName = null;
      }
    } catch (error) {
      console.error('Error handling WebSocket message:', error);
    }
  });
  
  ws.on('close', () => {
    console.log('Client disconnected from metrics stream');
    if (ws.workspaceName && activeStreams.has(ws.workspaceName)) {
      clearInterval(activeStreams.get(ws.workspaceName));
      activeStreams.delete(ws.workspaceName);
    }
  });
});

// Serve React app for all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'frontend/build', 'index.html'));
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  res.status(500).json({ error: 'Internal server error' });
});

server.listen(PORT, () => {
  console.log(`🚀 DevPod Dashboard running on http://localhost:${PORT}`);
  console.log(`📊 WebSocket metrics available on ws://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  
  // Clear all active intervals
  activeStreams.forEach(interval => clearInterval(interval));
  activeStreams.clear();
  
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});