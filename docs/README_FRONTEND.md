# GitInsight Frontend Documentation

## Overview

This directory contains comprehensive documentation for the GitInsight frontend application. The frontend is built with SvelteKit as the primary framework, strategically integrating React components for specific use cases, and utilizing Shadcn UI components for a modern, accessible design system.

## Documentation Structure

### Core Documentation

| Document | Description |
|----------|-------------|
| **[Frontend Architecture](./frontend_architecture.md)** | Main overview of the frontend architecture, technology stack, and design principles |
| **[SvelteKit Implementation](./frontend_sveltekit.md)** | Detailed SvelteKit configuration, routing, SSR, and core application structure |
| **[React Integration](./frontend_react_integration.md)** | React component integration patterns, state management, and interoperability |
| **[Shadcn UI Components](./frontend_shadcn_ui.md)** | Component library integration, theming, customization, and usage patterns |
| **[State Management](./frontend_state_management.md)** | State management patterns, stores, data flow, and synchronization |
| **[UI Components](./frontend_ui_components.md)** | Component documentation, props, usage examples, and design system |
| **[User Flows & Navigation](./frontend_user_flows.md)** | User journey implementation and navigation patterns |

### Technology Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitInsight Frontend Stack                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                Framework Layer                              │  │
│  │                                                             │  │
│  │  ┌─────────────────┐              ┌─────────────────┐      │  │
│  │  │   SvelteKit     │              │     React       │      │  │
│  │  │   (Primary)     │◄────────────►│  (Selective)    │      │  │
│  │  │                 │              │                 │      │  │
│  │  │ • SSR/SPA       │              │ • Charts        │      │  │
│  │  │ • File Routing  │              │ • Widgets       │      │  │
│  │  │ • Load Functions│              │ • Integrations  │      │  │
│  │  └─────────────────┘              └─────────────────┘      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                  UI & Styling Layer                         │  │
│  │                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │   Shadcn UI     │  │  Tailwind CSS   │  │   Lucide    │  │  │
│  │  │   Components    │  │                 │  │    Icons    │  │  │
│  │  │                 │  │ • Utility First │  │             │  │  │
│  │  │ • Accessible    │  │ • Custom Tokens │  │ • SVG Icons │  │  │
│  │  │ • Customizable  │  │ • Dark/Light    │  │ • Tree Shake│  │  │
│  │  │ • Consistent    │  │ • Responsive    │  │ • Variants  │  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                State & Data Layer                           │  │
│  │                                                             │  │
│  │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │  │
│  │  │ Svelte Stores   │  │    Zustand      │  │   API       │  │  │
│  │  │                 │  │   (React)       │  │  Client     │  │  │
│  │  │ • Reactive      │  │                 │  │             │  │  │
│  │  │ • Persistent    │  │ • Lightweight   │  │ • Fetch API │  │  │
│  │  │ • Derived       │  │ • Middleware    │  │ • WebSocket │  │  │
│  │  │ • Custom        │  │ • DevTools      │  │ • Auth      │  │  │
│  │  └─────────────────┘  └─────────────────┘  └─────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### Hybrid Framework Approach
- **SvelteKit Primary**: Main application framework with SSR, routing, and form handling
- **React Integration**: Strategic use for complex visualizations and third-party integrations
- **Seamless Interop**: State synchronization and event handling between frameworks
- **Performance Optimized**: Code splitting and lazy loading for optimal bundle sizes

### Modern UI/UX
- **Shadcn UI**: Accessible, customizable component library
- **Dark/Light Themes**: System-aware theme switching with custom tokens
- **Responsive Design**: Mobile-first approach with adaptive layouts
- **Accessibility**: WCAG 2.1 AA compliance throughout the application

### Developer Experience
- **TypeScript**: Full type safety across the application
- **Hot Reload**: Fast development with instant updates
- **Component Docs**: Comprehensive component documentation and examples
- **Testing**: Unit, integration, and E2E testing strategies

## Quick Start

### Prerequisites

```bash
# Required software
- Node.js 18+ with npm/yarn/pnpm
- Git for version control
```

### Development Setup

1. **Clone and Install**
   ```bash
   git clone https://github.com/your-org/git-insight.git
   cd git-insight/frontend
   npm install  # or yarn/pnpm install
   ```

2. **Environment Configuration**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your configuration:
   # VITE_API_URL=http://localhost:8000
   # VITE_WS_URL=ws://localhost:8080
   # VITE_GITHUB_CLIENT_ID=your_github_client_id
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

## Project Structure

