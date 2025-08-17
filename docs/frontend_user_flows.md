# User Flows and Navigation Documentation

## Overview

This document describes the complete user journey through the GitInsight frontend application, including navigation patterns, user flow implementations, and the frontend architecture that supports seamless user experiences. It covers authentication flows, repository management, analysis workflows, and dashboard interactions.

## User Journey Overview

### Primary User Flows

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitInsight User Journey                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   Landing Page  │───►│  Authentication │───►│  Dashboard  │  │
│  │                 │    │                 │    │             │  │
│  │ • Value Prop    │    │ • GitHub OAuth  │    │ • Overview  │  │
│  │ • Features      │    │ • User Onboard  │    │ • Quick     │  │
│  │ • Call to Action│    │ • Profile Setup │    │   Actions   │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                       │                       │     │
│           ▼                       ▼                       ▼     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   Repository    │    │    Analysis     │    │   Insights  │  │
│  │   Management    │    │    Workflow     │    │   & Reports │  │
│  │                 │    │                 │    │             │  │
│  │ • Add Repos     │    │ • Trigger       │    │ • View      │  │
│  │ • Browse        │    │ • Monitor       │    │ • Export    │  │
│  │ • Search        │    │ • Configure     │    │ • Share     │  │
│  │ • Organize      │    │ • Results       │    │ • Compare   │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Authentication Flow

### GitHub OAuth Integration

```svelte
<!-- src/routes/auth/login/+page.svelte -->
<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { authStore } from '$stores/auth';
  import { Button } from '$components/ui/button';
  import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '$components/ui/card';
  import { Alert, AlertDescription } from '$components/ui/alert';
  import { Github, ArrowRight, Shield, Zap, BarChart } from 'lucide-svelte';
  
  let loading = false;
  let error = '';
  
  $: redirectTo = $page.url.searchParams.get('redirect') || '/dashboard';
  
  async function handleGitHubLogin() {
    loading = true;
    error = '';
    
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
      });
      
      const data = await response.json();
      
      if (data.authorization_url) {
        window.location.href = data.authorization_url;
      } else {
        throw new Error('Failed to initiate authentication');
      }
    } catch (err) {
      error = err.message;
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>Sign In - GitInsight</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-background to-muted p-4">
  <div class="w-full max-w-md space-y-6">
    <!-- Logo and branding -->
    <div class="text-center">
      <div class="mx-auto h-12 w-12 rounded-lg bg-primary flex items-center justify-center mb-4">
        <BarChart class="h-6 w-6 text-primary-foreground" />
      </div>
      <h1 class="text-2xl font-bold">Welcome to GitInsight</h1>
      <p class="text-muted-foreground">
        Discover, evaluate, and engage with open-source projects using AI-driven insights
      </p>
    </div>
    
    <!-- Login card -->
    <Card>
      <CardHeader>
        <CardTitle>Sign in to your account</CardTitle>
        <CardDescription>
          Connect with GitHub to start analyzing repositories
        </CardDescription>
      </CardHeader>
      <CardContent class="space-y-4">
        {#if error}
          <Alert variant="destructive">
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        {/if}
        
        <Button
          class="w-full"
          size="lg"
          on:click={handleGitHubLogin}
          disabled={loading}
        >
          {#if loading}
            <div class="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
          {:else}
            <Github class="mr-2 h-4 w-4" />
          {/if}
          Continue with GitHub
          <ArrowRight class="ml-2 h-4 w-4" />
        </Button>
        
        <div class="text-xs text-center text-muted-foreground">
          By signing in, you agree to our Terms of Service and Privacy Policy
        </div>
      </CardContent>
    </Card>
    
    <!-- Features preview -->
    <div class="grid grid-cols-1 gap-4 text-center">
      <div class="flex items-center justify-center space-x-2 text-sm text-muted-foreground">
        <Shield class="h-4 w-4" />
        <span>Secure GitHub integration</span>
      </div>
      <div class="flex items-center justify-center space-x-2 text-sm text-muted-foreground">
        <Zap class="h-4 w-4" />
        <span>AI-powered analysis</span>
      </div>
      <div class="flex items-center justify-center space-x-2 text-sm text-muted-foreground">
        <BarChart class="h-4 w-4" />
        <span>Comprehensive insights</span>
      </div>
    </div>
  </div>
</div>
```

### OAuth Callback Handler

