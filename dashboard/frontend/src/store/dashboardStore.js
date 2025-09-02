import { create } from 'zustand';
import axios from 'axios';

const API_BASE = process.env.NODE_ENV === 'production' ? '' : 'http://localhost:3001';

export const useDashboardStore = create((set, get) => ({
  // State
  workspaces: [],
  metrics: {},
  ports: {},
  logs: {},
  metricsHistory: {},
  loading: false,
  error: null,
  wsConnection: null,

  // Actions
  setLoading: (loading) => set({ loading }),
  setError: (error) => set({ error }),
  
  setWorkspaces: (workspaces) => set({ workspaces }),
  
  updateMetrics: (workspaceName, metricsData) => {
    set((state) => {
      // Update current metrics
      const newState = {
        metrics: {
          ...state.metrics,
          [workspaceName]: metricsData
        }
      };
      
      // Store metrics history (keep last 100 data points)
      if (metricsData.status === 'running' && metricsData.metrics) {
        const history = state.metricsHistory[workspaceName] || [];
        const newHistory = [...history, {
          timestamp: Date.now(),
          cpu: parseFloat(metricsData.metrics.cpu?.replace('%', '') || 0),
          memory: parseFloat(metricsData.metrics.memPerc?.replace('%', '') || 0)
        }].slice(-100);
        
        newState.metricsHistory = {
          ...state.metricsHistory,
          [workspaceName]: newHistory
        };
      }
      
      return newState;
    });
  },
  
  updatePorts: (workspaceName, portsData) => set((state) => ({
    ports: {
      ...state.ports,
      [workspaceName]: portsData
    }
  })),
  
  updateLogs: (workspaceName, logsData) => set((state) => ({
    logs: {
      ...state.logs,
      [workspaceName]: logsData
    }
  })),

  // API calls
  fetchWorkspaces: async () => {
    set({ loading: true, error: null });
    try {
      const response = await axios.get(`${API_BASE}/api/workspaces`);
      set({ workspaces: response.data, loading: false });
    } catch (error) {
      console.error('Error fetching workspaces:', error);
      set({ error: error.message, loading: false });
    }
  },

  startWorkspace: async (name) => {
    try {
      await axios.post(`${API_BASE}/api/workspaces/${name}/start`);
      // Refresh workspaces after operation
      get().fetchWorkspaces();
    } catch (error) {
      console.error(`Error starting workspace ${name}:`, error);
      set({ error: `Failed to start ${name}: ${error.message}` });
    }
  },

  stopWorkspace: async (name) => {
    try {
      await axios.post(`${API_BASE}/api/workspaces/${name}/stop`);
      get().fetchWorkspaces();
    } catch (error) {
      console.error(`Error stopping workspace ${name}:`, error);
      set({ error: `Failed to stop ${name}: ${error.message}` });
    }
  },

  deleteWorkspace: async (name) => {
    if (!window.confirm(`Are you sure you want to delete workspace "${name}"? This action cannot be undone.`)) {
      return;
    }
    
    try {
      await axios.delete(`${API_BASE}/api/workspaces/${name}`);
      get().fetchWorkspaces();
    } catch (error) {
      console.error(`Error deleting workspace ${name}:`, error);
      set({ error: `Failed to delete ${name}: ${error.message}` });
    }
  },

  // WebSocket for real-time metrics
  connectWebSocket: () => {
    const wsUrl = process.env.NODE_ENV === 'production' 
      ? `ws://${window.location.host}`
      : 'ws://localhost:3001';
    
    const ws = new WebSocket(wsUrl);
    
    ws.onopen = () => {
      console.log('Connected to metrics WebSocket');
      set({ wsConnection: ws });
    };
    
    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.type === 'metrics') {
          get().updateMetrics(data.workspaceName, data.data);
        }
      } catch (error) {
        console.error('Error parsing WebSocket message:', error);
      }
    };
    
    ws.onclose = () => {
      console.log('WebSocket connection closed');
      set({ wsConnection: null });
      // Attempt to reconnect after 5 seconds
      setTimeout(() => {
        if (!get().wsConnection) {
          get().connectWebSocket();
        }
      }, 5000);
    };
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  },

  subscribeToMetrics: (workspaceName) => {
    const { wsConnection } = get();
    if (wsConnection && wsConnection.readyState === WebSocket.OPEN) {
      wsConnection.send(JSON.stringify({
        type: 'subscribe',
        workspaceName
      }));
    }
  },

  unsubscribeFromMetrics: (workspaceName) => {
    const { wsConnection } = get();
    if (wsConnection && wsConnection.readyState === WebSocket.OPEN) {
      wsConnection.send(JSON.stringify({
        type: 'unsubscribe',
        workspaceName
      }));
    }
  },

  disconnectWebSocket: () => {
    const { wsConnection } = get();
    if (wsConnection) {
      wsConnection.close();
      set({ wsConnection: null });
    }
  },

  // Fetch workspace ports
  fetchPorts: async (workspaceName) => {
    try {
      const response = await axios.get(`${API_BASE}/api/workspaces/${workspaceName}/ports`);
      get().updatePorts(workspaceName, response.data);
    } catch (error) {
      console.error(`Error fetching ports for ${workspaceName}:`, error);
    }
  },

  // Fetch workspace logs
  fetchLogs: async (workspaceName) => {
    try {
      const response = await axios.get(`${API_BASE}/api/workspaces/${workspaceName}/logs`);
      get().updateLogs(workspaceName, response.data);
    } catch (error) {
      console.error(`Error fetching logs for ${workspaceName}:`, error);
    }
  },

  // Execute command in workspace
  executeCommand: async (workspaceName, command) => {
    try {
      const response = await axios.post(`${API_BASE}/api/workspaces/${workspaceName}/execute`, {
        command
      });
      return response.data;
    } catch (error) {
      console.error(`Error executing command in ${workspaceName}:`, error);
      throw error;
    }
  },

  // Utility actions
  clearError: () => set({ error: null }),

  copyToClipboard: async (text) => {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (error) {
      console.error('Error copying to clipboard:', error);
      return false;
    }
  }
}));