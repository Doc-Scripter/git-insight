# Backend Services Documentation

## Overview

The GitInsight backend is designed as a microservices architecture combining Python FastAPI and Go services to provide high-performance, scalable API endpoints and data processing capabilities. This document provides comprehensive documentation for all backend services, their interactions, and implementation details.

## Architecture Overview

### Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Gateway   │    │  Load Balancer  │    │   Frontend      │
│   (Go/Nginx)    │    │                 │    │   (SvelteKit)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Python API    │    │   Go API        │    │   Auth Service  │
│   (FastAPI)     │    │   (Gin/Echo)    │    │   (Go/Python)   │
│   Port: 8000    │    │   Port: 8080    │    │   Port: 8001    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   Redis Cache   │    │   Message Queue │
│   Database      │    │                 │    │   (RabbitMQ)    │
│   Port: 5432    │    │   Port: 6379    │    │   Port: 5672    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Core Services

1. **Python FastAPI Service** - Primary API service for data processing and AI/ML operations
2. **Go API Service** - High-performance endpoints for real-time operations
3. **Authentication Service** - OAuth2/JWT authentication and authorization
4. **GitHub Integration Service** - Data ingestion from GitHub API
5. **AI/ML Processing Service** - Insight generation and analysis

## Service Responsibilities

### Python FastAPI Service (Port 8000)

**Primary Responsibilities:**
- Repository analysis and insight generation
- AI/ML model integration and inference
- Complex data processing and aggregation
- Database operations and ORM management
- GitHub API integration and data ingestion

**Key Features:**
- Asynchronous request handling
- Pydantic data validation
- SQLAlchemy ORM integration
- Celery task queue integration
- OpenAPI/Swagger documentation

### Go API Service (Port 8080)

**Primary Responsibilities:**
- High-performance read operations
- Real-time data streaming
- Caching layer management
- System health monitoring
- Metrics collection and reporting

**Key Features:**
- Ultra-low latency responses
- Concurrent request handling
- Memory-efficient operations
- Built-in health checks
- Prometheus metrics integration

## API Endpoints Overview

### Python FastAPI Endpoints

#### Repository Management
- `POST /api/v1/repositories` - Add repository for analysis
- `GET /api/v1/repositories/{repo_id}` - Get repository details
- `PUT /api/v1/repositories/{repo_id}` - Update repository settings
- `DELETE /api/v1/repositories/{repo_id}` - Remove repository

#### Analysis Operations
- `POST /api/v1/repositories/{repo_id}/analyze` - Trigger repository analysis
- `GET /api/v1/repositories/{repo_id}/insights` - Get analysis insights
- `GET /api/v1/repositories/{repo_id}/metrics` - Get repository metrics
- `GET /api/v1/repositories/{repo_id}/trends` - Get trend analysis

#### AI/ML Services
- `POST /api/v1/ai/analyze-code` - Analyze code quality
- `POST /api/v1/ai/sentiment-analysis` - Analyze commit sentiment
- `POST /api/v1/ai/predict-trends` - Generate trend predictions
- `GET /api/v1/ai/models` - List available AI models

### Go API Endpoints

#### High-Performance Queries
- `GET /api/v1/fast/repositories/{repo_id}/summary` - Quick repository summary
- `GET /api/v1/fast/search` - Fast repository search
- `GET /api/v1/fast/leaderboard` - Repository rankings
- `GET /api/v1/fast/trending` - Trending repositories

#### Real-time Operations
- `GET /api/v1/stream/repository/{repo_id}/updates` - Real-time updates (WebSocket)
- `GET /api/v1/stream/global/activity` - Global activity stream
- `GET /api/v1/stream/user/{user_id}/feed` - User activity feed

#### System Operations
- `GET /health` - Service health check
- `GET /metrics` - Prometheus metrics
- `GET /api/v1/system/status` - System status
- `GET /api/v1/system/stats` - Performance statistics

## Data Models

### Core Entities

