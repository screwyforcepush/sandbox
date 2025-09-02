import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  IconButton,
  Tooltip,
  Chip,
  Button,
  Paper,
  Tabs,
  Tab,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  LinearProgress,
  Grid,
  ButtonGroup,
  Collapse,
  Alert
} from '@mui/material';
import {
  Terminal as TerminalIcon,
  OpenInNew as OpenIcon,
  ExpandMore as ExpandIcon,
  ExpandLess as CollapseIcon,
  Refresh as RefreshIcon,
  ContentCopy as CopyIcon,
  GitHub as GitIcon,
  Storage as StorageIcon,
  Memory as MemoryIcon,
  Speed as CpuIcon
} from '@mui/icons-material';
import { useDashboardStore } from '../store/dashboardStore';
import { LineChart, Line, XAxis, YAxis, Tooltip as ChartTooltip, ResponsiveContainer } from 'recharts';

const WorkspaceDetails = ({ workspace, metrics, expanded, onToggleExpand }) => {
  const [activeTab, setActiveTab] = useState(0);
  const [commandOutput, setCommandOutput] = useState(null);
  const [loadingCommand, setLoadingCommand] = useState(false);
  
  const { 
    ports, 
    logs, 
    metricsHistory,
    fetchPorts, 
    fetchLogs, 
    executeCommand,
    copyToClipboard 
  } = useDashboardStore();
  
  const workspacePorts = ports[workspace.id];
  const workspaceLogs = logs[workspace.id];
  const workspaceHistory = metricsHistory[workspace.id] || [];
  
  // Fetch data when expanded
  useEffect(() => {
    if (expanded) {
      fetchPorts(workspace.id);
      fetchLogs(workspace.id);
    }
  }, [expanded, workspace.id, fetchPorts, fetchLogs]);
  
  // Calculate health score
  const calculateHealthScore = () => {
    if (!metrics || metrics.status !== 'running') return null;
    
    const cpuScore = Math.max(0, 100 - parseFloat(metrics.metrics?.cpu?.replace('%', '') || 0));
    const memScore = Math.max(0, 100 - parseFloat(metrics.metrics?.memPerc?.replace('%', '') || 0));
    
    const healthScore = Math.round((cpuScore + memScore) / 2);
    
    return {
      score: healthScore,
      color: healthScore > 80 ? 'success' : healthScore > 50 ? 'warning' : 'error',
      label: healthScore > 80 ? 'Healthy' : healthScore > 50 ? 'Warning' : 'Critical'
    };
  };
  
  const health = calculateHealthScore();
  
  // Quick actions
  const quickActions = [
    { label: 'Git Status', icon: <GitIcon />, command: 'git status' },
    { label: 'Disk Usage', icon: <StorageIcon />, command: 'df -h' },
    { label: 'Memory', icon: <MemoryIcon />, command: 'free -h' },
    { label: 'Top Processes', icon: <CpuIcon />, command: 'ps aux --sort=-%cpu | head -10' }
  ];
  
  const handleQuickAction = async (command) => {
    setLoadingCommand(true);
    setCommandOutput(null);
    try {
      const result = await executeCommand(workspace.id, command);
      setCommandOutput(result);
    } catch (error) {
      setCommandOutput({ error: error.message });
    } finally {
      setLoadingCommand(false);
    }
  };
  
  const handleOpenPort = (port) => {
    window.open(`http://localhost:${port.hostPort}`, '_blank');
  };
  
  // Format metrics history for chart
  const chartData = workspaceHistory.slice(-20).map((point, index) => ({
    time: index,
    cpu: point.cpu,
    memory: point.memory
  }));
  
  return (
    <Box sx={{ mt: 2 }}>
      {/* Health Score and Expand Button */}
      <Box display="flex" alignItems="center" justifyContent="space-between" mb={2}>
        <Box display="flex" alignItems="center" gap={2}>
          {health && (
            <Chip
              label={`Health: ${health.score}% - ${health.label}`}
              color={health.color}
              size="small"
            />
          )}
          <Typography variant="body2" color="textSecondary">
            Click to view details
          </Typography>
        </Box>
        <IconButton onClick={onToggleExpand} size="small">
          {expanded ? <CollapseIcon /> : <ExpandIcon />}
        </IconButton>
      </Box>
      
      <Collapse in={expanded}>
        <Paper sx={{ p: 2, bgcolor: 'background.default' }}>
          <Tabs value={activeTab} onChange={(e, v) => setActiveTab(v)} sx={{ mb: 2 }}>
            <Tab label="Ports" />
            <Tab label="Metrics" />
            <Tab label="Quick Actions" />
            <Tab label="Logs" />
          </Tabs>
          
          {/* Ports Tab */}
          {activeTab === 0 && (
            <Box>
              {workspacePorts?.ports?.length > 0 ? (
                <List dense>
                  {workspacePorts.ports.map((port, idx) => (
                    <ListItem key={idx}>
                      <ListItemText
                        primary={`Port ${port.containerPort} → ${port.hostPort}`}
                        secondary={`Protocol: ${port.protocol.toUpperCase()}`}
                      />
                      <ListItemSecondaryAction>
                        <Tooltip title="Open in browser">
                          <IconButton 
                            edge="end" 
                            onClick={() => handleOpenPort(port)}
                            size="small"
                          >
                            <OpenIcon />
                          </IconButton>
                        </Tooltip>
                      </ListItemSecondaryAction>
                    </ListItem>
                  ))}
                </List>
              ) : (
                <Typography variant="body2" color="textSecondary">
                  No exposed ports
                </Typography>
              )}
            </Box>
          )}
          
          {/* Metrics History Tab */}
          {activeTab === 1 && (
            <Box>
              {chartData.length > 0 ? (
                <Box sx={{ height: 200 }}>
                  <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={chartData}>
                      <XAxis dataKey="time" hide />
                      <YAxis domain={[0, 100]} />
                      <ChartTooltip />
                      <Line 
                        type="monotone" 
                        dataKey="cpu" 
                        stroke="#8884d8" 
                        name="CPU %"
                        strokeWidth={2}
                        dot={false}
                      />
                      <Line 
                        type="monotone" 
                        dataKey="memory" 
                        stroke="#82ca9d" 
                        name="Memory %"
                        strokeWidth={2}
                        dot={false}
                      />
                    </LineChart>
                  </ResponsiveContainer>
                </Box>
              ) : (
                <Typography variant="body2" color="textSecondary">
                  No metrics history available
                </Typography>
              )}
            </Box>
          )}
          
          {/* Quick Actions Tab */}
          {activeTab === 2 && (
            <Box>
              <Grid container spacing={1} sx={{ mb: 2 }}>
                {quickActions.map((action) => (
                  <Grid item xs={6} key={action.label}>
                    <Button
                      fullWidth
                      variant="outlined"
                      size="small"
                      startIcon={action.icon}
                      onClick={() => handleQuickAction(action.command)}
                      disabled={loadingCommand}
                    >
                      {action.label}
                    </Button>
                  </Grid>
                ))}
              </Grid>
              
              {loadingCommand && <LinearProgress sx={{ mb: 2 }} />}
              
              {commandOutput && (
                <Paper sx={{ p: 2, bgcolor: 'background.paper' }}>
                  <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                    <Typography variant="caption" sx={{ fontFamily: 'monospace' }}>
                      $ {commandOutput.command}
                    </Typography>
                    <IconButton
                      size="small"
                      onClick={() => copyToClipboard(commandOutput.output || commandOutput.error)}
                    >
                      <CopyIcon fontSize="small" />
                    </IconButton>
                  </Box>
                  <Typography
                    variant="body2"
                    sx={{
                      fontFamily: 'monospace',
                      whiteSpace: 'pre-wrap',
                      wordBreak: 'break-all',
                      maxHeight: 200,
                      overflow: 'auto',
                      color: commandOutput.error ? 'error.main' : 'text.primary'
                    }}
                  >
                    {commandOutput.output || commandOutput.error}
                  </Typography>
                </Paper>
              )}
            </Box>
          )}
          
          {/* Logs Tab */}
          {activeTab === 3 && (
            <Box>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={1}>
                <Typography variant="caption" color="textSecondary">
                  Last 100 lines
                </Typography>
                <IconButton size="small" onClick={() => fetchLogs(workspace.id)}>
                  <RefreshIcon fontSize="small" />
                </IconButton>
              </Box>
              <Paper
                sx={{
                  p: 2,
                  bgcolor: 'grey.900',
                  maxHeight: 300,
                  overflow: 'auto',
                }}
              >
                <Typography
                  variant="body2"
                  sx={{
                    fontFamily: 'monospace',
                    fontSize: '0.8rem',
                    whiteSpace: 'pre-wrap',
                    wordBreak: 'break-all',
                  }}
                >
                  {workspaceLogs?.logs || 'No logs available'}
                </Typography>
              </Paper>
            </Box>
          )}
        </Paper>
      </Collapse>
    </Box>
  );
};

export default WorkspaceDetails;