# State Management Documentation

## Overview

GitInsight employs a hybrid state management approach combining Svelte's reactive stores for the primary application state with Zustand for React component state management. This document covers the complete state management architecture, patterns, and best practices for maintaining consistent application state across the SvelteKit application.

## State Management Architecture

### State Layer Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Application State                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                  Svelte Stores Layer                        │  │
│  │                                                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │    Auth     │  │    User     │  │    Application      │  │  │
│  │  │   Store     │  │   Store     │  │      Store          │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  │                                                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │ Repository  │  │  Insights   │  │        UI           │  │  │
│  │  │   Store     │  │   Store     │  │      Store          │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                React State Layer                            │  │
│  │                                                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │   Chart     │  │   Widget    │  │      Editor         │  │  │
│  │  │   Store     │  │   Store     │  │      Store          │  │  │
│  │  │ (Zustand)   │  │ (Zustand)   │  │    (Zustand)        │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                  Persistence Layer                          │  │
│  │                                                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │ Local       │  │ Session     │  │      Server         │  │  │
│  │  │ Storage     │  │ Storage     │  │      State          │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Svelte Stores

### Authentication Store

```typescript
// src/lib/stores/auth.ts
import { writable, derived } from 'svelte/store';
import { browser } from '$app/environment';
import type { User } from '$types/user';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

function createAuthStore() {
  const { subscribe, set, update } = writable<AuthState>({
    user: null,
    token: null,
    isAuthenticated: false,
    isLoading: false,
    error: null
  });

  return {
    subscribe,
    
    // Initialize auth state from storage
    initialize() {
      if (!browser) return;
      
      const token = localStorage.getItem('auth-token');
      const userStr = localStorage.getItem('auth-user');
      
      if (token && userStr) {
        try {
          const user = JSON.parse(userStr);
          this.setUser(user, token);
        } catch (error) {
          this.clearAuth();
        }
      }
    },
    
    // Set authenticated user
    setUser(user: User, token?: string) {
      if (browser) {
        localStorage.setItem('auth-user', JSON.stringify(user));
        if (token) {
          localStorage.setItem('auth-token', token);
        }
      }
      
      update(state => ({
        ...state,
        user,
        token: token || state.token,
        isAuthenticated: true,
        isLoading: false,
        error: null
      }));
    },
    
    // Set loading state
    setLoading(isLoading: boolean) {
      update(state => ({ ...state, isLoading }));
    },
    
    // Set error state
    setError(error: string) {
      update(state => ({ ...state, error, isLoading: false }));
    },
    
    // Clear authentication
    clearAuth() {
      if (browser) {
        localStorage.removeItem('auth-token');
        localStorage.removeItem('auth-user');
      }
      
      set({
        user: null,
        token: null,
        isAuthenticated: false,
        isLoading: false,
        error: null
      });
    },
    
    // Update user profile
    updateUser(updates: Partial<User>) {
      update(state => {
        if (!state.user) return state;
        
        const updatedUser = { ...state.user, ...updates };
        
        if (browser) {
          localStorage.setItem('auth-user', JSON.stringify(updatedUser));
        }
        
        return { ...state, user: updatedUser };
      });
    }
  };
}

export const authStore = createAuthStore();

// Derived stores
export const isAuthenticated = derived(authStore, $auth => $auth.isAuthenticated);
export const currentUser = derived(authStore, $auth => $auth.user);
export const authToken = derived(authStore, $auth => $auth.token);
```

### Repository Store