```typescript
// src/routes/auth/callback/+page.server.ts
import type { PageServerLoad } from './$types';
import { redirect, error } from '@sveltejs/kit';
import { authService } from '$lib/server/auth';

export const load: PageServerLoad = async ({ url, cookies }) => {
  const code = url.searchParams.get('code');
  const state = url.searchParams.get('state');
  const errorParam = url.searchParams.get('error');
  
  if (errorParam) {
    throw error(400, `Authentication failed: ${errorParam}`);
  }
  
  if (!code || !state) {
    throw error(400, 'Missing authentication parameters');
  }
  
  try {
    // Exchange code for tokens and user info
    const { user, tokens } = await authService.handleOAuthCallback(code, state);
    
    // Set authentication cookies
    cookies.set('auth-token', tokens.access_token, {
      path: '/',
      httpOnly: true,
      secure: true,
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 7 // 7 days
    });
    
    // Redirect to dashboard or intended destination
    const redirectTo = url.searchParams.get('redirect') || '/dashboard';
    throw redirect(302, redirectTo);
    
  } catch (err) {
    console.error('OAuth callback error:', err);
    throw error(500, 'Authentication failed');
  }
};
```

## Dashboard Flow

### Dashboard Layout and Components

```svelte
<!-- src/routes/dashboard/+page.svelte -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { repositoryStore, authStore } from '$stores';
  import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '$components/ui/card';
  import { Button } from '$components/ui/button';
  import { Badge } from '$components/ui/badge';
  import { Progress } from '$components/ui/progress';
  import RepositoryCard from '$components/repository/RepositoryCard.svelte';
  import MetricsCard from '$components/dashboard/MetricsCard.svelte';
  import RecentActivity from '$components/dashboard/RecentActivity.svelte';
  import QuickActions from '$components/dashboard/QuickActions.svelte';
  import { Plus, TrendingUp, Clock, Star, GitFork } from 'lucide-svelte';
  
  export let data;
  
  $: user = $authStore.user;
  $: repositories = data.repositories;
  $: stats = data.stats;
  $: recentActivity = data.recentActivity;
  
  onMount(() => {
    // Initialize dashboard data
    repositoryStore.loadRepositories({ limit: 6, sort: 'updated' });
  });
</script>

<svelte:head>
  <title>Dashboard - GitInsight</title>
</svelte:head>

<div class="space-y-6">
  <!-- Welcome header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold">Welcome back, {user?.name || user?.username}!</h1>
      <p class="text-muted-foreground">
        Here's what's happening with your repositories
      </p>
    </div>
    <Button href="/repositories/add">
      <Plus class="mr-2 h-4 w-4" />
      Add Repository
    </Button>
  </div>
  
  <!-- Metrics overview -->
  <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
    <MetricsCard
      title="Total Repositories"
      value={stats.totalRepositories}
      icon={GitFork}
      trend={stats.repositoryGrowth}
    />
    <MetricsCard
      title="Analyses Completed"
      value={stats.analysesCompleted}
      icon={TrendingUp}
      trend={stats.analysisGrowth}
    />
    <MetricsCard
      title="Average Quality Score"
      value="{stats.averageQuality}%"
      icon={Star}
      trend={stats.qualityTrend}
    />
    <MetricsCard
      title="Active This Week"
      value={stats.activeThisWeek}
      icon={Clock}
      trend={stats.activityTrend}
    />
  </div>
  
  <!-- Main content grid -->
  <div class="grid gap-6 lg:grid-cols-3">
    <!-- Recent repositories -->
    <div class="lg:col-span-2 space-y-4">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-semibold">Recent Repositories</h2>
        <Button variant="outline" size="sm" href="/repositories">
          View All
        </Button>
      </div>
      
      <div class="grid gap-4 md:grid-cols-2">
        {#each repositories as repository}
          <RepositoryCard {repository} compact />
        {/each}
      </div>
      
      {#if repositories.length === 0}
        <Card>
          <CardContent class="flex flex-col items-center justify-center py-12">
            <GitFork class="h-12 w-12 text-muted-foreground mb-4" />
            <h3 class="text-lg font-medium mb-2">No repositories yet</h3>
            <p class="text-muted-foreground text-center mb-4">
              Add your first repository to start analyzing code quality and getting insights
            </p>
            <Button href="/repositories/add">
              <Plus class="mr-2 h-4 w-4" />
              Add Repository
            </Button>
          </CardContent>
        </Card>
      {/if}
    </div>
    
    <!-- Sidebar -->
    <div class="space-y-6">
      <!-- Quick actions -->
      <QuickActions />
      
      <!-- Recent activity -->
      <RecentActivity activities={recentActivity} />
      
      <!-- Analysis progress -->
      <Card>
        <CardHeader>
          <CardTitle class="text-lg">Analysis Progress</CardTitle>
          <CardDescription>
            Current analysis jobs
          </CardDescription>
        </CardHeader>
        <CardContent class="space-y-4">
          {#each stats.activeAnalyses as analysis}
            <div class="space-y-2">
              <div class="flex items-center justify-between text-sm">
                <span class="truncate">{analysis.repositoryName}</span>
                <span class="text-muted-foreground">{analysis.progress}%</span>
              </div>
              <Progress value={analysis.progress} class="h-2" />
            </div>
          {/each}
          
          {#if stats.activeAnalyses.length === 0}
            <p class="text-sm text-muted-foreground text-center py-4">
              No active analyses
            </p>
          {/if}
        </CardContent>
      </Card>
    </div>
  </div>
</div>
```

