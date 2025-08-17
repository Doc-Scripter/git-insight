# Shadcn UI Components Documentation

## Overview

GitInsight uses Shadcn UI components ported to Svelte, providing a modern, accessible, and highly customizable component library. This document covers the integration, theming, customization, and usage patterns for Shadcn UI components within the SvelteKit application.

## Shadcn UI Integration

### Installation and Setup

```bash
# Install Shadcn UI for Svelte
npx shadcn-svelte@latest init

# Add specific components
npx shadcn-svelte@latest add button
npx shadcn-svelte@latest add card
npx shadcn-svelte@latest add input
npx shadcn-svelte@latest add dialog
npx shadcn-svelte@latest add dropdown-menu
npx shadcn-svelte@latest add table
npx shadcn-svelte@latest add tabs
npx shadcn-svelte@latest add badge
npx shadcn-svelte@latest add progress
npx shadcn-svelte@latest add toast
```

### Configuration Files

#### components.json

```json
{
  "$schema": "https://shadcn-svelte.com/schema.json",
  "style": "default",
  "rsc": false,
  "tsx": false,
  "tailwind": {
    "config": "tailwind.config.js",
    "css": "src/app.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "$lib/components",
    "utils": "$lib/utils"
  }
}
```

#### Tailwind Configuration

```javascript
// tailwind.config.js
import { fontFamily } from "tailwindcss/defaultTheme";

/** @type {import('tailwindcss').Config} */
const config = {
  darkMode: ["class"],
  content: ["./src/**/*.{html,js,svelte,ts}"],
  safelist: ["dark"],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px"
      }
    },
    extend: {
      colors: {
        border: "hsl(var(--border) / <alpha-value>)",
        input: "hsl(var(--input) / <alpha-value>)",
        ring: "hsl(var(--ring) / <alpha-value>)",
        background: "hsl(var(--background) / <alpha-value>)",
        foreground: "hsl(var(--foreground) / <alpha-value>)",
        primary: {
          DEFAULT: "hsl(var(--primary) / <alpha-value>)",
          foreground: "hsl(var(--primary-foreground) / <alpha-value>)"
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary) / <alpha-value>)",
          foreground: "hsl(var(--secondary-foreground) / <alpha-value>)"
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive) / <alpha-value>)",
          foreground: "hsl(var(--destructive-foreground) / <alpha-value>)"
        },
        muted: {
          DEFAULT: "hsl(var(--muted) / <alpha-value>)",
          foreground: "hsl(var(--muted-foreground) / <alpha-value>)"
        },
        accent: {
          DEFAULT: "hsl(var(--accent) / <alpha-value>)",
          foreground: "hsl(var(--accent-foreground) / <alpha-value>)"
        },
        popover: {
          DEFAULT: "hsl(var(--popover) / <alpha-value>)",
          foreground: "hsl(var(--popover-foreground) / <alpha-value>)"
        },
        card: {
          DEFAULT: "hsl(var(--card) / <alpha-value>)",
          foreground: "hsl(var(--card-foreground) / <alpha-value>)"
        }
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)"
      },
      fontFamily: {
        sans: [...fontFamily.sans]
      }
    }
  }
};

export default config;
```

## Theme System

### CSS Variables (app.css)

```css
/* src/app.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 221.2 83.2% 53.3%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96%;
    --secondary-foreground: 222.2 84% 4.9%;
    --muted: 210 40% 96%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96%;
    --accent-foreground: 222.2 84% 4.9%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 221.2 83.2% 53.3%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 217.2 91.2% 59.8%;
    --primary-foreground: 222.2 84% 4.9%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 224.3 76.3% 94.1%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}

/* GitInsight specific theme extensions */
:root {
  --gitinsight-primary: 142 76% 36%;
  --gitinsight-secondary: 210 40% 96%;
  --gitinsight-success: 142 76% 36%;
  --gitinsight-warning: 38 92% 50%;
  --gitinsight-error: 0 84% 60%;
  --gitinsight-info: 221 83% 53%;
}

.dark {
  --gitinsight-primary: 142 70% 45%;
  --gitinsight-secondary: 217 32% 17%;
  --gitinsight-success: 142 70% 45%;
  --gitinsight-warning: 38 92% 50%;
  --gitinsight-error: 0 63% 31%;
  --gitinsight-info: 217 91% 60%;
}
```

### Theme Store

