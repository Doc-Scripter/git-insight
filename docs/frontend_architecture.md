# Frontend Architecture Documentation

## Overview

The GitInsight frontend is built with SvelteKit as the primary framework, integrating React components where necessary for specific UI elements, and utilizing Shadcn UI components for a modern, customizable design system. This hybrid approach leverages the best of both ecosystems while maintaining performance and developer experience.

## Architecture Overview

### Technology Stack

- **Primary Framework**: SvelteKit 2.0+ with TypeScript
- **React Integration**: React 18+ for specific components
- **UI Library**: Shadcn UI (Svelte port) with Tailwind CSS
- **State Management**: Svelte stores + Zustand for React components
- **Routing**: SvelteKit file-based routing with dynamic routes
- **Build Tool**: Vite with SvelteKit adapter
- **Styling**: Tailwind CSS with custom design tokens
- **Icons**: Lucide icons (Svelte and React variants)
- **Charts**: Chart.js with Svelte wrappers
- **HTTP Client**: Fetch API with custom wrappers

### Frontend Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitInsight Frontend                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    User Interface Layer                     │  │
│  │                                                             │  │
│  │  ┌─────────────────┐              ┌─────────────────┐      │  │
│  │  │   SvelteKit     │              │   React         │      │  │
│  │  │   Components    │◄────────────►│   Components    │      │  │
│  │  │                 │              │                 │      │  │
│  │  │ • Pages         │              │ • Complex Widgets│     │  │
│  │  │ • Layouts       │              │ • Data Viz      │     │  │
│  │  │ • Basic UI      │              │ • Third-party   │     │  │
│  │  └─────────────────┘              └─────────────────┘      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                  Component Library Layer                    │  │
│  │                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │   Shadcn UI     │  │   Custom        │  │   Shared    │  │  │
│  │  │   Components    │  │   Components    │  │   Utilities │  │  │
│  │  │                 │  │                 │  │             │  │  │
│  │  │ • Buttons       │  │ • Repository    │  │ • API Client│  │  │
│  │  │ • Forms         │  │ • Dashboard     │  │ • Auth      │  │  │
│  │  │ • Navigation    │  │ • Charts        │  │ • Utils     │  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                    State Management Layer                   │  │
│  │                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │  Svelte Stores  │  │   Zustand       │  │   Local     │  │  │
│  │  │                 │  │   (React)       │  │   State     │  │  │
│  │  │ • User State    │  │                 │  │             │  │  │
│  │  │ • App State     │  │ • Complex State │  │ • Component │  │  │
│  │  │ • UI State      │  │ • React State   │  │ • Form Data │  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                      Data Layer                             │  │
│  │                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │   API Client    │  │   WebSocket     │  │   Cache     │  │  │
│  │  │                 │  │   Client        │  │   Layer     │  │  │
│  │  │ • REST APIs     │  │                 │  │             │  │  │
│  │  │ • Authentication│  │ • Real-time     │  │ • Browser   │  │  │
│  │  │ • Error Handling│  │ • Updates       │  │ • Session   │  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

### Recommended Directory Structure

