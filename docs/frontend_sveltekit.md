# SvelteKit Implementation Documentation

## Overview

SvelteKit serves as the primary framework for GitInsight's frontend, providing server-side rendering, file-based routing, and excellent developer experience. This document covers the complete SvelteKit implementation including configuration, routing patterns, data loading, and integration with the backend services.

## SvelteKit Configuration

### Core Configuration Files

#### svelte.config.js

```javascript
import adapter from '@sveltejs/adapter-auto';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  preprocess: vitePreprocess(),
  
  kit: {
    adapter: adapter(),
    
    // Path configuration
    paths: {
      base: process.env.NODE_ENV === 'production' ? '/app' : '',
      assets: process.env.NODE_ENV === 'production' ? 'https://cdn.gitinsight.com' : ''
    },
    
    // CSP configuration for security
    csp: {
      mode: 'auto',
      directives: {
        'script-src': ['self', 'unsafe-inline', 'https://api.github.com'],
        'style-src': ['self', 'unsafe-inline'],
        'img-src': ['self', 'data:', 'https:'],
        'connect-src': ['self', 'https://api.gitinsight.com', 'wss://api.gitinsight.com']
      }
    },
    
    // Service worker configuration
    serviceWorker: {
      register: true,
      files: (filepath) => !/\.DS_Store/.test(filepath)
    },
    
    // Alias configuration
    alias: {
      $components: 'src/lib/components',
      $stores: 'src/lib/stores',
      $utils: 'src/lib/utils',
      $types: 'src/lib/types',
      $api: 'src/lib/api'
    }
  }
};

export default config;
```

#### vite.config.ts

```typescript
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
  plugins: [sveltekit()],
  
  define: {
    __APP_VERSION__: JSON.stringify(process.env.npm_package_version)
  },
  
  server: {
    port: 5173,
    host: true,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
        secure: false
      },
      '/ws': {
        target: 'ws://localhost:8080',
        ws: true
      }
    }
  },
  
  build: {
    target: 'es2022',
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom'],
          'chart-vendor': ['chart.js', 'chartjs-adapter-date-fns'],
          'ui-vendor': ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu']
        }
      }
    }
  },
  
  optimizeDeps: {
    include: ['react', 'react-dom', 'chart.js']
  }
});
```

## Routing System

### File-based Routing Structure

```
src/routes/
├── +layout.svelte              # Root layout
├── +layout.ts                  # Root layout data
├── +page.svelte               # Home page (/)
├── +page.ts                   # Home page data
├── +error.svelte              # Error page
├── auth/                      # Authentication routes
│   ├── +layout.svelte         # Auth layout
│   ├── login/
│   │   ├── +page.svelte       # Login page (/auth/login)
│   │   └── +page.server.ts    # Server-side login logic
│   ├── callback/
│   │   └── +page.server.ts    # OAuth callback (/auth/callback)
│   └── logout/
│       └── +page.server.ts    # Logout handler (/auth/logout)
├── dashboard/
│   ├── +layout.svelte         # Dashboard layout
│   ├── +layout.ts             # Dashboard data loading
│   ├── +page.svelte           # Dashboard home (/dashboard)
│   └── +page.ts               # Dashboard page data
├── repositories/
│   ├── +page.svelte           # Repository list (/repositories)
│   ├── +page.ts               # Repository list data
│   ├── [id]/                  # Dynamic repository routes
│   │   ├── +layout.svelte     # Repository layout
│   │   ├── +layout.ts         # Repository data loading
│   │   ├── +page.svelte       # Repository overview (/repositories/[id])
│   │   ├── +page.ts           # Repository page data
│   │   ├── insights/
│   │   │   ├── +page.svelte   # Insights page (/repositories/[id]/insights)
│   │   │   └── +page.ts       # Insights data
│   │   ├── analysis/
│   │   │   ├── +page.svelte   # Analysis page (/repositories/[id]/analysis)
│   │   │   └── +page.ts       # Analysis data
│   │   └── settings/
│   │       ├── +page.svelte   # Settings page (/repositories/[id]/settings)
│   │       └── +page.server.ts # Settings form actions
│   └── add/
│       ├── +page.svelte       # Add repository (/repositories/add)
│       └── +page.server.ts    # Add repository form action
├── search/
│   ├── +page.svelte           # Search page (/search)
│   └── +page.ts               # Search data loading
├── profile/
│   ├── +page.svelte           # User profile (/profile)
│   ├── +page.ts               # Profile data
│   └── +page.server.ts        # Profile form actions
└── api/                       # Server-side API routes
    ├── auth/
    │   └── session/
    │       └── +server.ts     # Session API (/api/auth/session)
    ├── repositories/
    │   ├── +server.ts         # Repository API (/api/repositories)
    │   └── [id]/
    │       └── +server.ts     # Single repository API (/api/repositories/[id])
    └── search/
        └── +server.ts         # Search API (/api/search)
```