```typescript
// src/lib/stores/theme.ts
import { writable } from 'svelte/store';
import { browser } from '$app/environment';

type Theme = 'light' | 'dark' | 'system';

interface ThemeState {
  theme: Theme;
  isDark: boolean;
}

function createThemeStore() {
  const { subscribe, set, update } = writable<ThemeState>({
    theme: 'system',
    isDark: false
  });

  return {
    subscribe,
    
    initialize() {
      if (!browser) return;
      
      const stored = localStorage.getItem('theme') as Theme;
      const theme = stored || 'system';
      
      this.setTheme(theme);
    },
    
    setTheme(theme: Theme) {
      if (!browser) return;
      
      localStorage.setItem('theme', theme);
      
      let isDark = false;
      
      if (theme === 'dark') {
        isDark = true;
      } else if (theme === 'light') {
        isDark = false;
      } else {
        isDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      }
      
      document.documentElement.classList.toggle('dark', isDark);
      
      set({ theme, isDark });
    },
    
    toggle() {
      update(state => {
        const newTheme = state.isDark ? 'light' : 'dark';
        this.setTheme(newTheme);
        return state;
      });
    }
  };
}

export const themeStore = createThemeStore();
```

## Core Components

### Button Component Usage

```svelte
<!-- src/lib/components/examples/ButtonExamples.svelte -->
<script>
  import { Button } from "$lib/components/ui/button";
  import { Plus, Download, Settings } from "lucide-svelte";
</script>

<!-- Basic buttons -->
<div class="space-x-2">
  <Button>Default</Button>
  <Button variant="secondary">Secondary</Button>
  <Button variant="destructive">Destructive</Button>
  <Button variant="outline">Outline</Button>
  <Button variant="ghost">Ghost</Button>
  <Button variant="link">Link</Button>
</div>

<!-- Sizes -->
<div class="space-x-2">
  <Button size="sm">Small</Button>
  <Button size="default">Default</Button>
  <Button size="lg">Large</Button>
  <Button size="icon">
    <Settings class="h-4 w-4" />
  </Button>
</div>

<!-- With icons -->
<div class="space-x-2">
  <Button>
    <Plus class="mr-2 h-4 w-4" />
    Add Repository
  </Button>
  
  <Button variant="outline">
    <Download class="mr-2 h-4 w-4" />
    Export Data
  </Button>
</div>

<!-- Loading state -->
<Button disabled>
  <div class="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
  Loading...
</Button>
```

### Card Component Usage

```svelte
<!-- src/lib/components/examples/CardExamples.svelte -->
<script>
  import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { Badge } from "$lib/components/ui/badge";
  import { Star, GitFork, Eye } from "lucide-svelte";
</script>

<!-- Repository card -->
<Card class="w-full max-w-md">
  <CardHeader>
    <div class="flex items-start justify-between">
      <div>
        <CardTitle class="text-lg">awesome-project</CardTitle>
        <CardDescription>owner/awesome-project</CardDescription>
      </div>
      <Badge variant="secondary">Public</Badge>
    </div>
  </CardHeader>
  
  <CardContent>
    <p class="text-sm text-muted-foreground mb-4">
      A comprehensive toolkit for building modern web applications with SvelteKit and TypeScript.
    </p>
    
    <div class="flex items-center space-x-4 text-sm text-muted-foreground">
      <div class="flex items-center">
        <Star class="mr-1 h-3 w-3" />
        1,234
      </div>
      <div class="flex items-center">
        <GitFork class="mr-1 h-3 w-3" />
        567
      </div>
      <div class="flex items-center">
        <Eye class="mr-1 h-3 w-3" />
        89
      </div>
    </div>
    
    <div class="mt-4">
      <Badge variant="outline">TypeScript</Badge>
    </div>
  </CardContent>
  
  <CardFooter class="flex justify-between">
    <Button variant="outline" size="sm">View Details</Button>
    <Button size="sm">Analyze</Button>
  </CardFooter>
</Card>
```

### Form Components

