# React Integration Documentation

## Overview

GitInsight strategically integrates React components within the SvelteKit framework for specific use cases where React's ecosystem provides superior solutions, particularly for complex data visualizations, third-party integrations, and advanced interactive widgets. This document covers the implementation patterns, state management, and best practices for seamless React-Svelte interoperability.

## Integration Strategy

### When to Use React Components

React components are used selectively in GitInsight for:

- **Complex Data Visualizations**: Chart.js, D3.js, and other visualization libraries with React wrappers
- **Third-party Integrations**: Monaco Editor, GitHub integrations, and external widgets
- **Advanced Interactive Components**: Complex forms, drag-and-drop interfaces, and rich text editors
- **Existing React Libraries**: When no suitable Svelte alternative exists

### Integration Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    SvelteKit Application                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                  Svelte Components                          │  │
│  │                                                             │  │
│  │  ┌─────────────────┐              ┌─────────────────┐      │  │
│  │  │   Page Layout   │              │   UI Components │      │  │
│  │  │   Components    │              │   (Shadcn UI)   │      │  │
│  │  └─────────────────┘              └─────────────────┘      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                React Integration Layer                      │  │
│  │                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │   React Wrapper │  │   State Bridge  │  │   Event     │  │  │
│  │  │   Components    │  │   (Zustand)     │  │   Handlers  │  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                  React Components                           │  │
│  │                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │   Chart         │  │   Monaco        │  │   Complex   │  │  │
│  │  │   Components    │  │   Editor        │  │   Widgets   │  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## React Component Integration

### React Wrapper Component

```svelte
<!-- src/lib/components/ReactWrapper.svelte -->
<script lang="ts">
  import { onMount, onDestroy, createEventDispatcher } from 'svelte';
  import { createElement } from 'react';
  import { createRoot, type Root } from 'react-dom/client';
  import type { ComponentType } from 'react';
  
  export let component: ComponentType<any>;
  export let props: Record<string, any> = {};
  export let className: string = '';
  
  const dispatch = createEventDispatcher();
  
  let container: HTMLDivElement;
  let root: Root;
  
  onMount(() => {
    root = createRoot(container);
    renderComponent();
  });
  
  onDestroy(() => {
    if (root) {
      root.unmount();
    }
  });
  
  function renderComponent() {
    if (!root || !component) return;
    
    const reactElement = createElement(component, {
      ...props,
      // Bridge Svelte events to React
      onEvent: (eventName: string, data: any) => {
        dispatch(eventName, data);
      }
    });
    
    root.render(reactElement);
  }
  
  // Re-render when props change
  $: if (root && component) {
    renderComponent();
  }
</script>

<div bind:this={container} class={className}></div>
```

### Chart Component Integration

#### React Chart Component

```tsx
// src/lib/react/charts/LineChart.tsx
import React, { useEffect, useRef } from 'react';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  ChartOptions,
  ChartData
} from 'chart.js';
import { Line } from 'react-chartjs-2';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

interface LineChartProps {
  data: ChartData<'line'>;
  options?: ChartOptions<'line'>;
  height?: number;
  onDataPointClick?: (dataIndex: number, datasetIndex: number) => void;
  onEvent?: (eventName: string, data: any) => void;
}

export default function LineChart({ 
  data, 
  options = {}, 
  height = 400,
  onDataPointClick,
  onEvent 
}: LineChartProps) {
  const chartRef = useRef<ChartJS<'line'>>(null);
  
  const defaultOptions: ChartOptions<'line'> = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Repository Metrics Over Time',
      },
    },
    scales: {
      y: {
        beginAtZero: true,
      },
    },
    onClick: (event, elements) => {
      if (elements.length > 0 && onDataPointClick) {
        const element = elements[0];
        onDataPointClick(element.index, element.datasetIndex);
        onEvent?.('dataPointClick', {
          dataIndex: element.index,
          datasetIndex: element.datasetIndex,
          value: data.datasets[element.datasetIndex].data[element.index]
        });
      }
    },
  };
  
  const mergedOptions = { ...defaultOptions, ...options };
  
  useEffect(() => {
    // Notify parent component when chart is ready
    onEvent?.('chartReady', { chartRef: chartRef.current });
  }, [onEvent]);
  
  return (
    <div style={{ height: `${height}px` }}>
      <Line 
        ref={chartRef}
        data={data} 
        options={mergedOptions} 
      />
    </div>
  );
}
```

