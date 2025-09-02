import React, { useEffect, useState } from 'react';
import { 
  ThemeProvider, 
  createTheme, 
  CssBaseline,
  Container,
  Typography,
  Box,
  Grid,
  Alert,
  CircularProgress,
  Button,
  AppBar,
  Toolbar,
  TextField,
  InputAdornment,
  ToggleButton,
  ToggleButtonGroup
} from '@mui/material';
import { 
  Refresh as RefreshIcon,
  Search as SearchIcon,
  PlayArrow as RunningIcon,
  Stop as StoppedIcon,
  Computer as AllIcon
} from '@mui/icons-material';
import { useDashboardStore } from './store/dashboardStore';
import WorkspaceCard from './components/WorkspaceCard';
import MetricsSummary from './components/MetricsSummary';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#90caf9',
    },
    secondary: {
      main: '#f48fb1',
    },
    background: {
      default: '#0a0a0a',
      paper: '#1a1a1a',
    },
  },
  typography: {
    h4: {
      fontWeight: 600,
    },
    h6: {
      fontWeight: 500,
    }
  }
});

function App() {
  const {
    workspaces,
    loading,
    error,
    fetchWorkspaces,
    connectWebSocket,
    disconnectWebSocket,
    clearError,
    subscribeToMetrics,
    metrics
  } = useDashboardStore();

  // Local state for filtering
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  useEffect(() => {
    // Initial data fetch
    fetchWorkspaces();
    
    // Connect WebSocket for real-time metrics
    connectWebSocket();
    
    // Cleanup on unmount
    return () => {
      disconnectWebSocket();
    };
  }, []);

  // Subscribe to metrics for all running workspaces
  useEffect(() => {
    workspaces.forEach(workspace => {
      if (workspace.status === 'Running' || workspace.status === 'Started') {
        subscribeToMetrics(workspace.id);
      }
    });
  }, [workspaces, subscribeToMetrics]);

  const handleRefresh = () => {
    fetchWorkspaces();
  };

  // Filter workspaces based on search and status
  const filteredWorkspaces = workspaces.filter(workspace => {
    // Search filter
    const searchMatch = !searchQuery || 
      workspace.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (workspace.source && workspace.source.toLowerCase().includes(searchQuery.toLowerCase()));
    
    // Status filter
    const isRunning = workspace.status === 'Running' || workspace.status === 'Started';
    const isStopped = workspace.status === 'Stopped' || workspace.status === 'NotFound';
    
    let statusMatch = true;
    if (statusFilter === 'running') {
      statusMatch = isRunning;
    } else if (statusFilter === 'stopped') {
      statusMatch = isStopped;
    }
    
    return searchMatch && statusMatch;
  });

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      
      <AppBar position="static" sx={{ mb: 3 }}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            🚀 DevPod Dashboard
          </Typography>
          <Button 
            color="inherit" 
            onClick={handleRefresh}
            startIcon={<RefreshIcon />}
            disabled={loading}
          >
            Refresh
          </Button>
        </Toolbar>
      </AppBar>

      <Container maxWidth="xl">
        {error && (
          <Alert 
            severity="error" 
            onClose={clearError}
            sx={{ mb: 3 }}
          >
            {error}
          </Alert>
        )}

        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" gutterBottom>
            DevPod Workspaces
          </Typography>
          <Typography variant="body1" color="textSecondary" sx={{ mb: 3 }}>
            Monitor and manage your Claude Agent sandboxes
          </Typography>
          
          {/* Search and Filter Controls */}
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center', mb: 3 }}>
            <TextField
              placeholder="Search workspaces..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              size="small"
              sx={{ minWidth: 250, flexGrow: 1 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon />
                  </InputAdornment>
                ),
              }}
            />
            
            <ToggleButtonGroup
              value={statusFilter}
              exclusive
              onChange={(e, newFilter) => newFilter && setStatusFilter(newFilter)}
              size="small"
            >
              <ToggleButton value="all">
                <AllIcon sx={{ mr: 1 }} />
                All ({workspaces.length})
              </ToggleButton>
              <ToggleButton value="running">
                <RunningIcon sx={{ mr: 1 }} />
                Running ({workspaces.filter(w => w.status === 'Running' || w.status === 'Started').length})
              </ToggleButton>
              <ToggleButton value="stopped">
                <StoppedIcon sx={{ mr: 1 }} />
                Stopped ({workspaces.filter(w => w.status === 'Stopped' || w.status === 'NotFound').length})
              </ToggleButton>
            </ToggleButtonGroup>
          </Box>
        </Box>

        {workspaces.length > 0 && (
          <Box sx={{ mb: 4 }}>
            <MetricsSummary workspaces={workspaces} metrics={metrics} />
          </Box>
        )}

        {loading && workspaces.length === 0 ? (
          <Box display="flex" justifyContent="center" mt={4}>
            <CircularProgress />
          </Box>
        ) : (
          <>
            {workspaces.length === 0 ? (
              <Alert severity="info">
                No DevPod workspaces found. Create one using the CLI or quickstart script.
              </Alert>
            ) : filteredWorkspaces.length === 0 ? (
              <Alert severity="info">
                No workspaces match your search criteria. Try adjusting your filters.
              </Alert>
            ) : (
              <>
                {/* Results summary */}
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="textSecondary">
                    Showing {filteredWorkspaces.length} of {workspaces.length} workspaces
                    {searchQuery && ` matching "${searchQuery}"`}
                    {statusFilter !== 'all' && ` with status "${statusFilter}"`}
                  </Typography>
                </Box>
                
                <Grid container spacing={3}>
                  {filteredWorkspaces.map((workspace) => (
                    <Grid item xs={12} md={6} lg={4} key={workspace.id}>
                      <WorkspaceCard 
                        workspace={workspace}
                        metrics={metrics[workspace.id]}
                      />
                    </Grid>
                  ))}
                </Grid>
              </>
            )}
          </>
        )}

        <Box sx={{ mt: 6, p: 2, bgcolor: 'background.paper', borderRadius: 1 }}>
          <Typography variant="h6" gutterBottom>
            💡 Quick Commands
          </Typography>
          <Typography variant="body2" color="textSecondary">
            • Create sandbox: <code>./scripts/spin-up-sandbox.sh</code><br/>
            • List workspaces: <code>devpod list</code><br/>
            • SSH access: <code>devpod ssh &lt;workspace-name&gt;</code><br/>
            • View logs: <code>devpod logs &lt;workspace-name&gt;</code>
          </Typography>
        </Box>
      </Container>
    </ThemeProvider>
  );
}

export default App;