```svelte
<!-- src/lib/components/forms/RepositoryForm.svelte -->
<script lang="ts">
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Textarea } from "$lib/components/ui/textarea";
  import { Checkbox } from "$lib/components/ui/checkbox";
  import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "$lib/components/ui/card";
  import { Alert, AlertDescription } from "$lib/components/ui/alert";
  import { AlertCircle } from "lucide-svelte";
  
  export let form: any = null;
  export let loading = false;
  
  let githubUrl = '';
  let autoAnalyze = true;
  let isPrivate = false;
  let description = '';
</script>

<Card class="w-full max-w-2xl">
  <CardHeader>
    <CardTitle>Add Repository</CardTitle>
    <CardDescription>
      Add a GitHub repository to start analyzing its code quality, security, and performance.
    </CardDescription>
  </CardHeader>
  
  <CardContent>
    <form method="POST" class="space-y-6">
      {#if form?.error}
        <Alert variant="destructive">
          <AlertCircle class="h-4 w-4" />
          <AlertDescription>{form.error}</AlertDescription>
        </Alert>
      {/if}
      
      <div class="space-y-2">
        <Label for="githubUrl">GitHub Repository URL</Label>
        <Input
          id="githubUrl"
          name="githubUrl"
          type="url"
          placeholder="https://github.com/owner/repository"
          bind:value={githubUrl}
          class={form?.errors?.githubUrl ? 'border-destructive' : ''}
          required
        />
        {#if form?.errors?.githubUrl}
          <p class="text-sm text-destructive">{form.errors.githubUrl[0]}</p>
        {/if}
      </div>
      
      <div class="space-y-2">
        <Label for="description">Description (Optional)</Label>
        <Textarea
          id="description"
          name="description"
          placeholder="Brief description of the repository..."
          bind:value={description}
          rows={3}
        />
      </div>
      
      <div class="space-y-4">
        <div class="flex items-center space-x-2">
          <Checkbox
            id="autoAnalyze"
            name="autoAnalyze"
            bind:checked={autoAnalyze}
          />
          <Label for="autoAnalyze" class="text-sm font-normal">
            Start analysis automatically after adding
          </Label>
        </div>
        
        <div class="flex items-center space-x-2">
          <Checkbox
            id="isPrivate"
            name="isPrivate"
            bind:checked={isPrivate}
          />
          <Label for="isPrivate" class="text-sm font-normal">
            This is a private repository
          </Label>
        </div>
      </div>
      
      <div class="flex justify-end space-x-2">
        <Button variant="outline" type="button">Cancel</Button>
        <Button type="submit" disabled={loading}>
          {#if loading}
            <div class="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
          {/if}
          Add Repository
        </Button>
      </div>
    </form>
  </CardContent>
</Card>
```

### Dialog Component

```svelte
<!-- src/lib/components/dialogs/ConfirmDialog.svelte -->
<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { Button } from "$lib/components/ui/button";
  import {
    Dialog,
    DialogContent,
    DialogDescription,
    DialogFooter,
    DialogHeader,
    DialogTitle,
  } from "$lib/components/ui/dialog";
  import { AlertTriangle } from "lucide-svelte";
  
  export let open = false;
  export let title = "Confirm Action";
  export let description = "Are you sure you want to proceed?";
  export let confirmText = "Confirm";
  export let cancelText = "Cancel";
  export let variant: "default" | "destructive" = "default";
  export let loading = false;
  
  const dispatch = createEventDispatcher();
  
  function handleConfirm() {
    dispatch('confirm');
  }
  
  function handleCancel() {
    dispatch('cancel');
    open = false;
  }
</script>

<Dialog bind:open>
  <DialogContent class="sm:max-w-md">
    <DialogHeader>
      <div class="flex items-center space-x-2">
        {#if variant === "destructive"}
          <AlertTriangle class="h-5 w-5 text-destructive" />
        {/if}
        <DialogTitle>{title}</DialogTitle>
      </div>
      <DialogDescription>
        {description}
      </DialogDescription>
    </DialogHeader>
    
    <DialogFooter class="flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2">
      <Button variant="outline" on:click={handleCancel} disabled={loading}>
        {cancelText}
      </Button>
      <Button 
        variant={variant} 
        on:click={handleConfirm} 
        disabled={loading}
      >
        {#if loading}
          <div class="mr-2 h-4 w-4 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
        {/if}
        {confirmText}
      </Button>
    </DialogFooter>
  </DialogContent>
</Dialog>
```

## Custom Component Extensions

### GitInsight Specific Components

