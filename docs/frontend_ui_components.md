# UI Components Documentation

## Overview

This document provides comprehensive documentation for all UI components used in GitInsight, including custom components, Shadcn UI integrations, and React components. Each component includes detailed props, usage examples, and design system implementation guidelines.

## Component Categories

### Layout Components
- **Header** - Main navigation and user menu
- **Sidebar** - Navigation sidebar with collapsible sections
- **Footer** - Application footer with links and information
- **PageLayout** - Standard page wrapper with breadcrumbs
- **DashboardLayout** - Dashboard-specific layout with widgets

### Data Display Components
- **RepositoryCard** - Repository information display
- **InsightCard** - Analysis insight presentation
- **MetricsCard** - Key metrics display
- **DataTable** - Sortable and filterable data tables
- **Charts** - Various chart components for data visualization

### Form Components
- **RepositoryForm** - Add/edit repository form
- **SearchForm** - Repository search interface
- **SettingsForm** - User and application settings
- **FilterForm** - Data filtering controls

### Interactive Components
- **AnalysisWidget** - Interactive analysis dashboard
- **CodeViewer** - Syntax-highlighted code display
- **NotificationCenter** - Toast notifications and alerts
- **ConfirmDialog** - Confirmation dialogs
- **LoadingStates** - Loading indicators and skeletons

## Layout Components

### Header Component