```typescript
// src/lib/stores/repositories.ts
import { writable, derived } from 'svelte/store';
import type { Repository, RepositoryFilters, PaginationInfo } from '$types/repository';

interface RepositoryState {
  repositories: Repository[];
  selectedRepository: Repository | null;
  filters: RepositoryFilters;
  pagination: PaginationInfo;
  isLoading: boolean;
  error: string | null;
  searchQuery: string;
}

function createRepositoryStore() {
  const { subscribe, set, update } = writable<RepositoryState>({
    repositories: [],
    selectedRepository: null,
    filters: {
      sort: 'updated',
      filter: 'all',
      language: null
    },
    pagination: {
      page: 1,
      limit: 20,
      total: 0,
      totalPages: 0
    },
    isLoading: false,
    error: null,
    searchQuery: ''
  });

  return {
    subscribe,
    
    // Load repositories
    async loadRepositories(filters?: Partial<RepositoryFilters>) {
      update(state => ({ ...state, isLoading: true, error: null }));
      
      try {
        const response = await fetch('/api/repositories?' + new URLSearchParams({
          ...state.filters,
          ...filters,
          page: state.pagination.page.toString(),
          limit: state.pagination.limit.toString()
        }));
        
        if (!response.ok) {
          throw new Error('Failed to load repositories');
        }
        
        const data = await response.json();
        
        update(state => ({
          ...state,
          repositories: data.repositories,
          pagination: data.pagination,
          isLoading: false
        }));
      } catch (error) {
        update(state => ({
          ...state,
          error: error.message,
          isLoading: false
        }));
      }
    },
    
    // Add repository
    addRepository(repository: Repository) {
      update(state => ({
        ...state,
        repositories: [repository, ...state.repositories]
      }));
    },
    
    // Update repository
    updateRepository(id: string, updates: Partial<Repository>) {
      update(state => ({
        ...state,
        repositories: state.repositories.map(repo =>
          repo.id === id ? { ...repo, ...updates } : repo
        ),
        selectedRepository: state.selectedRepository?.id === id
          ? { ...state.selectedRepository, ...updates }
          : state.selectedRepository
      }));
    },
    
    // Remove repository
    removeRepository(id: string) {
      update(state => ({
        ...state,
        repositories: state.repositories.filter(repo => repo.id !== id),
        selectedRepository: state.selectedRepository?.id === id
          ? null
          : state.selectedRepository
      }));
    },
    
    // Set selected repository
    setSelectedRepository(repository: Repository | null) {
      update(state => ({ ...state, selectedRepository: repository }));
    },
    
    // Update filters
    setFilters(filters: Partial<RepositoryFilters>) {
      update(state => ({
        ...state,
        filters: { ...state.filters, ...filters },
        pagination: { ...state.pagination, page: 1 }
      }));
    },
    
    // Set search query
    setSearchQuery(query: string) {
      update(state => ({ ...state, searchQuery: query }));
    },
    
    // Set pagination
    setPagination(pagination: Partial<PaginationInfo>) {
      update(state => ({
        ...state,
        pagination: { ...state.pagination, ...pagination }
      }));
    },
    
    // Clear error
    clearError() {
      update(state => ({ ...state, error: null }));
    }
  };
}

export const repositoryStore = createRepositoryStore();

// Derived stores
export const filteredRepositories = derived(
  [repositoryStore],
  ([$repositories]) => {
    if (!$repositories.searchQuery) {
      return $repositories.repositories;
    }
    
    const query = $repositories.searchQuery.toLowerCase();
    return $repositories.repositories.filter(repo =>
      repo.name.toLowerCase().includes(query) ||
      repo.description?.toLowerCase().includes(query) ||
      repo.language?.toLowerCase().includes(query)
    );
  }
);

export const selectedRepository = derived(
  repositoryStore,
  $repositories => $repositories.selectedRepository
);
```

### UI Store