#### Svelte Chart Wrapper

```svelte
<!-- src/lib/components/charts/LineChart.svelte -->
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import ReactWrapper from '../ReactWrapper.svelte';
  import type { ChartData, ChartOptions } from 'chart.js';
  
  export let data: ChartData<'line'>;
  export let options: ChartOptions<'line'> = {};
  export let height: number = 400;
  export let loading: boolean = false;
  
  const dispatch = createEventDispatcher();
  
  let LineChartComponent: any;
  
  // Lazy load React component
  import('$lib/react/charts/LineChart').then(module => {
    LineChartComponent = module.default;
  });
  
  function handleChartEvent(event: CustomEvent) {
    const { eventName, data } = event.detail;
    dispatch(eventName, data);
  }
  
  function handleDataPointClick(event: CustomEvent) {
    const { dataIndex, datasetIndex, value } = event.detail;
    dispatch('dataPointClick', { dataIndex, datasetIndex, value });
  }
</script>

<div class="chart-container">
  {#if loading}
    <div class="chart-skeleton" style="height: {height}px;">
      <div class="skeleton-content">
        <div class="skeleton-line"></div>
        <div class="skeleton-line"></div>
        <div class="skeleton-line"></div>
      </div>
    </div>
  {:else if LineChartComponent}
    <ReactWrapper
      component={LineChartComponent}
      props={{ data, options, height }}
      on:chartReady={handleChartEvent}
      on:dataPointClick={handleDataPointClick}
    />
  {:else}
    <div class="chart-loading" style="height: {height}px;">
      Loading chart...
    </div>
  {/if}
</div>

<style>
  .chart-container {
    width: 100%;
    position: relative;
  }
  
  .chart-skeleton {
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--muted);
    border-radius: 8px;
  }
  
  .skeleton-content {
    width: 80%;
    height: 60%;
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }
  
  .skeleton-line {
    height: 2px;
    background: var(--muted-foreground);
    border-radius: 1px;
    opacity: 0.3;
    animation: pulse 2s infinite;
  }
  
  .chart-loading {
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--muted);
    border-radius: 8px;
    color: var(--muted-foreground);
  }
  
  @keyframes pulse {
    0%, 100% { opacity: 0.3; }
    50% { opacity: 0.7; }
  }
</style>
```

## State Management Bridge

### Zustand Store for React Components

```typescript
// src/lib/react/stores/chartStore.ts
import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';

interface ChartState {
  selectedDataPoint: {
    chartId: string;
    dataIndex: number;
    datasetIndex: number;
    value: any;
  } | null;
  chartConfigs: Record<string, any>;
  isLoading: boolean;
  
  // Actions
  setSelectedDataPoint: (selection: ChartState['selectedDataPoint']) => void;
  setChartConfig: (chartId: string, config: any) => void;
  setLoading: (loading: boolean) => void;
  clearSelection: () => void;
}

export const useChartStore = create<ChartState>()(
  subscribeWithSelector((set, get) => ({
    selectedDataPoint: null,
    chartConfigs: {},
    isLoading: false,
    
    setSelectedDataPoint: (selection) => set({ selectedDataPoint: selection }),
    
    setChartConfig: (chartId, config) => set((state) => ({
      chartConfigs: { ...state.chartConfigs, [chartId]: config }
    })),
    
    setLoading: (loading) => set({ isLoading: loading }),
    
    clearSelection: () => set({ selectedDataPoint: null })
  }))
);
```

### Svelte-React State Bridge