```svelte
<!-- src/lib/components/layout/Header.svelte -->
<script lang="ts">
  import { page } from '$app/stores';
  import { authStore, uiStore } from '$stores';
  import { Button } from '$components/ui/button';
  import { Avatar, AvatarFallback, AvatarImage } from '$components/ui/avatar';
  import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
  } from '$components/ui/dropdown-menu';
  import { Menu, Search, Bell, Settings, LogOut, User } from 'lucide-svelte';
  import ThemeToggle from './ThemeToggle.svelte';
  import SearchDialog from './SearchDialog.svelte';
  
  export let user: User | null = null;
  
  let searchOpen = false;
  
  function toggleSidebar() {
    uiStore.toggleSidebar();
  }
  
  function openSearch() {
    searchOpen = true;
  }
  
  function handleLogout() {
    authStore.clearAuth();
    goto('/auth/login');
  }
</script>

<header class="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
  <div class="container flex h-14 items-center">
    <!-- Mobile menu button -->
    <Button
      variant="ghost"
      size="icon"
      class="mr-2 md:hidden"
      on:click={toggleSidebar}
    >
      <Menu class="h-4 w-4" />
      <span class="sr-only">Toggle menu</span>
    </Button>
    
    <!-- Logo -->
    <div class="mr-4 hidden md:flex">
      <a class="mr-6 flex items-center space-x-2" href="/">
        <div class="h-6 w-6 rounded bg-primary"></div>
        <span class="hidden font-bold sm:inline-block">GitInsight</span>
      </a>
    </div>
    
    <!-- Navigation -->
    <nav class="flex items-center space-x-6 text-sm font-medium">
      <a
        href="/dashboard"
        class="transition-colors hover:text-foreground/80"
        class:text-foreground={$page.url.pathname === '/dashboard'}
        class:text-foreground/60={$page.url.pathname !== '/dashboard'}
      >
        Dashboard
      </a>
      <a
        href="/repositories"
        class="transition-colors hover:text-foreground/80"
        class:text-foreground={$page.url.pathname.startsWith('/repositories')}
        class:text-foreground/60={!$page.url.pathname.startsWith('/repositories')}
      >
        Repositories
      </a>
      <a
        href="/search"
        class="transition-colors hover:text-foreground/80"
        class:text-foreground={$page.url.pathname === '/search'}
        class:text-foreground/60={$page.url.pathname !== '/search'}
      >
        Explore
      </a>
    </nav>
    
    <div class="flex flex-1 items-center justify-between space-x-2 md:justify-end">
      <!-- Search -->
      <div class="w-full flex-1 md:w-auto md:flex-none">
        <Button
          variant="outline"
          class="relative h-8 w-full justify-start rounded-[0.5rem] text-sm font-normal text-muted-foreground shadow-none sm:pr-12 md:w-40 lg:w-64"
          on:click={openSearch}
        >
          <Search class="mr-2 h-4 w-4" />
          Search repositories...
          <kbd class="pointer-events-none absolute right-[0.3rem] top-[0.3rem] hidden h-5 select-none items-center gap-1 rounded border bg-muted px-1.5 font-mono text-[10px] font-medium opacity-100 sm:flex">
            <span class="text-xs">⌘</span>K
          </kbd>
        </Button>
      </div>
      
      <!-- Actions -->
      <div class="flex items-center space-x-2">
        <ThemeToggle />
        
        {#if user}
          <!-- Notifications -->
          <Button variant="ghost" size="icon" class="relative">
            <Bell class="h-4 w-4" />
            <span class="absolute -top-1 -right-1 h-3 w-3 rounded-full bg-red-500 text-[10px] font-medium text-white flex items-center justify-center">
              3
            </span>
            <span class="sr-only">Notifications</span>
          </Button>
          
          <!-- User menu -->
          <DropdownMenu>
            <DropdownMenuTrigger asChild let:builder>
              <Button variant="ghost" class="relative h-8 w-8 rounded-full" builders={[builder]}>
                <Avatar class="h-8 w-8">
                  <AvatarImage src={user.avatar_url} alt={user.username} />
                  <AvatarFallback>{user.username.slice(0, 2).toUpperCase()}</AvatarFallback>
                </Avatar>
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent class="w-56" align="end">
              <DropdownMenuLabel class="font-normal">
                <div class="flex flex-col space-y-1">
                  <p class="text-sm font-medium leading-none">{user.name || user.username}</p>
                  <p class="text-xs leading-none text-muted-foreground">{user.email}</p>
                </div>
              </DropdownMenuLabel>
              <DropdownMenuSeparator />
              <DropdownMenuItem href="/profile">
                <User class="mr-2 h-4 w-4" />
                <span>Profile</span>
              </DropdownMenuItem>
              <DropdownMenuItem href="/settings">
                <Settings class="mr-2 h-4 w-4" />
                <span>Settings</span>
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem on:click={handleLogout}>
                <LogOut class="mr-2 h-4 w-4" />
                <span>Log out</span>
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        {:else}
          <Button href="/auth/login" size="sm">Sign In</Button>
        {/if}
      </div>
    </div>
  </div>
</header>

<SearchDialog bind:open={searchOpen} />
```

### Sidebar Component