```
frontend/
├── src/
│   ├── app.html                    # HTML template
│   ├── app.css                     # Global styles
│   ├── app.d.ts                    # TypeScript declarations
│   ├── hooks.client.ts             # Client-side hooks
│   ├── hooks.server.ts             # Server-side hooks
│   ├── routes/                     # SvelteKit routes
│   │   ├── +layout.svelte         # Root layout
│   │   ├── +layout.ts             # Layout data loading
│   │   ├── +page.svelte           # Home page
│   │   ├── +page.ts               # Page data loading
│   │   ├── auth/                  # Authentication routes
│   │   │   ├── login/
│   │   │   ├── callback/
│   │   │   └── logout/
│   │   ├── dashboard/             # Dashboard routes
│   │   │   ├── +page.svelte
│   │   │   └── +page.ts
│   │   ├── repositories/          # Repository routes
│   │   │   ├── +page.svelte       # Repository list
│   │   │   ├── [id]/              # Dynamic repository routes
│   │   │   │   ├── +page.svelte   # Repository details
│   │   │   │   ├── +page.ts
│   │   │   │   ├── insights/
│   │   │   │   ├── analysis/
│   │   │   │   └── settings/
│   │   │   └── add/
│   │   ├── search/                # Search functionality
│   │   ├── profile/               # User profile
│   │   └── api/                   # API routes (server-side)
│   ├── lib/                       # Shared libraries
│   │   ├── components/            # Svelte components
│   │   │   ├── ui/                # Shadcn UI components
│   │   │   │   ├── button/
│   │   │   │   ├── card/
│   │   │   │   ├── input/
│   │   │   │   ├── dialog/
│   │   │   │   └── index.ts
│   │   │   ├── layout/            # Layout components
│   │   │   │   ├── Header.svelte
│   │   │   │   ├── Sidebar.svelte
│   │   │   │   ├── Footer.svelte
│   │   │   │   └── Navigation.svelte
│   │   │   ├── dashboard/         # Dashboard components
│   │   │   │   ├── MetricsCard.svelte
│   │   │   │   ├── RecentActivity.svelte
│   │   │   │   └── QuickActions.svelte
│   │   │   ├── repository/        # Repository components
│   │   │   │   ├── RepositoryCard.svelte
│   │   │   │   ├── RepositoryList.svelte
│   │   │   │   ├── InsightChart.svelte
│   │   │   │   └── AnalysisStatus.svelte
│   │   │   └── forms/             # Form components
│   │   │       ├── RepositoryForm.svelte
│   │   │       ├── SearchForm.svelte
│   │   │       └── SettingsForm.svelte
│   │   ├── react/                 # React components
│   │   │   ├── charts/            # Chart components
│   │   │   │   ├── LineChart.tsx
│   │   │   │   ├── BarChart.tsx
│   │   │   │   ├── PieChart.tsx
│   │   │   │   └── HeatMap.tsx
│   │   │   ├── widgets/           # Complex widgets
│   │   │   │   ├── CodeQualityWidget.tsx
│   │   │   │   ├── TrendAnalysis.tsx
│   │   │   │   └── ContributorMap.tsx
│   │   │   └── integrations/      # Third-party integrations
│   │   │       ├── GitHubIntegration.tsx
│   │   │       └── MonacoEditor.tsx
│   │   ├── stores/                # Svelte stores
│   │   │   ├── auth.ts            # Authentication state
│   │   │   ├── user.ts            # User data
│   │   │   ├── repositories.ts    # Repository data
│   │   │   ├── ui.ts              # UI state
│   │   │   └── notifications.ts   # Notifications
│   │   ├── api/                   # API client
│   │   │   ├── client.ts          # Base API client
│   │   │   ├── auth.ts            # Auth API
│   │   │   ├── repositories.ts    # Repository API
│   │   │   ├── insights.ts        # Insights API
│   │   │   └── websocket.ts       # WebSocket client
│   │   ├── utils/                 # Utility functions
│   │   │   ├── auth.ts            # Auth utilities
│   │   │   ├── formatting.ts      # Data formatting
│   │   │   ├── validation.ts      # Form validation
│   │   │   ├── constants.ts       # App constants
│   │   │   └── helpers.ts         # General helpers
│   │   ├── types/                 # TypeScript types
│   │   │   ├── api.ts             # API types
│   │   │   ├── user.ts            # User types
│   │   │   ├── repository.ts      # Repository types
│   │   │   └── ui.ts              # UI types
│   │   └── styles/                # Styling
│   │       ├── globals.css        # Global styles
│   │       ├── components.css     # Component styles
│   │       └── themes/            # Theme definitions
│   │           ├── dark.css
│   │           └── light.css
│   └── static/                    # Static assets
│       ├── favicon.ico
│       ├── images/
│       ├── icons/
│       └── fonts/
├── tests/                         # Test files
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── docs/                          # Component documentation
├── package.json                   # Dependencies
├── svelte.config.js              # SvelteKit configuration
├── vite.config.ts                # Vite configuration
├── tailwind.config.js            # Tailwind configuration
├── tsconfig.json                 # TypeScript configuration
├── playwright.config.ts          # E2E test configuration
├── vitest.config.ts              # Unit test configuration
└── README.md                     # Frontend documentation
```

## Core Features

### SvelteKit Integration