```typescript
// src/lib/stores/reactBridge.ts
import { writable, derived } from 'svelte/store';
import { useChartStore } from '$lib/react/stores/chartStore';

// Create a bridge between Svelte stores and Zustand
class ReactStateBridge {
  private chartStore = useChartStore;
  
  // Svelte store that mirrors React state
  public selectedDataPoint = writable(null);
  public chartConfigs = writable({});
  public isLoading = writable(false);
  
  constructor() {
    this.setupBridge();
  }
  
  private setupBridge() {
    // Subscribe to Zustand store changes and update Svelte stores
    this.chartStore.subscribe(
      (state) => state.selectedDataPoint,
      (selectedDataPoint) => {
        this.selectedDataPoint.set(selectedDataPoint);
      }
    );
    
    this.chartStore.subscribe(
      (state) => state.chartConfigs,
      (chartConfigs) => {
        this.chartConfigs.set(chartConfigs);
      }
    );
    
    this.chartStore.subscribe(
      (state) => state.isLoading,
      (isLoading) => {
        this.isLoading.set(isLoading);
      }
    );
  }
  
  // Methods to update React state from Svelte
  setSelectedDataPoint(selection: any) {
    this.chartStore.getState().setSelectedDataPoint(selection);
  }
  
  setChartConfig(chartId: string, config: any) {
    this.chartStore.getState().setChartConfig(chartId, config);
  }
  
  setLoading(loading: boolean) {
    this.chartStore.getState().setLoading(loading);
  }
}

export const reactBridge = new ReactStateBridge();
```

## Advanced Integration Patterns

### Monaco Editor Integration

```tsx
// src/lib/react/editors/MonacoEditor.tsx
import React, { useRef, useEffect } from 'react';
import * as monaco from 'monaco-editor';

interface MonacoEditorProps {
  value: string;
  language: string;
  theme?: string;
  height?: number;
  readOnly?: boolean;
  onChange?: (value: string) => void;
  onEvent?: (eventName: string, data: any) => void;
}

export default function MonacoEditor({
  value,
  language,
  theme = 'vs-dark',
  height = 400,
  readOnly = false,
  onChange,
  onEvent
}: MonacoEditorProps) {
  const editorRef = useRef<HTMLDivElement>(null);
  const monacoRef = useRef<monaco.editor.IStandaloneCodeEditor | null>(null);
  
  useEffect(() => {
    if (editorRef.current) {
      monacoRef.current = monaco.editor.create(editorRef.current, {
        value,
        language,
        theme,
        readOnly,
        automaticLayout: true,
        minimap: { enabled: false },
        scrollBeyondLastLine: false,
        fontSize: 14,
        lineNumbers: 'on',
        roundedSelection: false,
        scrollbar: {
          vertical: 'visible',
          horizontal: 'visible'
        }
      });
      
      // Setup change listener
      const disposable = monacoRef.current.onDidChangeModelContent(() => {
        const currentValue = monacoRef.current?.getValue() || '';
        onChange?.(currentValue);
        onEvent?.('change', { value: currentValue });
      });
      
      onEvent?.('editorReady', { editor: monacoRef.current });
      
      return () => {
        disposable.dispose();
        monacoRef.current?.dispose();
      };
    }
  }, []);
  
  // Update value when prop changes
  useEffect(() => {
    if (monacoRef.current && monacoRef.current.getValue() !== value) {
      monacoRef.current.setValue(value);
    }
  }, [value]);
  
  // Update language when prop changes
  useEffect(() => {
    if (monacoRef.current) {
      const model = monacoRef.current.getModel();
      if (model) {
        monaco.editor.setModelLanguage(model, language);
      }
    }
  }, [language]);
  
  return <div ref={editorRef} style={{ height: `${height}px` }} />;
}
```

### Complex Widget Integration