```svelte
<!-- src/lib/components/layout/Sidebar.svelte -->
<script lang="ts">
  import { page } from '$app/stores';
  import { sidebarOpen } from '$stores/ui';
  import { Button } from '$components/ui/button';
  import { ScrollArea } from '$components/ui/scroll-area';
  import { Separator } from '$components/ui/separator';
  import { Badge } from '$components/ui/badge';
  import {
    Home,
    FolderGit2,
    Search,
    BarChart3,
    Settings,
    Plus,
    Star,
    Clock,
    TrendingUp
  } from 'lucide-svelte';
  
  interface NavItem {
    title: string;
    href: string;
    icon: any;
    badge?: string;
    children?: NavItem[];
  }
  
  const navigation: NavItem[] = [
    {
      title: 'Dashboard',
      href: '/dashboard',
      icon: Home
    },
    {
      title: 'Repositories',
      href: '/repositories',
      icon: FolderGit2,
      children: [
        { title: 'All Repositories', href: '/repositories', icon: FolderGit2 },
        { title: 'Add Repository', href: '/repositories/add', icon: Plus },
        { title: 'Starred', href: '/repositories?filter=starred', icon: Star },
        { title: 'Recent', href: '/repositories?filter=recent', icon: Clock }
      ]
    },
    {
      title: 'Explore',
      href: '/search',
      icon: Search
    },
    {
      title: 'Analytics',
      href: '/analytics',
      icon: BarChart3,
      badge: 'Pro'
    },
    {
      title: 'Trending',
      href: '/trending',
      icon: TrendingUp
    }
  ];
  
  $: currentPath = $page.url.pathname;
  
  function isActive(href: string): boolean {
    if (href === '/dashboard') {
      return currentPath === '/dashboard';
    }
    return currentPath.startsWith(href);
  }
</script>

<aside
  class="fixed inset-y-0 left-0 z-50 w-64 bg-background border-r transition-transform duration-200 ease-in-out lg:translate-x-0"
  class:translate-x-0={$sidebarOpen}
  class:-translate-x-full={!$sidebarOpen}
>
  <div class="flex h-full flex-col">
    <!-- Logo -->
    <div class="flex h-14 items-center border-b px-4">
      <a class="flex items-center space-x-2" href="/">
        <div class="h-6 w-6 rounded bg-primary"></div>
        <span class="font-bold">GitInsight</span>
      </a>
    </div>
    
    <!-- Navigation -->
    <ScrollArea class="flex-1 px-3 py-4">
      <nav class="space-y-2">
        {#each navigation as item}
          <div>
            <Button
              variant={isActive(item.href) ? 'secondary' : 'ghost'}
              class="w-full justify-start"
              href={item.href}
            >
              <svelte:component this={item.icon} class="mr-2 h-4 w-4" />
              {item.title}
              {#if item.badge}
                <Badge variant="secondary" class="ml-auto text-xs">
                  {item.badge}
                </Badge>
              {/if}
            </Button>
            
            {#if item.children && isActive(item.href)}
              <div class="ml-4 mt-2 space-y-1">
                {#each item.children as child}
                  <Button
                    variant={currentPath === child.href ? 'secondary' : 'ghost'}
                    size="sm"
                    class="w-full justify-start"
                    href={child.href}
                  >
                    <svelte:component this={child.icon} class="mr-2 h-3 w-3" />
                    {child.title}
                  </Button>
                {/each}
              </div>
            {/if}
          </div>
        {/each}
      </nav>
    </ScrollArea>
    
    <!-- Footer -->
    <div class="border-t p-4">
      <Button variant="outline" size="sm" class="w-full" href="/settings">
        <Settings class="mr-2 h-4 w-4" />
        Settings
      </Button>
    </div>
  </div>
</aside>

<!-- Overlay for mobile -->
{#if $sidebarOpen}
  <div
    class="fixed inset-0 z-40 bg-background/80 backdrop-blur-sm lg:hidden"
    on:click={() => sidebarOpen.set(false)}
    on:keydown={(e) => e.key === 'Escape' && sidebarOpen.set(false)}
  ></div>
{/if}
```

## Data Display Components

### Repository Card Component