#### Repository Model
```python
class Repository(BaseModel):
    id: UUID
    github_id: int
    name: str
    full_name: str
    description: Optional[str]
    url: str
    clone_url: str
    language: Optional[str]
    stars: int
    forks: int
    watchers: int
    size: int
    created_at: datetime
    updated_at: datetime
    last_analyzed: Optional[datetime]
    analysis_status: AnalysisStatus
    owner: User
    insights: List[Insight]
```

#### Insight Model
```python
class Insight(BaseModel):
    id: UUID
    repository_id: UUID
    type: InsightType
    title: str
    description: str
    confidence_score: float
    data: Dict[str, Any]
    generated_at: datetime
    model_version: str
    tags: List[str]
```

#### User Model
```python
class User(BaseModel):
    id: UUID
    github_id: int
    username: str
    email: Optional[str]
    avatar_url: Optional[str]
    name: Optional[str]
    bio: Optional[str]
    location: Optional[str]
    company: Optional[str]
    created_at: datetime
    last_login: Optional[datetime]
    subscription_tier: SubscriptionTier
    followed_repositories: List[Repository]
```

## Database Schema

### Tables Overview

1. **users** - User account information
2. **repositories** - Repository metadata and status
3. **insights** - Generated insights and analysis results
4. **analysis_jobs** - Background job tracking
5. **user_repository_follows** - User-repository relationships
6. **api_keys** - API authentication tokens
7. **audit_logs** - System activity logging

### Key Relationships

- Users can follow multiple repositories (many-to-many)
- Repositories have multiple insights (one-to-many)
- Analysis jobs are linked to repositories (one-to-many)
- Users can have multiple API keys (one-to-many)

## Service Communication

### Inter-Service Communication Patterns

1. **Synchronous HTTP** - Direct API calls between services
2. **Asynchronous Messaging** - RabbitMQ for background tasks
3. **Event Streaming** - Real-time updates via WebSockets
4. **Shared Cache** - Redis for cross-service data sharing

### Message Queue Topics

- `repository.analysis.requested` - New analysis job
- `repository.analysis.completed` - Analysis finished
- `repository.insights.generated` - New insights available
- `user.repository.followed` - User followed repository
- `system.health.check` - Health monitoring events

## Authentication & Authorization

### OAuth2 Flow

1. User initiates GitHub OAuth
2. GitHub redirects with authorization code
3. Backend exchanges code for access token
4. JWT token generated for session management
5. Subsequent requests use JWT bearer token

### Role-Based Access Control (RBAC)

#### Roles
- **Guest** - Read-only access to public data
- **User** - Full access to personal data and insights
- **Premium** - Enhanced features and higher rate limits
- **Admin** - System administration capabilities

#### Permissions
- `repository:read` - View repository data
- `repository:analyze` - Trigger analysis
- `insights:read` - Access insights
- `insights:export` - Export insights data
- `admin:users` - Manage users
- `admin:system` - System administration

## Error Handling

### Standard Error Response Format

```json
{
  "error": {
    "code": "REPOSITORY_NOT_FOUND",
    "message": "Repository with ID 12345 not found",
    "details": {
      "repository_id": "12345",
      "timestamp": "2025-08-16T10:30:00Z"
    },
    "trace_id": "abc123def456"
  }
}
```

### Error Codes

- `VALIDATION_ERROR` - Request validation failed
- `AUTHENTICATION_REQUIRED` - Authentication needed
- `AUTHORIZATION_DENIED` - Insufficient permissions
- `REPOSITORY_NOT_FOUND` - Repository doesn't exist
- `ANALYSIS_IN_PROGRESS` - Analysis already running
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `INTERNAL_SERVER_ERROR` - Unexpected server error

## Performance Considerations

### Caching Strategy

1. **Application Cache** - Redis for frequently accessed data
2. **Database Query Cache** - PostgreSQL query result caching
3. **CDN Cache** - Static asset and API response caching
4. **Browser Cache** - Client-side caching headers

### Rate Limiting

- **Guest Users**: 100 requests/hour
- **Authenticated Users**: 1000 requests/hour
- **Premium Users**: 5000 requests/hour
- **API Keys**: Configurable limits per key

### Database Optimization