```tsx
// src/lib/react/widgets/RepositoryAnalysisWidget.tsx
import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';

interface AnalysisData {
  codeQuality: {
    score: number;
    issues: Array<{ type: string; count: number; severity: string }>;
  };
  security: {
    vulnerabilities: number;
    riskLevel: string;
  };
  performance: {
    score: number;
    metrics: Record<string, number>;
  };
}

interface RepositoryAnalysisWidgetProps {
  repositoryId: string;
  data: AnalysisData;
  onTabChange?: (tab: string) => void;
  onEvent?: (eventName: string, data: any) => void;
}

export default function RepositoryAnalysisWidget({
  repositoryId,
  data,
  onTabChange,
  onEvent
}: RepositoryAnalysisWidgetProps) {
  const [activeTab, setActiveTab] = useState('overview');
  
  useEffect(() => {
    onEvent?.('widgetMounted', { repositoryId });
  }, [repositoryId, onEvent]);
  
  const handleTabChange = (tab: string) => {
    setActiveTab(tab);
    onTabChange?.(tab);
    onEvent?.('tabChanged', { tab, repositoryId });
  };
  
  const getRiskColor = (riskLevel: string) => {
    switch (riskLevel.toLowerCase()) {
      case 'low': return 'bg-green-500';
      case 'medium': return 'bg-yellow-500';
      case 'high': return 'bg-red-500';
      default: return 'bg-gray-500';
    }
  };
  
  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>Repository Analysis</CardTitle>
      </CardHeader>
      <CardContent>
        <Tabs value={activeTab} onValueChange={handleTabChange}>
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="overview">Overview</TabsTrigger>
            <TabsTrigger value="security">Security</TabsTrigger>
            <TabsTrigger value="performance">Performance</TabsTrigger>
          </TabsList>
          
          <TabsContent value="overview" className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="space-y-2">
                <h4 className="text-sm font-medium">Code Quality</h4>
                <Progress value={data.codeQuality.score} className="h-2" />
                <p className="text-xs text-muted-foreground">
                  {data.codeQuality.score}% overall score
                </p>
              </div>
              
              <div className="space-y-2">
                <h4 className="text-sm font-medium">Security Risk</h4>
                <Badge className={getRiskColor(data.security.riskLevel)}>
                  {data.security.riskLevel}
                </Badge>
                <p className="text-xs text-muted-foreground">
                  {data.security.vulnerabilities} vulnerabilities found
                </p>
              </div>
              
              <div className="space-y-2">
                <h4 className="text-sm font-medium">Performance</h4>
                <Progress value={data.performance.score} className="h-2" />
                <p className="text-xs text-muted-foreground">
                  {data.performance.score}% performance score
                </p>
              </div>
            </div>
          </TabsContent>
          
          <TabsContent value="security" className="space-y-4">
            <div className="space-y-2">
              <h4 className="text-sm font-medium">Security Vulnerabilities</h4>
              <div className="space-y-2">
                {data.security.vulnerabilities > 0 ? (
                  <p className="text-sm text-red-600">
                    {data.security.vulnerabilities} vulnerabilities detected
                  </p>
                ) : (
                  <p className="text-sm text-green-600">
                    No vulnerabilities detected
                  </p>
                )}
              </div>
            </div>
          </TabsContent>
          
          <TabsContent value="performance" className="space-y-4">
            <div className="space-y-2">
              <h4 className="text-sm font-medium">Performance Metrics</h4>
              <div className="grid grid-cols-2 gap-4">
                {Object.entries(data.performance.metrics).map(([key, value]) => (
                  <div key={key} className="space-y-1">
                    <p className="text-xs font-medium capitalize">
                      {key.replace(/([A-Z])/g, ' $1').trim()}
                    </p>
                    <p className="text-sm">{value}</p>
                  </div>
                ))}
              </div>
            </div>
          </TabsContent>
        </Tabs>
      </CardContent>
    </Card>
  );
}
```

## Performance Optimization

### Code Splitting for React Components