- **File-based Routing**: Automatic route generation based on file structure
- **Server-Side Rendering**: SEO-friendly pages with fast initial loads
- **Progressive Enhancement**: Works without JavaScript, enhanced with it
- **API Routes**: Server-side API endpoints for backend integration
- **Load Functions**: Data fetching with automatic invalidation
- **Form Actions**: Server-side form handling with progressive enhancement

### React Component Integration

- **Selective Integration**: React components used for complex widgets and visualizations
- **State Bridge**: Seamless state sharing between Svelte and React
- **Performance Optimization**: Lazy loading and code splitting for React components
- **Event Handling**: Proper event propagation between frameworks
- **Styling Consistency**: Shared Tailwind classes and design tokens

### Shadcn UI Implementation

- **Component Library**: Pre-built, accessible UI components
- **Theming System**: Consistent design tokens and color schemes
- **Customization**: Easy component customization and extension
- **Accessibility**: WCAG compliant components out of the box
- **Dark Mode**: Built-in dark/light theme switching

## Key Design Principles

### Performance First

- **Code Splitting**: Automatic route-based code splitting
- **Lazy Loading**: Components and images loaded on demand
- **Optimized Builds**: Tree shaking and bundle optimization
- **Caching Strategy**: Intelligent caching of API responses and assets
- **Progressive Loading**: Skeleton screens and loading states

### Developer Experience

- **TypeScript**: Full type safety across the application
- **Hot Module Replacement**: Fast development with instant updates
- **Component Documentation**: Storybook integration for component development
- **Testing**: Comprehensive unit, integration, and E2E testing
- **Linting**: ESLint and Prettier for code quality

### User Experience

- **Responsive Design**: Mobile-first approach with adaptive layouts
- **Accessibility**: WCAG 2.1 AA compliance
- **Internationalization**: Multi-language support ready
- **Offline Support**: Service worker for offline functionality
- **Real-time Updates**: WebSocket integration for live data

## State Management Strategy

### Svelte Stores

- **Reactive State**: Automatic UI updates on state changes
- **Derived Stores**: Computed values from base stores
- **Custom Stores**: Domain-specific state management
- **Persistence**: Local storage integration for user preferences

### React State Integration

- **Zustand**: Lightweight state management for React components
- **State Bridge**: Custom hooks for Svelte-React state sharing
- **Context Providers**: React context for component trees
- **State Synchronization**: Automatic sync between frameworks

## API Integration

### HTTP Client

- **Fetch Wrapper**: Custom fetch wrapper with error handling
- **Authentication**: Automatic token management and refresh
- **Request Interceptors**: Logging, error handling, and retries
- **Response Caching**: Intelligent caching with invalidation
- **Type Safety**: Full TypeScript support for API responses

### WebSocket Integration

- **Real-time Updates**: Live repository analysis updates
- **Connection Management**: Automatic reconnection and error handling
- **Message Queuing**: Offline message queuing and replay
- **Event Handling**: Type-safe event handling and routing

## Related Documentation

For detailed information on specific aspects of the frontend architecture, refer to these comprehensive guides:

- **[SvelteKit Implementation](./frontend_sveltekit.md)** - SvelteKit configuration, routing, SSR, and core application structure
- **[React Integration](./frontend_react_integration.md)** - React component integration, state management, and interoperability
- **[Shadcn UI Components](./frontend_shadcn_ui.md)** - Component library integration, theming, and customization
- **[State Management](./frontend_state_management.md)** - State management patterns, stores, and data flow
- **[UI Components](./frontend_ui_components.md)** - Component documentation, props, and usage examples
- **[User Flows & Navigation](./frontend_user_flows.md)** - User journey implementation and navigation patterns

## Quick Start

### Prerequisites

```bash
# Required software
- Node.js 18+ with npm/yarn/pnpm
- Git for version control
```

### Development Setup

1. **Install Dependencies**
   ```bash
   cd frontend
   npm install  # or yarn install / pnpm install
   ```

2. **Environment Configuration**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your configuration
   ```

3. **Start Development Server**
   ```bash
   npm run dev
   # Frontend available at http://localhost:5173
   ```

4. **Build for Production**
   ```bash
   npm run build
   npm run preview  # Preview production build
   ```

This frontend architecture provides a solid foundation for building a modern, performant, and maintainable user interface for GitInsight, leveraging the best features of both SvelteKit and React ecosystems.