```typescript
// src/lib/stores/ui.ts
import { writable, derived } from 'svelte/store';
import { browser } from '$app/environment';

interface UIState {
  sidebarOpen: boolean;
  theme: 'light' | 'dark' | 'system';
  notifications: Notification[];
  modals: Record<string, boolean>;
  loading: Record<string, boolean>;
  breadcrumbs: BreadcrumbItem[];
}

interface Notification {
  id: string;
  type: 'success' | 'error' | 'warning' | 'info';
  title: string;
  message: string;
  duration?: number;
  actions?: NotificationAction[];
}

interface NotificationAction {
  label: string;
  action: () => void;
}

interface BreadcrumbItem {
  label: string;
  href?: string;
}

function createUIStore() {
  const { subscribe, set, update } = writable<UIState>({
    sidebarOpen: true,
    theme: 'system',
    notifications: [],
    modals: {},
    loading: {},
    breadcrumbs: []
  });

  return {
    subscribe,
    
    // Initialize UI state
    initialize() {
      if (!browser) return;
      
      const sidebarOpen = localStorage.getItem('sidebar-open') !== 'false';
      const theme = (localStorage.getItem('theme') as UIState['theme']) || 'system';
      
      update(state => ({ ...state, sidebarOpen, theme }));
    },
    
    // Toggle sidebar
    toggleSidebar() {
      update(state => {
        const sidebarOpen = !state.sidebarOpen;
        if (browser) {
          localStorage.setItem('sidebar-open', sidebarOpen.toString());
        }
        return { ...state, sidebarOpen };
      });
    },
    
    // Set theme
    setTheme(theme: UIState['theme']) {
      if (browser) {
        localStorage.setItem('theme', theme);
      }
      update(state => ({ ...state, theme }));
    },
    
    // Add notification
    addNotification(notification: Omit<Notification, 'id'>) {
      const id = Math.random().toString(36).substr(2, 9);
      const newNotification = { ...notification, id };
      
      update(state => ({
        ...state,
        notifications: [...state.notifications, newNotification]
      }));
      
      // Auto-remove notification after duration
      if (notification.duration !== 0) {
        setTimeout(() => {
          this.removeNotification(id);
        }, notification.duration || 5000);
      }
      
      return id;
    },
    
    // Remove notification
    removeNotification(id: string) {
      update(state => ({
        ...state,
        notifications: state.notifications.filter(n => n.id !== id)
      }));
    },
    
    // Clear all notifications
    clearNotifications() {
      update(state => ({ ...state, notifications: [] }));
    },
    
    // Set modal state
    setModal(modalId: string, open: boolean) {
      update(state => ({
        ...state,
        modals: { ...state.modals, [modalId]: open }
      }));
    },
    
    // Set loading state
    setLoading(key: string, loading: boolean) {
      update(state => ({
        ...state,
        loading: { ...state.loading, [key]: loading }
      }));
    },
    
    // Set breadcrumbs
    setBreadcrumbs(breadcrumbs: BreadcrumbItem[]) {
      update(state => ({ ...state, breadcrumbs }));
    }
  };
}

export const uiStore = createUIStore();

// Derived stores
export const isDarkMode = derived(uiStore, $ui => {
  if ($ui.theme === 'dark') return true;
  if ($ui.theme === 'light') return false;
  if (browser) {
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  }
  return false;
});

export const sidebarOpen = derived(uiStore, $ui => $ui.sidebarOpen);
export const notifications = derived(uiStore, $ui => $ui.notifications);
```

## React State Management (Zustand)

### Chart Store