```svelte
<!-- src/lib/components/gitinsight/RepositoryCard.svelte -->
<script lang="ts">
  import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { Badge } from "$lib/components/ui/badge";
  import { Progress } from "$lib/components/ui/progress";
  import { Star, GitFork, Eye, Clock, TrendingUp } from "lucide-svelte";
  import type { Repository } from "$types/repository";
  
  export let repository: Repository;
  export let showAnalysis = true;
  export let compact = false;
  
  $: analysisScore = repository.insights?.reduce((acc, insight) => 
    acc + insight.confidence_score, 0) / (repository.insights?.length || 1) * 100;
</script>

<Card class="group hover:shadow-md transition-shadow duration-200" class:compact>
  <CardHeader class={compact ? "pb-2" : ""}>
    <div class="flex items-start justify-between">
      <div class="min-w-0 flex-1">
        <CardTitle class="text-lg truncate">
          <a href="/repositories/{repository.id}" class="hover:underline">
            {repository.name}
          </a>
        </CardTitle>
        <CardDescription class="truncate">
          {repository.full_name}
        </CardDescription>
      </div>
      <div class="flex items-center space-x-2">
        <Badge variant={repository.is_private ? "secondary" : "outline"}>
          {repository.is_private ? "Private" : "Public"}
        </Badge>
        {#if repository.analysis_status === "completed"}
          <Badge variant="default" class="bg-green-500">
            <TrendingUp class="mr-1 h-3 w-3" />
            Analyzed
          </Badge>
        {/if}
      </div>
    </div>
  </CardHeader>
  
  <CardContent class={compact ? "py-2" : ""}>
    {#if repository.description && !compact}
      <p class="text-sm text-muted-foreground mb-4 line-clamp-2">
        {repository.description}
      </p>
    {/if}
    
    <div class="flex items-center space-x-4 text-sm text-muted-foreground mb-4">
      <div class="flex items-center">
        <Star class="mr-1 h-3 w-3" />
        {repository.stars.toLocaleString()}
      </div>
      <div class="flex items-center">
        <GitFork class="mr-1 h-3 w-3" />
        {repository.forks.toLocaleString()}
      </div>
      <div class="flex items-center">
        <Eye class="mr-1 h-3 w-3" />
        {repository.watchers.toLocaleString()}
      </div>
      {#if repository.last_analyzed}
        <div class="flex items-center">
          <Clock class="mr-1 h-3 w-3" />
          {new Date(repository.last_analyzed).toLocaleDateString()}
        </div>
      {/if}
    </div>
    
    <div class="flex items-center justify-between">
      {#if repository.language}
        <Badge variant="outline" class="text-xs">
          {repository.language}
        </Badge>
      {/if}
      
      {#if showAnalysis && repository.analysis_status === "completed"}
        <div class="flex items-center space-x-2 text-sm">
          <span class="text-muted-foreground">Quality:</span>
          <Progress value={analysisScore} class="w-16 h-2" />
          <span class="text-xs font-medium">{Math.round(analysisScore)}%</span>
        </div>
      {/if}
    </div>
  </CardContent>
  
  {#if !compact}
    <CardFooter class="flex justify-between">
      <Button variant="outline" size="sm" href="/repositories/{repository.id}">
        View Details
      </Button>
      {#if repository.analysis_status !== "in_progress"}
        <Button size="sm" href="/repositories/{repository.id}/analysis">
          {repository.analysis_status === "completed" ? "Re-analyze" : "Analyze"}
        </Button>
      {:else}
        <Button size="sm" disabled>
          <div class="mr-2 h-3 w-3 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
          Analyzing...
        </Button>
      {/if}
    </CardFooter>
  {/if}
</Card>

<style>
  .compact {
    @apply p-3;
  }
  
  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
</style>
```

## Accessibility Features

### ARIA Labels and Screen Reader Support

```svelte
<!-- Example of accessible component usage -->
<script>
  import { Button } from "$lib/components/ui/button";
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Search, X } from "lucide-svelte";
  
  let searchQuery = '';
  let searching = false;
  
  function clearSearch() {
    searchQuery = '';
  }
</script>

<div class="relative">
  <Label for="search" class="sr-only">Search repositories</Label>
  <div class="relative">
    <Search class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
    <Input
      id="search"
      type="search"
      placeholder="Search repositories..."
      bind:value={searchQuery}
      class="pl-10 pr-10"
      aria-describedby="search-help"
    />
    {#if searchQuery}
      <Button
        variant="ghost"
        size="icon"
        class="absolute right-1 top-1/2 h-6 w-6 -translate-y-1/2"
        on:click={clearSearch}
        aria-label="Clear search"
      >
        <X class="h-3 w-3" />
      </Button>
    {/if}
  </div>
  <p id="search-help" class="sr-only">
    Search through your repositories by name, description, or language
  </p>
</div>
```

This Shadcn UI documentation provides comprehensive guidance for implementing and customizing the component library within GitInsight's SvelteKit application, ensuring consistency, accessibility, and maintainability.