### Layout System

#### Root Layout (+layout.svelte)

```svelte
<script lang="ts">
  import '../app.css';
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import { authStore } from '$stores/auth';
  import { themeStore } from '$stores/ui';
  import Header from '$components/layout/Header.svelte';
  import Footer from '$components/layout/Footer.svelte';
  import Notifications from '$components/ui/Notifications.svelte';
  import LoadingBar from '$components/ui/LoadingBar.svelte';
  
  export let data;
  
  // Initialize stores with server data
  onMount(() => {
    if (data.user) {
      authStore.setUser(data.user);
    }
    themeStore.initialize();
  });
  
  $: isAuthPage = $page.route.id?.startsWith('/auth');
  $: isDashboard = $page.route.id?.startsWith('/dashboard');
</script>

<svelte:head>
  <title>GitInsight - AI-Powered Repository Analysis</title>
  <meta name="description" content="Discover, evaluate, and engage with open-source projects using AI-driven insights." />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</svelte:head>

<div class="app" class:dark={$themeStore.isDark}>
  <LoadingBar />
  
  {#if !isAuthPage}
    <Header user={data.user} />
  {/if}
  
  <main class="main" class:auth-page={isAuthPage} class:dashboard={isDashboard}>
    <slot />
  </main>
  
  {#if !isAuthPage}
    <Footer />
  {/if}
  
  <Notifications />
</div>

<style>
  .app {
    min-height: 100vh;
    display: flex;
    flex-direction: column;
    background: var(--background);
    color: var(--foreground);
  }
  
  .main {
    flex: 1;
    display: flex;
    flex-direction: column;
  }
  
  .auth-page {
    justify-content: center;
    align-items: center;
    padding: 2rem;
  }
  
  .dashboard {
    background: var(--muted);
  }
</style>
```

#### Root Layout Data (+layout.ts)

```typescript
import type { LayoutLoad } from './$types';
import { browser } from '$app/environment';
import { authApi } from '$api/auth';

export const load: LayoutLoad = async ({ fetch, url }) => {
  // Only check authentication on client-side or for protected routes
  if (browser || url.pathname.startsWith('/dashboard') || url.pathname.startsWith('/repositories')) {
    try {
      const user = await authApi.getCurrentUser(fetch);
      return {
        user,
        pathname: url.pathname
      };
    } catch (error) {
      // User not authenticated
      return {
        user: null,
        pathname: url.pathname
      };
    }
  }
  
  return {
    user: null,
    pathname: url.pathname
  };
};
```

## Data Loading Patterns

### Page Data Loading

#### Repository List Page (+page.ts)

```typescript
import type { PageLoad } from './$types';
import { error, redirect } from '@sveltejs/kit';
import { repositoryApi } from '$api/repositories';
import type { Repository } from '$types/repository';

export const load: PageLoad = async ({ fetch, url, parent }) => {
  const { user } = await parent();
  
  // Redirect to login if not authenticated
  if (!user) {
    throw redirect(302, '/auth/login');
  }
  
  const searchParams = url.searchParams;
  const page = parseInt(searchParams.get('page') || '1');
  const limit = parseInt(searchParams.get('limit') || '20');
  const sort = searchParams.get('sort') || 'updated';
  const filter = searchParams.get('filter') || 'all';
  
  try {
    const [repositories, stats] = await Promise.all([
      repositoryApi.getRepositories(fetch, { page, limit, sort, filter }),
      repositoryApi.getStats(fetch)
    ]);
    
    return {
      repositories: repositories.data,
      pagination: repositories.pagination,
      stats,
      filters: { page, limit, sort, filter }
    };
  } catch (err) {
    console.error('Failed to load repositories:', err);
    throw error(500, 'Failed to load repositories');
  }
};
```