```typescript
// src/lib/utils/reactLoader.ts
import { writable } from 'svelte/store';

interface ComponentCache {
  [key: string]: {
    component: any;
    loading: boolean;
    error: Error | null;
  };
}

class ReactComponentLoader {
  private cache: ComponentCache = {};
  private loadingStore = writable<Record<string, boolean>>({});
  
  async loadComponent(importPath: string, componentName: string = 'default') {
    const cacheKey = `${importPath}#${componentName}`;
    
    if (this.cache[cacheKey]?.component) {
      return this.cache[cacheKey].component;
    }
    
    if (this.cache[cacheKey]?.loading) {
      // Wait for existing load to complete
      return new Promise((resolve, reject) => {
        const checkInterval = setInterval(() => {
          const cached = this.cache[cacheKey];
          if (!cached.loading) {
            clearInterval(checkInterval);
            if (cached.error) {
              reject(cached.error);
            } else {
              resolve(cached.component);
            }
          }
        }, 50);
      });
    }
    
    // Start loading
    this.cache[cacheKey] = { component: null, loading: true, error: null };
    this.updateLoadingStore();
    
    try {
      const module = await import(/* @vite-ignore */ importPath);
      const component = module[componentName];
      
      this.cache[cacheKey] = { component, loading: false, error: null };
      this.updateLoadingStore();
      
      return component;
    } catch (error) {
      this.cache[cacheKey] = { component: null, loading: false, error: error as Error };
      this.updateLoadingStore();
      throw error;
    }
  }
  
  private updateLoadingStore() {
    const loading: Record<string, boolean> = {};
    Object.entries(this.cache).forEach(([key, value]) => {
      loading[key] = value.loading;
    });
    this.loadingStore.set(loading);
  }
  
  getLoadingStore() {
    return this.loadingStore;
  }
}

export const reactLoader = new ReactComponentLoader();
```

### Optimized React Wrapper with Error Boundaries

```svelte
<!-- src/lib/components/OptimizedReactWrapper.svelte -->
<script lang="ts">
  import { onMount, onDestroy, createEventDispatcher } from 'svelte';
  import { createElement } from 'react';
  import { createRoot, type Root } from 'react-dom/client';
  import { reactLoader } from '$lib/utils/reactLoader';
  import type { ComponentType } from 'react';
  
  export let importPath: string;
  export let componentName: string = 'default';
  export let props: Record<string, any> = {};
  export let className: string = '';
  export let fallback: string = 'Loading...';
  
  const dispatch = createEventDispatcher();
  
  let container: HTMLDivElement;
  let root: Root;
  let component: ComponentType<any> | null = null;
  let loading = true;
  let error: Error | null = null;
  
  onMount(async () => {
    try {
      component = await reactLoader.loadComponent(importPath, componentName);
      loading = false;
      
      if (container) {
        root = createRoot(container);
        renderComponent();
      }
    } catch (err) {
      error = err as Error;
      loading = false;
      dispatch('error', { error: err });
    }
  });
  
  onDestroy(() => {
    if (root) {
      root.unmount();
    }
  });
  
  function renderComponent() {
    if (!root || !component) return;
    
    const reactElement = createElement(component, {
      ...props,
      onEvent: (eventName: string, data: any) => {
        dispatch(eventName, data);
      }
    });
    
    root.render(reactElement);
  }
  
  $: if (root && component && !loading) {
    renderComponent();
  }
</script>

<div bind:this={container} class={className}>
  {#if loading}
    <div class="react-loading">
      {fallback}
    </div>
  {:else if error}
    <div class="react-error">
      <p>Failed to load component</p>
      <details>
        <summary>Error details</summary>
        <pre>{error.message}</pre>
      </details>
    </div>
  {/if}
</div>

<style>
  .react-loading {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 2rem;
    color: var(--muted-foreground);
  }
  
  .react-error {
    padding: 1rem;
    border: 1px solid var(--destructive);
    border-radius: 0.5rem;
    background: var(--destructive-foreground);
    color: var(--destructive);
  }
  
  .react-error details {
    margin-top: 0.5rem;
  }
  
  .react-error pre {
    font-size: 0.75rem;
    margin-top: 0.25rem;
    white-space: pre-wrap;
  }
</style>
```

This React integration documentation provides comprehensive patterns for seamlessly incorporating React components into the SvelteKit application while maintaining performance, type safety, and proper state management.