```typescript
// src/lib/react/stores/chartStore.ts
import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';
import { persist } from 'zustand/middleware';

interface ChartDataPoint {
  x: string | number;
  y: number;
  label?: string;
}

interface ChartConfig {
  type: 'line' | 'bar' | 'pie' | 'scatter';
  data: ChartDataPoint[];
  options: Record<string, any>;
  title?: string;
  subtitle?: string;
}

interface ChartState {
  charts: Record<string, ChartConfig>;
  selectedChart: string | null;
  selectedDataPoint: {
    chartId: string;
    dataIndex: number;
    value: ChartDataPoint;
  } | null;
  isLoading: Record<string, boolean>;
  errors: Record<string, string>;
  
  // Actions
  setChart: (chartId: string, config: ChartConfig) => void;
  updateChart: (chartId: string, updates: Partial<ChartConfig>) => void;
  removeChart: (chartId: string) => void;
  setSelectedChart: (chartId: string | null) => void;
  setSelectedDataPoint: (selection: ChartState['selectedDataPoint']) => void;
  setLoading: (chartId: string, loading: boolean) => void;
  setError: (chartId: string, error: string) => void;
  clearError: (chartId: string) => void;
}

export const useChartStore = create<ChartState>()(
  subscribeWithSelector(
    persist(
      (set, get) => ({
        charts: {},
        selectedChart: null,
        selectedDataPoint: null,
        isLoading: {},
        errors: {},
        
        setChart: (chartId, config) => set(state => ({
          charts: { ...state.charts, [chartId]: config }
        })),
        
        updateChart: (chartId, updates) => set(state => ({
          charts: {
            ...state.charts,
            [chartId]: { ...state.charts[chartId], ...updates }
          }
        })),
        
        removeChart: (chartId) => set(state => {
          const { [chartId]: removed, ...charts } = state.charts;
          const { [chartId]: removedLoading, ...isLoading } = state.isLoading;
          const { [chartId]: removedError, ...errors } = state.errors;
          
          return {
            charts,
            isLoading,
            errors,
            selectedChart: state.selectedChart === chartId ? null : state.selectedChart
          };
        }),
        
        setSelectedChart: (chartId) => set({ selectedChart: chartId }),
        
        setSelectedDataPoint: (selection) => set({ selectedDataPoint: selection }),
        
        setLoading: (chartId, loading) => set(state => ({
          isLoading: { ...state.isLoading, [chartId]: loading }
        })),
        
        setError: (chartId, error) => set(state => ({
          errors: { ...state.errors, [chartId]: error }
        })),
        
        clearError: (chartId) => set(state => {
          const { [chartId]: removed, ...errors } = state.errors;
          return { errors };
        })
      }),
      {
        name: 'chart-store',
        partialize: (state) => ({ charts: state.charts })
      }
    )
  )
);
```

### Widget Store

```typescript
// src/lib/react/stores/widgetStore.ts
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface WidgetLayout {
  id: string;
  x: number;
  y: number;
  width: number;
  height: number;
}

interface Widget {
  id: string;
  type: string;
  title: string;
  config: Record<string, any>;
  data: any;
  layout: WidgetLayout;
  isLoading: boolean;
  error: string | null;
}

interface WidgetState {
  widgets: Record<string, Widget>;
  layouts: Record<string, WidgetLayout[]>;
  selectedWidget: string | null;
  draggedWidget: string | null;
  
  // Actions
  addWidget: (widget: Omit<Widget, 'isLoading' | 'error'>) => void;
  updateWidget: (id: string, updates: Partial<Widget>) => void;
  removeWidget: (id: string) => void;
  setWidgetData: (id: string, data: any) => void;
  setWidgetLoading: (id: string, loading: boolean) => void;
  setWidgetError: (id: string, error: string | null) => void;
  updateLayout: (layoutId: string, layouts: WidgetLayout[]) => void;
  setSelectedWidget: (id: string | null) => void;
  setDraggedWidget: (id: string | null) => void;
}

export const useWidgetStore = create<WidgetState>()(
  immer((set) => ({
    widgets: {},
    layouts: {},
    selectedWidget: null,
    draggedWidget: null,
    
    addWidget: (widget) => set((state) => {
      state.widgets[widget.id] = {
        ...widget,
        isLoading: false,
        error: null
      };
    }),
    
    updateWidget: (id, updates) => set((state) => {
      if (state.widgets[id]) {
        Object.assign(state.widgets[id], updates);
      }
    }),
    
    removeWidget: (id) => set((state) => {
      delete state.widgets[id];
      if (state.selectedWidget === id) {
        state.selectedWidget = null;
      }
    }),
    
    setWidgetData: (id, data) => set((state) => {
      if (state.widgets[id]) {
        state.widgets[id].data = data;
        state.widgets[id].isLoading = false;
        state.widgets[id].error = null;
      }
    }),
    
    setWidgetLoading: (id, loading) => set((state) => {
      if (state.widgets[id]) {
        state.widgets[id].isLoading = loading;
      }
    }),
    
    setWidgetError: (id, error) => set((state) => {
      if (state.widgets[id]) {
        state.widgets[id].error = error;
        state.widgets[id].isLoading = false;
      }
    }),
    
    updateLayout: (layoutId, layouts) => set((state) => {
      state.layouts[layoutId] = layouts;
      // Update widget layouts
      layouts.forEach(layout => {
        if (state.widgets[layout.id]) {
          state.widgets[layout.id].layout = layout;
        }
      });
    }),
    
    setSelectedWidget: (id) => set((state) => {
      state.selectedWidget = id;
    }),
    
    setDraggedWidget: (id) => set((state) => {
      state.draggedWidget = id;
    })
  }))
);
```