- Indexed columns for common queries
- Connection pooling for efficient resource usage
- Read replicas for scaling read operations
- Partitioning for large tables (insights, audit_logs)

## Monitoring & Observability

### Health Checks

Each service exposes health endpoints:
- `/health` - Basic liveness check
- `/health/ready` - Readiness check with dependencies
- `/health/detailed` - Comprehensive health status

### Metrics Collection

- **Application Metrics** - Request rates, response times, error rates
- **Business Metrics** - Analysis completion rates, user engagement
- **Infrastructure Metrics** - CPU, memory, disk usage
- **Database Metrics** - Query performance, connection counts

### Logging

Structured logging with:
- Request/response logging
- Error tracking with stack traces
- Performance monitoring
- Security event logging
- Audit trail for data changes

## Deployment Architecture

### Container Strategy

Each service is containerized with:
- Multi-stage Docker builds for optimization
- Health check configurations
- Resource limits and requests
- Security scanning integration

### Kubernetes Deployment

- **Deployments** - Service replicas with rolling updates
- **Services** - Internal service discovery
- **Ingress** - External traffic routing
- **ConfigMaps** - Configuration management
- **Secrets** - Sensitive data management

### Environment Configuration

- **Development** - Single instance, local database
- **Staging** - Production-like setup for testing
- **Production** - Multi-instance, managed services

## Security Implementation

### Data Protection

- Encryption at rest for sensitive data
- TLS 1.3 for all network communication
- Input validation and sanitization
- SQL injection prevention via ORM
- XSS protection headers

### API Security

- JWT token validation
- Rate limiting per user/IP
- CORS configuration
- API key rotation
- Request signing for sensitive operations

### Infrastructure Security

- Network segmentation
- Firewall rules
- Regular security updates
- Vulnerability scanning
- Secrets management

## Development Guidelines

### Code Standards

- **Python**: Black formatting, isort imports, mypy type checking
- **Go**: gofmt formatting, golint linting, go vet analysis
- **Testing**: Minimum 80% code coverage
- **Documentation**: Inline comments and API documentation

### Git Workflow

1. Feature branches from main
2. Pull request with code review
3. Automated testing and security scans
4. Deployment to staging environment
5. Manual testing and approval
6. Merge and deploy to production

This documentation provides a comprehensive overview of the GitInsight backend services. For specific implementation details, refer to the individual service documentation sections that follow.

## Related Documentation

For detailed information on specific aspects of the backend services, refer to these comprehensive guides:

- **[Python FastAPI Service](./backend_python_fastapi.md)** - Detailed documentation of the Python FastAPI service including API endpoints, data processing logic, AI/ML integration, and database interactions
- **[Go Service](./backend_go_service.md)** - Complete documentation of the Go service covering high-performance API endpoints, system services, and integration patterns
- **[Database Architecture](./backend_database.md)** - PostgreSQL database schema, models, migrations, and data access patterns
- **[API Gateway & Service Communication](./backend_api_gateway.md)** - API gateway configuration, service discovery, load balancing, and inter-service communication patterns
- **[Authentication & Authorization](./backend_authentication.md)** - OAuth2/JWT implementation, role-based access control, and security patterns
- **[Data Flow & Business Logic](./backend_data_flow.md)** - Complete data flow from GitHub ingestion to insight presentation, including business logic and processing pipelines

## Quick Start Guide

### Prerequisites
- Docker and Docker Compose
- Python 3.9+ with pip/pipenv/poetry
- Go 1.18+
- PostgreSQL 13+
- Redis 6+

### Development Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/git-insight.git
   cd git-insight
   ```

2. **Start infrastructure services:**
   ```bash
   docker-compose up -d postgres redis rabbitmq
   ```

3. **Set up Python service:**
   ```bash
   cd backend/python
   pipenv install --dev
   pipenv shell
   alembic upgrade head
   uvicorn app.main:app --reload --port 8000
   ```

4. **Set up Go service:**
   ```bash
   cd backend/go
   go mod tidy
   go run cmd/server/main.go
   ```

5. **Verify services:**
   ```bash
   curl http://localhost:8000/health  # Python API
   curl http://localhost:8080/health  # Go API
   ```