```svelte
<!-- src/lib/components/repository/RepositoryCard.svelte -->
<script lang="ts">
  import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '$components/ui/card';
  import { Button } from '$components/ui/button';
  import { Badge } from '$components/ui/badge';
  import { Progress } from '$components/ui/progress';
  import { Avatar, AvatarFallback, AvatarImage } from '$components/ui/avatar';
  import {
    Star,
    GitFork,
    Eye,
    Clock,
    TrendingUp,
    AlertTriangle,
    CheckCircle,
    Loader2
  } from 'lucide-svelte';
  import type { Repository } from '$types/repository';
  
  export let repository: Repository;
  export let showAnalysis = true;
  export let showActions = true;
  export let compact = false;
  
  $: qualityScore = repository.insights?.reduce((acc, insight) => 
    acc + insight.confidence_score, 0) / (repository.insights?.length || 1) * 100;
  
  $: statusIcon = {
    'pending': Clock,
    'in_progress': Loader2,
    'completed': CheckCircle,
    'failed': AlertTriangle
  }[repository.analysis_status];
  
  $: statusColor = {
    'pending': 'text-muted-foreground',
    'in_progress': 'text-blue-500',
    'completed': 'text-green-500',
    'failed': 'text-red-500'
  }[repository.analysis_status];
  
  function formatNumber(num: number): string {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
  }
  
  function formatDate(date: string): string {
    return new Date(date).toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }
</script>

<Card class="group hover:shadow-md transition-all duration-200" class:compact>
  <CardHeader class={compact ? 'pb-3' : 'pb-4'}>
    <div class="flex items-start justify-between gap-4">
      <div class="min-w-0 flex-1">
        <CardTitle class="text-lg leading-6">
          <a 
            href="/repositories/{repository.id}" 
            class="hover:underline truncate block"
          >
            {repository.name}
          </a>
        </CardTitle>
        <CardDescription class="flex items-center gap-2 mt-1">
          <Avatar class="h-4 w-4">
            <AvatarImage src={repository.owner.avatar_url} alt={repository.owner.username} />
            <AvatarFallback class="text-xs">
              {repository.owner.username.slice(0, 1).toUpperCase()}
            </AvatarFallback>
          </Avatar>
          <span class="truncate">{repository.full_name}</span>
        </CardDescription>
      </div>
      
      <div class="flex items-center gap-2 flex-shrink-0">
        <Badge variant={repository.is_private ? 'secondary' : 'outline'} class="text-xs">
          {repository.is_private ? 'Private' : 'Public'}
        </Badge>
        
        {#if showAnalysis}
          <div class="flex items-center gap-1 {statusColor}">
            <svelte:component 
              this={statusIcon} 
              class="h-3 w-3" 
              class:animate-spin={repository.analysis_status === 'in_progress'}
            />
            {#if repository.analysis_status === 'completed'}
              <TrendingUp class="h-3 w-3" />
            {/if}
          </div>
        {/if}
      </div>
    </div>
  </CardHeader>
  
  <CardContent class={compact ? 'py-3' : 'py-4'}>
    {#if repository.description && !compact}
      <p class="text-sm text-muted-foreground mb-4 line-clamp-2">
        {repository.description}
      </p>
    {/if}
    
    <!-- Repository stats -->
    <div class="flex items-center gap-4 text-sm text-muted-foreground mb-4">
      <div class="flex items-center gap-1">
        <Star class="h-3 w-3" />
        <span>{formatNumber(repository.stars)}</span>
      </div>
      <div class="flex items-center gap-1">
        <GitFork class="h-3 w-3" />
        <span>{formatNumber(repository.forks)}</span>
      </div>
      <div class="flex items-center gap-1">
        <Eye class="h-3 w-3" />
        <span>{formatNumber(repository.watchers)}</span>
      </div>
      {#if repository.last_analyzed}
        <div class="flex items-center gap-1">
          <Clock class="h-3 w-3" />
          <span>{formatDate(repository.last_analyzed)}</span>
        </div>
      {/if}
    </div>
    
    <!-- Language and quality score -->
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        {#if repository.language}
          <Badge variant="outline" class="text-xs">
            {repository.language}
          </Badge>
        {/if}
      </div>
      
      {#if showAnalysis && repository.analysis_status === 'completed' && qualityScore}
        <div class="flex items-center gap-2 text-sm">
          <span class="text-muted-foreground">Quality:</span>
          <Progress value={qualityScore} class="w-16 h-2" />
          <span class="text-xs font-medium min-w-[3ch]">
            {Math.round(qualityScore)}%
          </span>
        </div>
      {/if}
    </div>
  </CardContent>
  
  {#if showActions && !compact}
    <CardFooter class="flex justify-between pt-4">
      <Button variant="outline" size="sm" href="/repositories/{repository.id}">
        View Details
      </Button>
      
      {#if repository.analysis_status === 'in_progress'}
        <Button size="sm" disabled>
          <Loader2 class="mr-2 h-3 w-3 animate-spin" />
          Analyzing...
        </Button>
      {:else}
        <Button size="sm" href="/repositories/{repository.id}/analysis">
          {repository.analysis_status === 'completed' ? 'Re-analyze' : 'Analyze'}
        </Button>
      {/if}
    </CardFooter>
  {/if}
</Card>

<style>
  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style>
```