## State Synchronization

### Svelte-React Bridge

```typescript
// src/lib/stores/bridge.ts
import { writable, get } from 'svelte/store';
import { useChartStore } from '$lib/react/stores/chartStore';
import { useWidgetStore } from '$lib/react/stores/widgetStore';

class StateBridge {
  private chartStore = useChartStore;
  private widgetStore = useWidgetStore;
  
  // Svelte stores that mirror React state
  public chartData = writable({});
  public widgetData = writable({});
  
  constructor() {
    this.setupBridge();
  }
  
  private setupBridge() {
    // Subscribe to React store changes
    this.chartStore.subscribe(
      (state) => state.charts,
      (charts) => {
        this.chartData.set(charts);
      }
    );
    
    this.widgetStore.subscribe(
      (state) => state.widgets,
      (widgets) => {
        this.widgetData.set(widgets);
      }
    );
  }
  
  // Methods to update React state from Svelte
  updateChart(chartId: string, config: any) {
    this.chartStore.getState().setChart(chartId, config);
  }
  
  updateWidget(widgetId: string, updates: any) {
    this.widgetStore.getState().updateWidget(widgetId, updates);
  }
  
  // Get current React state
  getChartState() {
    return this.chartStore.getState();
  }
  
  getWidgetState() {
    return this.widgetStore.getState();
  }
}

export const stateBridge = new StateBridge();
```

## Persistence Strategies

### Local Storage Persistence

```typescript
// src/lib/utils/persistence.ts
import { writable, type Writable } from 'svelte/store';
import { browser } from '$app/environment';

export function persistentStore<T>(
  key: string,
  initialValue: T,
  options: {
    serializer?: {
      parse: (text: string) => T;
      stringify: (object: T) => string;
    };
    syncAcrossTabs?: boolean;
  } = {}
): Writable<T> {
  const {
    serializer = JSON,
    syncAcrossTabs = true
  } = options;
  
  const store = writable(initialValue);
  
  if (!browser) return store;
  
  // Load initial value from localStorage
  try {
    const stored = localStorage.getItem(key);
    if (stored) {
      store.set(serializer.parse(stored));
    }
  } catch (error) {
    console.warn(`Failed to load persisted store "${key}":`, error);
  }
  
  // Subscribe to store changes and persist
  store.subscribe(value => {
    try {
      localStorage.setItem(key, serializer.stringify(value));
    } catch (error) {
      console.warn(`Failed to persist store "${key}":`, error);
    }
  });
  
  // Sync across tabs
  if (syncAcrossTabs) {
    window.addEventListener('storage', (event) => {
      if (event.key === key && event.newValue) {
        try {
          store.set(serializer.parse(event.newValue));
        } catch (error) {
          console.warn(`Failed to sync store "${key}" across tabs:`, error);
        }
      }
    });
  }
  
  return store;
}

// Usage example
export const userPreferences = persistentStore('user-preferences', {
  theme: 'system',
  sidebarOpen: true,
  language: 'en'
});
```

This state management documentation provides a comprehensive guide for managing application state across the hybrid SvelteKit-React architecture, ensuring consistency, performance, and maintainability.
