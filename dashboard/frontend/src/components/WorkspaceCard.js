import React, { useState } from 'react';
import {
  Card,
  CardContent,
  CardActions,
  Typography,
  Button,
  Chip,
  Box,
  IconButton,
  Tooltip,
  Grid,
  LinearProgress,
  Snackbar,
  Alert,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText
} from '@mui/material';
import {
  PlayArrow as StartIcon,
  Stop as StopIcon,
  Delete as DeleteIcon,
  ContentCopy as CopyIcon,
  Terminal as TerminalIcon,
  Memory as MemoryIcon,
  Speed as CpuIcon,
  NetworkCheck as NetworkIcon
} from '@mui/icons-material';
import { useDashboardStore } from '../store/dashboardStore';

import WorkspaceDetails from './WorkspaceDetails';

const WorkspaceCard = ({ workspace, metrics }) => {
  const [copySuccess, setCopySuccess] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [detailsExpanded, setDetailsExpanded] = useState(false);
  const { startWorkspace, stopWorkspace, deleteWorkspace, copyToClipboard } = useDashboardStore();

  const isRunning = workspace.status === 'Running' || workspace.status === 'Started';
  const isStopped = workspace.status === 'Stopped' || workspace.status === 'NotFound';

  // Parse repository info from source
  const getDisplaySource = (source) => {
    if (!source || typeof source !== 'string') return 'Unknown';
    
    // Backend already provides parsed format like "owner/repo@branch"
    // Just return it directly
    return source;
  };

  // Parse CPU percentage for progress bar
  const getCpuPercentage = (cpuStr) => {
    if (!cpuStr || typeof cpuStr !== 'string') return 0;
    const match = cpuStr.match(/([0-9.]+)%/);
    return match ? parseFloat(match[1]) : 0;
  };

  // Parse memory percentage
  const getMemPercentage = (memStr) => {
    if (!memStr || typeof memStr !== 'string') return 0;
    const match = memStr.match(/([0-9.]+)%/);
    return match ? parseFloat(match[1]) : 0;
  };

  // Get status color
  const getStatusColor = (status) => {
    switch (status) {
      case 'Running':
      case 'Started':
        return 'success';
      case 'Stopped':
      case 'NotFound':
        return 'default';
      case 'Starting':
      case 'Stopping':
        return 'warning';
      default:
        return 'default';
    }
  };

  // Handle copy SSH command
  const handleCopySSH = async () => {
    const command = `devpod ssh ${workspace.id}`;
    const success = await copyToClipboard(command);
    if (success) {
      setCopySuccess(true);
    }
  };

  // Handle workspace actions
  const handleStart = () => startWorkspace(workspace.id);
  const handleStop = () => stopWorkspace(workspace.id);
  const handleDelete = () => setDeleteDialogOpen(true);
  const handleConfirmDelete = () => {
    deleteWorkspace(workspace.id);
    setDeleteDialogOpen(false);
  };

  return (
    <>
      <Card 
        sx={{ 
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          bgcolor: 'background.paper',
          border: isRunning ? '1px solid rgba(76, 175, 80, 0.3)' : '1px solid rgba(255, 255, 255, 0.1)'
        }}
      >
        <CardContent sx={{ flexGrow: 1 }}>
          {/* Header */}
          <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
            <Box sx={{ flexGrow: 1, mr: 1 }}>
              <Typography variant="h6" sx={{ fontWeight: 600, fontSize: '1.1rem' }}>
                {getDisplaySource(workspace.source)}
              </Typography>
              <Typography 
                variant="body2" 
                color="textSecondary"
                sx={{ 
                  fontFamily: 'monospace',
                  fontSize: '0.8rem',
                  wordBreak: 'break-all'
                }}
                title={workspace.id}
              >
                {workspace.id}
              </Typography>
            </Box>
            <Chip 
              label={workspace.status || 'Unknown'}
              color={getStatusColor(workspace.status)}
              size="small"
              sx={{ ml: 1 }}
            />
          </Box>

          {/* Metrics */}
          {isRunning && metrics && metrics.status === 'running' && (
            <Box sx={{ mb: 2 }}>
              <Grid container spacing={1}>
                {/* CPU */}
                <Grid item xs={12}>
                  <Box display="flex" alignItems="center" mb={1}>
                    <CpuIcon sx={{ mr: 1, fontSize: 16 }} />
                    <Typography variant="body2" sx={{ mr: 1 }}>
                      CPU: {metrics.metrics?.cpu || 'N/A'}
                    </Typography>
                  </Box>
                  <LinearProgress 
                    variant="determinate" 
                    value={Math.min((getCpuPercentage(metrics.metrics?.cpu) / 16), 100)}
                    color={getCpuPercentage(metrics.metrics?.cpu) > 800 ? 'error' : 'primary'}
                    sx={{ height: 4, borderRadius: 2 }}
                    title={`${getCpuPercentage(metrics.metrics?.cpu)}% of 1600% total`}
                  />
                </Grid>

                {/* Memory */}
                <Grid item xs={12}>
                  <Box display="flex" alignItems="center" mb={1}>
                    <MemoryIcon sx={{ mr: 1, fontSize: 16 }} />
                    <Typography variant="body2">
                      Memory: {metrics.metrics?.memUsage || 'N/A'}
                    </Typography>
                  </Box>
                  <LinearProgress 
                    variant="determinate" 
                    value={Math.min(getMemPercentage(metrics.metrics?.memPerc), 100)}
                    color={getMemPercentage(metrics.metrics?.memPerc) > 80 ? 'error' : 'primary'}
                    sx={{ height: 4, borderRadius: 2 }}
                  />
                </Grid>

                {/* Network & Disk */}
                <Grid item xs={6}>
                  <Box display="flex" alignItems="center">
                    <NetworkIcon sx={{ mr: 1, fontSize: 16 }} />
                    <Typography variant="caption">
                      {metrics.metrics?.netIO || 'N/A'}
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="caption">
                    Disk: {metrics.metrics?.blockIO || 'N/A'}
                  </Typography>
                </Grid>

                {/* PIDs */}
                <Grid item xs={12}>
                  <Typography variant="caption" color="textSecondary">
                    Processes: {metrics.metrics?.pids || 'N/A'} | 
                    Container: {metrics.metrics?.containerId || 'N/A'}
                  </Typography>
                </Grid>
              </Grid>
            </Box>
          )}

          {/* No metrics available */}
          {isRunning && (!metrics || metrics.status !== 'running') && (
            <Box sx={{ mb: 2, p: 2, bgcolor: 'action.hover', borderRadius: 1 }}>
              <Typography variant="body2" color="textSecondary" align="center">
                Loading metrics...
              </Typography>
            </Box>
          )}

          {/* Workspace info */}
          <Box>
            <Typography variant="caption" color="textSecondary">
              {workspace.age && workspace.age !== 'Unknown' ? `Age: ${workspace.age}` : ''}
            </Typography>
          </Box>
          
          {/* Expandable Details */}
          {isRunning && (
            <WorkspaceDetails
              workspace={workspace}
              metrics={metrics}
              expanded={detailsExpanded}
              onToggleExpand={() => setDetailsExpanded(!detailsExpanded)}
            />
          )}
        </CardContent>

        <CardActions sx={{ p: 2, pt: 1 }}>
          <Grid container spacing={1}>
            {/* Primary action buttons - larger touch targets */}
            <Grid item xs={6}>
              {isStopped ? (
                <Button
                  fullWidth
                  variant="contained"
                  startIcon={<StartIcon />}
                  onClick={handleStart}
                  color="success"
                  size="medium"
                >
                  Start
                </Button>
              ) : (
                <Button
                  fullWidth
                  variant="contained"
                  startIcon={<StopIcon />}
                  onClick={handleStop}
                  color="warning"
                  size="medium"
                >
                  Stop
                </Button>
              )}
            </Grid>

            <Grid item xs={6}>
              <Button
                fullWidth
                variant="outlined"
                startIcon={<TerminalIcon />}
                endIcon={<CopyIcon />}
                onClick={handleCopySSH}
                size="medium"
              >
                SSH
              </Button>
            </Grid>

            {/* Secondary actions */}
            <Grid item xs={12}>
              <Box display="flex" justifyContent="center">
                <Tooltip title="Delete workspace (irreversible)">
                  <IconButton
                    onClick={handleDelete}
                    color="error"
                    size="medium"
                    sx={{ minWidth: 48, minHeight: 48 }}
                  >
                    <DeleteIcon />
                  </IconButton>
                </Tooltip>
              </Box>
            </Grid>
          </Grid>
        </CardActions>
      </Card>

      {/* Success notification */}
      <Snackbar
        open={copySuccess}
        autoHideDuration={3000}
        onClose={() => setCopySuccess(false)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert onClose={() => setCopySuccess(false)} severity="success">
          SSH command copied: devpod ssh {workspace.id}
        </Alert>
      </Snackbar>

      {/* Delete confirmation dialog */}
      <Dialog
        open={deleteDialogOpen}
        onClose={() => setDeleteDialogOpen(false)}
        aria-labelledby="delete-dialog-title"
      >
        <DialogTitle id="delete-dialog-title">
          Delete Workspace
        </DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete workspace "{getDisplaySource(workspace.source)}"?
            <br />
            <br />
            <strong>This action cannot be undone.</strong> All data in the workspace will be permanently lost.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>
            Cancel
          </Button>
          <Button onClick={handleConfirmDelete} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default WorkspaceCard;