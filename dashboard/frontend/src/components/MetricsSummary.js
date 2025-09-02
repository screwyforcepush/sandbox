import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Grid,
  Chip
} from '@mui/material';
import {
  Computer as ComputerIcon,
  PlayArrow as RunningIcon,
  Stop as StoppedIcon,
  Memory as MemoryIcon,
  Speed as CpuIcon
} from '@mui/icons-material';

const MetricsSummary = ({ workspaces, metrics }) => {
  // Calculate summary statistics
  const totalWorkspaces = workspaces.length;
  const runningWorkspaces = workspaces.filter(w => 
    w.status === 'Running' || w.status === 'Started'
  ).length;
  const stoppedWorkspaces = totalWorkspaces - runningWorkspaces;

  // Calculate average CPU and memory for running workspaces
  const runningMetrics = Object.values(metrics).filter(m => 
    m && m.status === 'running' && m.metrics
  );

  // Calculate total CPU usage and average
  const totalCpu = runningMetrics.reduce((sum, m) => {
    const cpu = parseFloat(m.metrics.cpu?.replace('%', '') || 0);
    return sum + cpu;
  }, 0);
  
  const avgCpu = runningMetrics.length > 0 ? totalCpu / runningMetrics.length : 0;
  
  // Maximum possible CPU is 1600% (16 cores * 100%)
  const MAX_CPU_PERCENT = 1600;
  const totalCpuOfMax = (totalCpu / MAX_CPU_PERCENT) * 100;

  const totalMemoryGB = runningMetrics.reduce((sum, m) => {
    const memUsage = m.metrics.memUsage || '';
    // Extract used memory from format like "4.329GiB / 62.68GiB"
    const match = memUsage.match(/([0-9.]+)\s*([A-Za-z]+)\s*\//);
    if (match) {
      const value = parseFloat(match[1]);
      const unit = match[2].toUpperCase();
      // Convert to GB
      if (unit === 'GB' || unit === 'GIB') return sum + value;
      if (unit === 'MB' || unit === 'MIB') return sum + (value / 1024);
      if (unit === 'KB' || unit === 'KIB') return sum + (value / (1024 * 1024));
    }
    return sum;
  }, 0);

  const formatPercentage = (value) => `${value.toFixed(1)}%`;
  const formatMemory = (value) => `${value.toFixed(1)} GB`;

  return (
    <Card sx={{ bgcolor: 'background.paper' }}>
      <CardContent>
        <Typography variant="h6" gutterBottom>
          📊 System Overview
        </Typography>
        
        <Grid container spacing={3}>
          {/* Total Workspaces */}
          <Grid item xs={6} md={3}>
            <Box display="flex" alignItems="center">
              <ComputerIcon sx={{ mr: 1, color: 'primary.main' }} />
              <Box>
                <Typography variant="h4" color="primary">
                  {totalWorkspaces}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Total Workspaces
                </Typography>
              </Box>
            </Box>
          </Grid>

          {/* Running */}
          <Grid item xs={6} md={3}>
            <Box display="flex" alignItems="center">
              <RunningIcon sx={{ mr: 1, color: 'success.main' }} />
              <Box>
                <Typography variant="h4" color="success.main">
                  {runningWorkspaces}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Running
                </Typography>
              </Box>
            </Box>
          </Grid>

          {/* Stopped */}
          <Grid item xs={6} md={3}>
            <Box display="flex" alignItems="center">
              <StoppedIcon sx={{ mr: 1, color: 'text.secondary' }} />
              <Box>
                <Typography variant="h4" color="text.secondary">
                  {stoppedWorkspaces}
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  Stopped
                </Typography>
              </Box>
            </Box>
          </Grid>

          {/* Total CPU */}
          <Grid item xs={6} md={3}>
            <Box display="flex" alignItems="center">
              <CpuIcon sx={{ mr: 1, color: totalCpu > 800 ? 'error.main' : 'info.main' }} />
              <Box>
                <Typography 
                  variant="h4" 
                  color={totalCpu > 800 ? 'error.main' : 'info.main'}
                >
                  {totalCpu.toFixed(0)}%
                </Typography>
                <Typography variant="body2" color="textSecondary">
                  CPU / {MAX_CPU_PERCENT}%
                </Typography>
              </Box>
            </Box>
          </Grid>
        </Grid>

        {/* Additional metrics row */}
        {runningWorkspaces > 0 && (
          <Box sx={{ mt: 3 }}>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <Box display="flex" alignItems="center">
                  <MemoryIcon sx={{ mr: 1, color: 'secondary.main' }} />
                  <Box>
                    <Typography variant="body1">
                      Total Memory Usage: {formatMemory(totalMemoryGB)}
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Across {runningMetrics.length} active containers
                    </Typography>
                  </Box>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Box display="flex" alignItems="center">
                  <CpuIcon sx={{ mr: 1, color: 'info.main' }} />
                  <Box>
                    <Typography variant="body1">
                      Total CPU: {totalCpu.toFixed(0)}% / {MAX_CPU_PERCENT}% ({totalCpuOfMax.toFixed(1)}%)
                    </Typography>
                    <Typography variant="body2" color="textSecondary">
                      Average per container: {formatPercentage(avgCpu)}
                    </Typography>
                  </Box>
                </Box>
              </Grid>
              
            </Grid>
            
            <Grid container spacing={2} sx={{ mt: 1 }}>
              <Grid item xs={12}>
                <Box display="flex" alignItems="center" flexWrap="wrap" gap={1}>
                  <Typography variant="body2" color="textSecondary">
                    Status:
                  </Typography>
                  {totalCpuOfMax > 50 && (
                    <Chip 
                      label="High CPU Usage" 
                      color="error" 
                      size="small" 
                    />
                  )}
                  {totalMemoryGB > 10 && (
                    <Chip 
                      label="High Memory Usage" 
                      color="warning" 
                      size="small" 
                    />
                  )}
                  {runningWorkspaces === 0 && (
                    <Chip 
                      label="All Stopped" 
                      color="default" 
                      size="small" 
                    />
                  )}
                  {runningWorkspaces > 0 && totalCpuOfMax < 25 && totalMemoryGB < 5 && (
                    <Chip 
                      label="Healthy" 
                      color="success" 
                      size="small" 
                    />
                  )}
                </Box>
              </Grid>
            </Grid>
          </Box>
        )}
      </CardContent>
    </Card>
  );
};

export default MetricsSummary;