### Data Table Component

```svelte
<!-- src/lib/components/ui/DataTable.svelte -->
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { Button } from '$components/ui/button';
  import { Input } from '$components/ui/input';
  import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
  } from '$components/ui/table';
  import { Badge } from '$components/ui/badge';
  import { ArrowUpDown, ArrowUp, ArrowDown, Search } from 'lucide-svelte';
  
  interface Column {
    key: string;
    title: string;
    sortable?: boolean;
    width?: string;
    align?: 'left' | 'center' | 'right';
    render?: (value: any, row: any) => string;
  }
  
  export let data: any[] = [];
  export let columns: Column[] = [];
  export let loading = false;
  export let searchable = true;
  export let pagination = true;
  export let pageSize = 10;
  export let currentPage = 1;
  export let totalItems = 0;
  
  const dispatch = createEventDispatcher();
  
  let searchQuery = '';
  let sortColumn = '';
  let sortDirection: 'asc' | 'desc' = 'asc';
  
  $: filteredData = searchQuery
    ? data.filter(row =>
        columns.some(col =>
          String(row[col.key]).toLowerCase().includes(searchQuery.toLowerCase())
        )
      )
    : data;
  
  $: paginatedData = pagination
    ? filteredData.slice((currentPage - 1) * pageSize, currentPage * pageSize)
    : filteredData;
  
  $: totalPages = Math.ceil(filteredData.length / pageSize);
  
  function handleSort(column: Column) {
    if (!column.sortable) return;
    
    if (sortColumn === column.key) {
      sortDirection = sortDirection === 'asc' ? 'desc' : 'asc';
    } else {
      sortColumn = column.key;
      sortDirection = 'asc';
    }
    
    dispatch('sort', { column: column.key, direction: sortDirection });
  }
  
  function handlePageChange(page: number) {
    currentPage = page;
    dispatch('pageChange', { page });
  }
  
  function getSortIcon(column: Column) {
    if (!column.sortable) return null;
    if (sortColumn !== column.key) return ArrowUpDown;
    return sortDirection === 'asc' ? ArrowUp : ArrowDown;
  }
  
  function renderCell(column: Column, row: any) {
    const value = row[column.key];
    return column.render ? column.render(value, row) : value;
  }
</script>

<div class="space-y-4">
  <!-- Search -->
  {#if searchable}
    <div class="flex items-center space-x-2">
      <div class="relative flex-1 max-w-sm">
        <Search class="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
        <Input
          placeholder="Search..."
          bind:value={searchQuery}
          class="pl-8"
        />
      </div>
    </div>
  {/if}
  
  <!-- Table -->
  <div class="rounded-md border">
    <Table>
      <TableHeader>
        <TableRow>
          {#each columns as column}
            <TableHead
              class="cursor-pointer select-none"
              class:text-center={column.align === 'center'}
              class:text-right={column.align === 'right'}
              style={column.width ? `width: ${column.width}` : ''}
              on:click={() => handleSort(column)}
            >
              <div class="flex items-center space-x-2">
                <span>{column.title}</span>
                {#if column.sortable}
                  <svelte:component this={getSortIcon(column)} class="h-4 w-4" />
                {/if}
              </div>
            </TableHead>
          {/each}
        </TableRow>
      </TableHeader>
      <TableBody>
        {#if loading}
          {#each Array(pageSize) as _}
            <TableRow>
              {#each columns as _}
                <TableCell>
                  <div class="h-4 bg-muted animate-pulse rounded"></div>
                </TableCell>
              {/each}
            </TableRow>
          {/each}
        {:else if paginatedData.length === 0}
          <TableRow>
            <TableCell colspan={columns.length} class="text-center py-8 text-muted-foreground">
              No data available
            </TableCell>
          </TableRow>
        {:else}
          {#each paginatedData as row, index}
            <TableRow>
              {#each columns as column}
                <TableCell
                  class:text-center={column.align === 'center'}
                  class:text-right={column.align === 'right'}
                >
                  {@html renderCell(column, row)}
                </TableCell>
              {/each}
            </TableRow>
          {/each}
        {/if}
      </TableBody>
    </Table>
  </div>
  
  <!-- Pagination -->
  {#if pagination && totalPages > 1}
    <div class="flex items-center justify-between">
      <div class="text-sm text-muted-foreground">
        Showing {(currentPage - 1) * pageSize + 1} to {Math.min(currentPage * pageSize, filteredData.length)} of {filteredData.length} results
      </div>
      
      <div class="flex items-center space-x-2">
        <Button
          variant="outline"
          size="sm"
          disabled={currentPage === 1}
          on:click={() => handlePageChange(currentPage - 1)}
        >
          Previous
        </Button>
        
        {#each Array(Math.min(5, totalPages)) as _, i}
          {@const page = i + 1}
          <Button
            variant={currentPage === page ? 'default' : 'outline'}
            size="sm"
            on:click={() => handlePageChange(page)}
          >
            {page}
          </Button>
        {/each}
        
        <Button
          variant="outline"
          size="sm"
          disabled={currentPage === totalPages}
          on:click={() => handlePageChange(currentPage + 1)}
        >
          Next
        </Button>
      </div>
    </div>
  {/if}
</div>
```