## Repository Management Flow

### Repository List and Search

```svelte
<!-- src/routes/repositories/+page.svelte -->
<script lang="ts">
  import { page } from '$app/stores';
  import { goto } from '$app/navigation';
  import { repositoryStore } from '$stores';
  import { Button } from '$components/ui/button';
  import { Input } from '$components/ui/input';
  import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '$components/ui/select';
  import { Badge } from '$components/ui/badge';
  import RepositoryCard from '$components/repository/RepositoryCard.svelte';
  import DataTable from '$components/ui/DataTable.svelte';
  import LoadingStates from '$components/ui/LoadingStates.svelte';
  import { Search, Plus, Filter, Grid, List } from 'lucide-svelte';
  
  export let data;
  
  let viewMode: 'grid' | 'list' = 'grid';
  let searchQuery = '';
  let sortBy = 'updated';
  let filterBy = 'all';
  let languageFilter = '';
  
  $: repositories = data.repositories;
  $: pagination = data.pagination;
  $: loading = $repositoryStore.isLoading;
  
  // Update URL params when filters change
  $: {
    const params = new URLSearchParams();
    if (searchQuery) params.set('search', searchQuery);
    if (sortBy !== 'updated') params.set('sort', sortBy);
    if (filterBy !== 'all') params.set('filter', filterBy);
    if (languageFilter) params.set('language', languageFilter);
    
    const newUrl = `/repositories?${params.toString()}`;
    if (newUrl !== $page.url.pathname + $page.url.search) {
      goto(newUrl, { replaceState: true, noScroll: true });
    }
  }
  
  const tableColumns = [
    { key: 'name', title: 'Repository', sortable: true },
    { key: 'language', title: 'Language', sortable: true },
    { key: 'stars', title: 'Stars', sortable: true, align: 'right' },
    { key: 'forks', title: 'Forks', sortable: true, align: 'right' },
    { key: 'updated_at', title: 'Updated', sortable: true },
    { key: 'analysis_status', title: 'Status', sortable: false }
  ];
  
  function handleSearch() {
    repositoryStore.setSearchQuery(searchQuery);
    repositoryStore.loadRepositories();
  }
  
  function handleSort(event) {
    const { column, direction } = event.detail;
    repositoryStore.setFilters({ sort: `${column}:${direction}` });
    repositoryStore.loadRepositories();
  }
</script>

<svelte:head>
  <title>Repositories - GitInsight</title>
</svelte:head>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold">Repositories</h1>
      <p class="text-muted-foreground">
        Manage and analyze your GitHub repositories
      </p>
    </div>
    <Button href="/repositories/add">
      <Plus class="mr-2 h-4 w-4" />
      Add Repository
    </Button>
  </div>
  
  <!-- Filters and search -->
  <div class="flex flex-col sm:flex-row gap-4">
    <!-- Search -->
    <div class="relative flex-1">
      <Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
      <Input
        placeholder="Search repositories..."
        bind:value={searchQuery}
        on:input={handleSearch}
        class="pl-10"
      />
    </div>
    
    <!-- Filters -->
    <div class="flex gap-2">
      <Select bind:value={sortBy}>
        <SelectTrigger class="w-40">
          <SelectValue placeholder="Sort by" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="updated">Recently Updated</SelectItem>
          <SelectItem value="created">Recently Added</SelectItem>
          <SelectItem value="name">Name</SelectItem>
          <SelectItem value="stars">Stars</SelectItem>
          <SelectItem value="quality">Quality Score</SelectItem>
        </SelectContent>
      </Select>
      
      <Select bind:value={filterBy}>
        <SelectTrigger class="w-32">
          <SelectValue placeholder="Filter" />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="all">All</SelectItem>
          <SelectItem value="analyzed">Analyzed</SelectItem>
          <SelectItem value="pending">Pending</SelectItem>
          <SelectItem value="starred">Starred</SelectItem>
        </SelectContent>
      </Select>
      
      <!-- View mode toggle -->
      <div class="flex rounded-md border">
        <Button
          variant={viewMode === 'grid' ? 'default' : 'ghost'}
          size="sm"
          class="rounded-r-none"
          on:click={() => viewMode = 'grid'}
        >
          <Grid class="h-4 w-4" />
        </Button>
        <Button
          variant={viewMode === 'list' ? 'default' : 'ghost'}
          size="sm"
          class="rounded-l-none"
          on:click={() => viewMode = 'list'}
        >
          <List class="h-4 w-4" />
        </Button>
      </div>
    </div>
  </div>
  
  <!-- Active filters -->
  {#if searchQuery || filterBy !== 'all' || languageFilter}
    <div class="flex items-center gap-2">
      <span class="text-sm text-muted-foreground">Active filters:</span>
      {#if searchQuery}
        <Badge variant="secondary">Search: {searchQuery}</Badge>
      {/if}
      {#if filterBy !== 'all'}
        <Badge variant="secondary">Filter: {filterBy}</Badge>
      {/if}
      {#if languageFilter}
        <Badge variant="secondary">Language: {languageFilter}</Badge>
      {/if}
      <Button
        variant="ghost"
        size="sm"
        on:click={() => {
          searchQuery = '';
          filterBy = 'all';
          languageFilter = '';
          handleSearch();
        }}
      >
        Clear all
      </Button>
    </div>
  {/if}
  
  <!-- Content -->
  {#if loading}
    <LoadingStates type="skeleton" />
  {:else if repositories.length === 0}
    <div class="text-center py-12">
      <div class="mx-auto h-12 w-12 rounded-full bg-muted flex items-center justify-center mb-4">
        <Search class="h-6 w-6 text-muted-foreground" />
      </div>
      <h3 class="text-lg font-medium mb-2">No repositories found</h3>
      <p class="text-muted-foreground mb-4">
        {searchQuery ? 'Try adjusting your search terms' : 'Add your first repository to get started'}
      </p>
      <Button href="/repositories/add">
        <Plus class="mr-2 h-4 w-4" />
        Add Repository
      </Button>
    </div>
  {:else if viewMode === 'grid'}
    <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      {#each repositories as repository}
        <RepositoryCard {repository} />
      {/each}
    </div>
  {:else}
    <DataTable
      data={repositories}
      columns={tableColumns}
      {pagination}
      on:sort={handleSort}
    />
  {/if}
</div>
```