#### Repository Detail Page (+page.ts)

```typescript
import type { PageLoad } from './$types';
import { error } from '@sveltejs/kit';
import { repositoryApi } from '$api/repositories';
import { insightApi } from '$api/insights';

export const load: PageLoad = async ({ params, fetch, parent }) => {
  const { user } = await parent();
  const repositoryId = params.id;
  
  try {
    const [repository, insights, analysisStatus] = await Promise.all([
      repositoryApi.getRepository(fetch, repositoryId),
      insightApi.getInsights(fetch, repositoryId, { limit: 10 }),
      repositoryApi.getAnalysisStatus(fetch, repositoryId)
    ]);
    
    // Check if user has access to this repository
    if (!repository.isPublic && repository.ownerId !== user?.id) {
      throw error(403, 'Access denied');
    }
    
    return {
      repository,
      insights: insights.data,
      analysisStatus,
      canEdit: repository.ownerId === user?.id
    };
  } catch (err) {
    if (err.status === 404) {
      throw error(404, 'Repository not found');
    }
    throw error(500, 'Failed to load repository');
  }
};
```

### Server-side Form Actions

#### Add Repository Form Action (+page.server.ts)

```typescript
import type { Actions, PageServerLoad } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import { z } from 'zod';
import { repositoryApi } from '$api/repositories';

const addRepositorySchema = z.object({
  githubUrl: z.string().url('Please enter a valid GitHub URL'),
  autoAnalyze: z.boolean().default(true),
  isPrivate: z.boolean().default(false)
});

export const load: PageServerLoad = async ({ locals }) => {
  // Ensure user is authenticated
  if (!locals.user) {
    throw redirect(302, '/auth/login');
  }
  
  return {
    user: locals.user
  };
};

export const actions: Actions = {
  default: async ({ request, locals, fetch }) => {
    if (!locals.user) {
      return fail(401, { error: 'Authentication required' });
    }
    
    const formData = await request.formData();
    const data = {
      githubUrl: formData.get('githubUrl'),
      autoAnalyze: formData.get('autoAnalyze') === 'on',
      isPrivate: formData.get('isPrivate') === 'on'
    };
    
    // Validate form data
    const result = addRepositorySchema.safeParse(data);
    if (!result.success) {
      return fail(400, {
        error: 'Invalid form data',
        errors: result.error.flatten().fieldErrors,
        data
      });
    }
    
    try {
      const repository = await repositoryApi.addRepository(fetch, result.data);
      
      // Redirect to the new repository page
      throw redirect(302, `/repositories/${repository.id}`);
    } catch (error) {
      console.error('Failed to add repository:', error);
      return fail(500, {
        error: 'Failed to add repository. Please try again.',
        data
      });
    }
  }
};
```

## Server-side API Routes

### Repository API Route (+server.ts)

```typescript
import type { RequestHandler } from './$types';
import { json, error } from '@sveltejs/kit';
import { repositoryService } from '$lib/server/services/repository';
import { authenticate } from '$lib/server/auth';

export const GET: RequestHandler = async ({ url, locals }) => {
  const user = await authenticate(locals);
  if (!user) {
    throw error(401, 'Authentication required');
  }
  
  const searchParams = url.searchParams;
  const page = parseInt(searchParams.get('page') || '1');
  const limit = Math.min(parseInt(searchParams.get('limit') || '20'), 100);
  const sort = searchParams.get('sort') || 'updated';
  const filter = searchParams.get('filter') || 'all';
  
  try {
    const repositories = await repositoryService.getUserRepositories(user.id, {
      page,
      limit,
      sort,
      filter
    });
    
    return json(repositories);
  } catch (err) {
    console.error('Failed to fetch repositories:', err);
    throw error(500, 'Failed to fetch repositories');
  }
};

export const POST: RequestHandler = async ({ request, locals }) => {
  const user = await authenticate(locals);
  if (!user) {
    throw error(401, 'Authentication required');
  }
  
  try {
    const data = await request.json();
    const repository = await repositoryService.addRepository(user.id, data);
    
    return json(repository, { status: 201 });
  } catch (err) {
    console.error('Failed to add repository:', err);
    throw error(500, 'Failed to add repository');
  }
};
```