## Interactive Components

### Loading States Component

```svelte
<!-- src/lib/components/ui/LoadingStates.svelte -->
<script lang="ts">
  export let type: 'spinner' | 'skeleton' | 'pulse' | 'dots' = 'spinner';
  export let size: 'sm' | 'md' | 'lg' = 'md';
  export let text: string = '';
  export let fullScreen = false;
  
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-6 w-6',
    lg: 'h-8 w-8'
  };
</script>

<div 
  class="flex items-center justify-center"
  class:fixed={fullScreen}
  class:inset-0={fullScreen}
  class:bg-background/80={fullScreen}
  class:backdrop-blur-sm={fullScreen}
  class:z-50={fullScreen}
>
  <div class="flex flex-col items-center space-y-2">
    {#if type === 'spinner'}
      <div class="animate-spin rounded-full border-2 border-current border-t-transparent {sizeClasses[size]}"></div>
    {:else if type === 'skeleton'}
      <div class="space-y-2">
        <div class="h-4 bg-muted animate-pulse rounded w-48"></div>
        <div class="h-4 bg-muted animate-pulse rounded w-32"></div>
        <div class="h-4 bg-muted animate-pulse rounded w-40"></div>
      </div>
    {:else if type === 'pulse'}
      <div class="animate-pulse">
        <div class="h-12 w-12 bg-muted rounded-full"></div>
      </div>
    {:else if type === 'dots'}
      <div class="flex space-x-1">
        <div class="h-2 w-2 bg-current rounded-full animate-bounce [animation-delay:-0.3s]"></div>
        <div class="h-2 w-2 bg-current rounded-full animate-bounce [animation-delay:-0.15s]"></div>
        <div class="h-2 w-2 bg-current rounded-full animate-bounce"></div>
      </div>
    {/if}
    
    {#if text}
      <p class="text-sm text-muted-foreground">{text}</p>
    {/if}
  </div>
</div>
```

This UI components documentation provides comprehensive examples and usage patterns for building consistent, accessible, and maintainable user interfaces in GitInsight.