## Analysis Workflow

### Repository Analysis Flow

```svelte
<!-- src/routes/repositories/[id]/analysis/+page.svelte -->
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/stores';
  import { Button } from '$components/ui/button';
  import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '$components/ui/card';
  import { Progress } from '$components/ui/progress';
  import { Badge } from '$components/ui/badge';
  import { Alert, AlertDescription } from '$components/ui/alert';
  import { Tabs, TabsContent, TabsList, TabsTrigger } from '$components/ui/tabs';
  import { Play, Square, RefreshCw, Download, Share, AlertCircle, CheckCircle } from 'lucide-svelte';
  import AnalysisProgress from '$components/analysis/AnalysisProgress.svelte';
  import AnalysisResults from '$components/analysis/AnalysisResults.svelte';
  import AnalysisConfig from '$components/analysis/AnalysisConfig.svelte';
  
  export let data;
  
  let wsConnection: WebSocket;
  let analysisStatus = data.analysisStatus;
  let analysisResults = data.analysisResults;
  let repository = data.repository;
  
  $: repositoryId = $page.params.id;
  $: canStartAnalysis = analysisStatus.status !== 'in_progress';
  $: hasResults = analysisResults && analysisResults.length > 0;
  
  onMount(() => {
    // Connect to WebSocket for real-time updates
    connectWebSocket();
  });
  
  onDestroy(() => {
    if (wsConnection) {
      wsConnection.close();
    }
  });
  
  function connectWebSocket() {
    const wsUrl = `wss://api.gitinsight.com/ws/repository/${repositoryId}/analysis`;
    wsConnection = new WebSocket(wsUrl);
    
    wsConnection.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      if (data.type === 'analysis_progress') {
        analysisStatus = { ...analysisStatus, ...data.data };
      } else if (data.type === 'analysis_completed') {
        analysisStatus.status = 'completed';
        analysisStatus.progress = 100;
        // Reload results
        loadAnalysisResults();
      }
    };
    
    wsConnection.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
  }
  
  async function startAnalysis(config = {}) {
    try {
      const response = await fetch(`/api/repositories/${repositoryId}/analyze`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(config)
      });
      
      if (response.ok) {
        const result = await response.json();
        analysisStatus = {
          status: 'in_progress',
          progress: 0,
          jobId: result.job_id,
          startedAt: new Date().toISOString()
        };
      }
    } catch (error) {
      console.error('Failed to start analysis:', error);
    }
  }
  
  async function stopAnalysis() {
    try {
      await fetch(`/api/analysis/${analysisStatus.jobId}/cancel`, {
        method: 'POST'
      });
      
      analysisStatus.status = 'cancelled';
    } catch (error) {
      console.error('Failed to stop analysis:', error);
    }
  }
  
  async function loadAnalysisResults() {
    try {
      const response = await fetch(`/api/repositories/${repositoryId}/insights`);
      if (response.ok) {
        analysisResults = await response.json();
      }
    } catch (error) {
      console.error('Failed to load results:', error);
    }
  }