```
frontend/
├── src/
│   ├── routes/                     # SvelteKit routes
│   │   ├── +layout.svelte         # Root layout
│   │   ├── +page.svelte           # Home page
│   │   ├── auth/                  # Authentication routes
│   │   ├── dashboard/             # Dashboard routes
│   │   ├── repositories/          # Repository management
│   │   └── api/                   # Server-side API routes
│   ├── lib/
│   │   ├── components/            # Svelte components
│   │   │   ├── ui/                # Shadcn UI components
│   │   │   ├── layout/            # Layout components
│   │   │   ├── repository/        # Repository components
│   │   │   └── forms/             # Form components
│   │   ├── react/                 # React components
│   │   │   ├── charts/            # Chart components
│   │   │   ├── widgets/           # Complex widgets
│   │   │   └── integrations/      # Third-party integrations
│   │   ├── stores/                # Svelte stores
│   │   ├── api/                   # API client
│   │   ├── utils/                 # Utility functions
│   │   └── types/                 # TypeScript types
│   ├── app.html                   # HTML template
│   └── app.css                    # Global styles
├── static/                        # Static assets
├── tests/                         # Test files
├── docs/                          # Component documentation
└── package.json                   # Dependencies
```

## Core Concepts

### Component Architecture

```typescript
// Example component structure
interface ComponentProps {
  // Required props
  data: Repository[];
  
  // Optional props with defaults
  loading?: boolean;
  compact?: boolean;
  
  // Event handlers
  onSelect?: (repository: Repository) => void;
  onAnalyze?: (repositoryId: string) => void;
}

// Component implementation with proper typing
export let data: Repository[];
export let loading = false;
export let compact = false;

const dispatch = createEventDispatcher<{
  select: Repository;
  analyze: string;
}>();
```

### State Management Patterns

```typescript
// Svelte store example
export const repositoryStore = writable<RepositoryState>({
  repositories: [],
  selectedRepository: null,
  isLoading: false,
  error: null
});

// React store example (Zustand)
export const useChartStore = create<ChartState>((set) => ({
  charts: {},
  selectedChart: null,
  setChart: (id, config) => set(state => ({
    charts: { ...state.charts, [id]: config }
  }))
}));
```

### API Integration

```typescript
// API client with proper error handling
export class ApiClient {
  async getRepositories(params: RepositoryParams): Promise<Repository[]> {
    const response = await fetch('/api/repositories?' + new URLSearchParams(params));
    
    if (!response.ok) {
      throw new ApiError(response.status, await response.text());
    }
    
    return response.json();
  }
}
```

## User Experience

### Navigation Flow

1. **Landing Page** → Authentication → Dashboard
2. **Dashboard** → Repository Management → Analysis
3. **Analysis** → Insights → Reports → Sharing

### Key User Journeys

- **New User Onboarding**: GitHub OAuth → Repository Discovery → First Analysis
- **Repository Management**: Add → Configure → Analyze → Monitor
- **Insight Exploration**: View → Filter → Export → Share
- **Dashboard Overview**: Metrics → Recent Activity → Quick Actions

## Performance Optimization

### Code Splitting Strategy

```typescript
// Route-based code splitting (automatic)
// Component-based lazy loading
const LazyChart = lazy(() => import('$lib/react/charts/LineChart'));

// Dynamic imports for large dependencies
const monaco = await import('monaco-editor');
```

### Caching Strategy

- **API Response Caching**: Intelligent cache invalidation
- **Static Asset Caching**: Long-term caching with versioning
- **Component State Caching**: Persistent user preferences
- **Image Optimization**: WebP format with fallbacks

## Testing Strategy

### Test Types

```bash
# Unit tests
npm run test:unit

# Integration tests
npm run test:integration

# E2E tests
npm run test:e2e

# Component tests
npm run test:components

# All tests with coverage
npm run test:coverage
```

### Testing Tools

- **Vitest**: Fast unit testing with Vite integration
- **Testing Library**: Component testing utilities
- **Playwright**: End-to-end testing framework
- **MSW**: API mocking for tests

## Deployment

### Build Process

```bash
# Production build
npm run build

# Build analysis
npm run build:analyze

# Type checking
npm run check

# Linting and formatting
npm run lint
npm run format
```

### Deployment Targets

- **Vercel**: Recommended for SvelteKit applications
- **Netlify**: Alternative with edge functions support
- **Docker**: Containerized deployment option
- **Static Hosting**: Pre-rendered static site option

## Contributing

### Development Guidelines

1. **Code Style**: Follow ESLint and Prettier configurations
2. **Component Design**: Use composition over inheritance
3. **Accessibility**: Ensure WCAG 2.1 AA compliance
4. **Performance**: Optimize for Core Web Vitals
5. **Testing**: Maintain >80% code coverage

### Git Workflow

1. Create feature branch from `main`
2. Implement changes with tests
3. Run linting and type checking
4. Submit pull request with description
5. Code review and approval
6. Merge and deploy

## Troubleshooting

### Common Issues

1. **Build Errors**: Check TypeScript types and imports
2. **Hydration Mismatches**: Ensure SSR/client consistency
3. **State Synchronization**: Verify store subscriptions
4. **Performance Issues**: Use browser dev tools profiling

### Getting Help

- **Documentation**: Check the relevant documentation files
- **Component Library**: Browse Storybook for component examples
- **Issues**: Create GitHub issues for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.

---

This frontend documentation provides everything needed for developers to understand, contribute to, and deploy the GitInsight frontend application. The hybrid SvelteKit-React architecture ensures optimal performance while leveraging the best tools from both ecosystems.