## Hooks and Middleware

### Server Hooks (hooks.server.ts)

```typescript
import type { Handle, HandleServerError } from '@sveltejs/kit';
import { sequence } from '@sveltejs/kit/hooks';
import { authService } from '$lib/server/auth';
import { logger } from '$lib/server/logger';

// Authentication hook
const authHook: Handle = async ({ event, resolve }) => {
  const token = event.cookies.get('auth-token') || 
                event.request.headers.get('authorization')?.replace('Bearer ', '');
  
  if (token) {
    try {
      const user = await authService.verifyToken(token);
      event.locals.user = user;
    } catch (error) {
      // Invalid token, clear cookie
      event.cookies.delete('auth-token', { path: '/' });
    }
  }
  
  return resolve(event);
};

// Logging hook
const loggingHook: Handle = async ({ event, resolve }) => {
  const start = Date.now();
  
  const response = await resolve(event);
  
  const duration = Date.now() - start;
  logger.info(`${event.request.method} ${event.url.pathname} ${response.status} ${duration}ms`);
  
  return response;
};

// CORS hook for API routes
const corsHook: Handle = async ({ event, resolve }) => {
  if (event.url.pathname.startsWith('/api/')) {
    if (event.request.method === 'OPTIONS') {
      return new Response(null, {
        status: 200,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        }
      });
    }
  }
  
  const response = await resolve(event);
  
  if (event.url.pathname.startsWith('/api/')) {
    response.headers.set('Access-Control-Allow-Origin', '*');
  }
  
  return response;
};

export const handle = sequence(authHook, loggingHook, corsHook);

export const handleError: HandleServerError = ({ error, event }) => {
  logger.error(`Error in ${event.url.pathname}:`, error);
  
  return {
    message: 'An unexpected error occurred',
    code: error?.code || 'UNKNOWN'
  };
};
```

### Client Hooks (hooks.client.ts)

```typescript
import type { HandleClientError } from '@sveltejs/kit';
import { logger } from '$lib/utils/logger';
import { notificationStore } from '$stores/notifications';

export const handleError: HandleClientError = ({ error, event }) => {
  logger.error(`Client error in ${event.url.pathname}:`, error);
  
  // Show user-friendly error notification
  notificationStore.add({
    type: 'error',
    title: 'Something went wrong',
    message: 'Please try again or contact support if the problem persists.',
    duration: 5000
  });
  
  return {
    message: 'An unexpected error occurred',
    code: error?.code || 'UNKNOWN'
  };
};
```

## Performance Optimization

### Code Splitting and Lazy Loading

```typescript
// Lazy load React components
import { onMount } from 'svelte';

let ReactChart;

onMount(async () => {
  const module = await import('$lib/react/charts/LineChart');
  ReactChart = module.default;
});
```

### Preloading and Prefetching

```svelte
<script>
  import { preloadData, preloadCode } from '$app/navigation';
  
  // Preload data on hover
  function handleMouseEnter(repositoryId) {
    preloadData(`/repositories/${repositoryId}`);
  }
  
  // Preload code for likely navigation
  function handleFocus() {
    preloadCode('/dashboard');
  }
</script>

<a 
  href="/repositories/{repository.id}" 
  on:mouseenter={() => handleMouseEnter(repository.id)}
  on:focus={handleFocus}
>
  {repository.name}
</a>
```

This SvelteKit implementation provides a robust foundation for the GitInsight frontend, with proper routing, data loading, form handling, and performance optimizations.