</script>

<svelte:head>
  <title>Analysis - {repository.name} - GitInsight</title>
</svelte:head>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold">Repository Analysis</h1>
      <p class="text-muted-foreground">
        {repository.full_name}
      </p>
    </div>
    
    <div class="flex items-center gap-2">
      {#if hasResults}
        <Button variant="outline" size="sm">
          <Download class="mr-2 h-4 w-4" />
          Export
        </Button>
        <Button variant="outline" size="sm">
          <Share class="mr-2 h-4 w-4" />
          Share
        </Button>
      {/if}
      
      {#if canStartAnalysis}
        <Button on:click={() => startAnalysis()}>
          <Play class="mr-2 h-4 w-4" />
          Start Analysis
        </Button>
      {:else}
        <Button variant="destructive" on:click={stopAnalysis}>
          <Square class="mr-2 h-4 w-4" />
          Stop Analysis
        </Button>
      {/if}
    </div>
  </div>
  
  <!-- Status card -->
  <Card>
    <CardHeader>
      <div class="flex items-center justify-between">
        <div>
          <CardTitle class="flex items-center gap-2">
            Analysis Status
            {#if analysisStatus.status === 'completed'}
              <CheckCircle class="h-5 w-5 text-green-500" />
            {:else if analysisStatus.status === 'failed'}
              <AlertCircle class="h-5 w-5 text-red-500" />
            {:else if analysisStatus.status === 'in_progress'}
              <RefreshCw class="h-5 w-5 animate-spin text-blue-500" />
            {/if}
          </CardTitle>
          <CardDescription>
            {#if analysisStatus.status === 'in_progress'}
              Analysis in progress...
            {:else if analysisStatus.status === 'completed'}
              Analysis completed successfully
            {:else if analysisStatus.status === 'failed'}
              Analysis failed
            {:else}
              Ready to start analysis
            {/if}
          </CardDescription>
        </div>
        
        <Badge variant={
          analysisStatus.status === 'completed' ? 'default' :
          analysisStatus.status === 'failed' ? 'destructive' :
          analysisStatus.status === 'in_progress' ? 'secondary' : 'outline'
        }>
          {analysisStatus.status}
        </Badge>
      </div>
    </CardHeader>
    
    {#if analysisStatus.status === 'in_progress'}
      <CardContent>
        <AnalysisProgress 
          progress={analysisStatus.progress}
          currentStep={analysisStatus.currentStep}
          estimatedTimeRemaining={analysisStatus.estimatedTimeRemaining}
        />
      </CardContent>
    {/if}
  </Card>
  
  <!-- Main content -->
  <Tabs value="results" class="space-y-4">
    <TabsList>
      <TabsTrigger value="results">Results</TabsTrigger>
      <TabsTrigger value="configuration">Configuration</TabsTrigger>
      <TabsTrigger value="history">History</TabsTrigger>
    </TabsList>
    
    <TabsContent value="results" class="space-y-4">
      {#if hasResults}
        <AnalysisResults results={analysisResults} {repository} />
      {:else if analysisStatus.status === 'completed'}
        <Alert>
          <AlertCircle class="h-4 w-4" />
          <AlertDescription>
            Analysis completed but no results found. Try running the analysis again.
          </AlertDescription>
        </Alert>
      {:else}
        <Card>
          <CardContent class="flex flex-col items-center justify-center py-12">
            <Play class="h-12 w-12 text-muted-foreground mb-4" />
            <h3 class="text-lg font-medium mb-2">No analysis results yet</h3>
            <p class="text-muted-foreground text-center mb-4">
              Start an analysis to see insights about code quality, security, and performance
            </p>
            <Button on:click={() => startAnalysis()}>
              <Play class="mr-2 h-4 w-4" />
              Start Analysis
            </Button>
          </CardContent>
        </Card>
      {/if}
    </TabsContent>
    
    <TabsContent value="configuration">
      <AnalysisConfig 
        {repository}
        on:startAnalysis={(e) => startAnalysis(e.detail)}
      />
    </TabsContent>
    
    <TabsContent value="history">
      <!-- Analysis history component -->
    </TabsContent>
  </Tabs>
</div>
```

## Navigation Patterns

### Breadcrumb Navigation

```svelte
<!-- src/lib/components/layout/Breadcrumbs.svelte -->
<script lang="ts">
  import { page } from '$app/stores';
  import { ChevronRight, Home } from 'lucide-svelte';
  
  interface BreadcrumbItem {
    label: string;
    href?: string;
    current?: boolean;
  }
  
  $: breadcrumbs = generateBreadcrumbs($page.url.pathname, $page.params);
  
  function generateBreadcrumbs(pathname: string, params: Record<string, string>): BreadcrumbItem[] {
    const segments = pathname.split('/').filter(Boolean);
    const items: BreadcrumbItem[] = [
      { label: 'Home', href: '/dashboard' }
    ];
    
    let currentPath = '';
    
    for (let i = 0; i < segments.length; i++) {
      const segment = segments[i];
      currentPath += `/${segment}`;
      const isLast = i === segments.length - 1;
      
      let label = segment;
      let href = currentPath;
      
      // Custom labels for specific routes
      if (segment === 'repositories') {
        label = 'Repositories';
      } else if (segment === 'add') {
        label = 'Add Repository';
      } else if (segment === 'analysis') {
        label = 'Analysis';
      } else if (segment === 'insights') {
        label = 'Insights';
      } else if (segment === 'settings') {
        label = 'Settings';
      } else if (params.id && segment === params.id) {
        // For dynamic routes, try to get a meaningful name
        label = getRepositoryName(params.id) || segment;
      }
      
      items.push({
        label,
        href: isLast ? undefined : href,
        current: isLast
      });
    }
    
    return items;
  }
  
  function getRepositoryName(id: string): string | null {
    // This would typically come from a store or API
    // For now, return null to use the ID
    return null;
  }
</script>

<nav aria-label="Breadcrumb" class="flex items-center space-x-1 text-sm text-muted-foreground">
  {#each breadcrumbs as item, index}
    {#if index > 0}
      <ChevronRight class="h-4 w-4" />
    {/if}
    
    {#if item.href}
      <a
        href={item.href}
        class="hover:text-foreground transition-colors"
        class:flex={index === 0}
        class:items-center={index === 0}
        class:gap-1={index === 0}
      >
        {#if index === 0}
          <Home class="h-4 w-4" />
        {/if}
        {item.label}
      </a>
    {:else}
      <span class="text-foreground font-medium" aria-current="page">
        {item.label}
      </span>
    {/if}
  {/each}
</nav>
```

This user flows and navigation documentation provides comprehensive guidance for implementing seamless user experiences throughout the GitInsight application, ensuring intuitive navigation and efficient task completion.
