# GitInsight Backend Documentation

## Overview

This directory contains comprehensive documentation for the GitInsight backend services. The backend is built as a microservices architecture combining Python FastAPI and Go services to provide high-performance, scalable API endpoints and data processing capabilities.

## Documentation Structure

### Core Documentation

| Document | Description |
|----------|-------------|
| **[Backend Services Overview](./backend_services.md)** | Main overview of the entire backend architecture, service responsibilities, and core concepts |
| **[Python FastAPI Service](./backend_python_fastapi.md)** | Detailed documentation of the Python service including API endpoints, data processing, and AI/ML integration |
| **[Go Service](./backend_go_service.md)** | Complete documentation of the Go service covering high-performance endpoints and real-time operations |
| **[Database Architecture](./backend_database.md)** | PostgreSQL schema, models, migrations, and data access patterns |
| **[API Gateway & Communication](./backend_api_gateway.md)** | Service discovery, load balancing, and inter-service communication |
| **[Authentication & Authorization](./backend_authentication.md)** | OAuth2/JWT implementation and role-based access control |
| **[Data Flow & Business Logic](./backend_data_flow.md)** | Complete data pipeline from GitHub ingestion to insight presentation |

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitInsight Backend                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────┐  │
│  │   API Gateway   │    │  Load Balancer  │    │   Frontend  │  │
│  │   (Kong/Nginx)  │◄──►│                 │◄──►│ (SvelteKit) │  │
│  └─────────────────┘    └─────────────────┘    └─────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                Service Layer                                │  │
│  │                                                             │  │
│  │  ┌─────────────────┐              ┌─────────────────┐      │  │
│  │  │   Python API    │              │    Go API       │      │  │
│  │  │   (FastAPI)     │◄────────────►│   (Gin/Echo)    │      │  │
│  │  │                 │              │                 │      │  │
│  │  │ • Data Processing│              │ • High Performance│     │  │
│  │  │ • AI/ML Services │              │ • Real-time Ops  │     │  │
│  │  │ • GitHub API    │              │ • Caching        │     │  │
│  │  │ • Analysis Jobs │              │ • WebSockets     │     │  │
│  │  └─────────────────┘              └─────────────────┘      │  │
│  └─────────────────────────────────────────────────────────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │                Data & Infrastructure Layer                  │  │
│  │                                                             │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │  │
│  │  │ PostgreSQL  │  │    Redis    │  │     RabbitMQ        │  │  │
│  │  │ Database    │  │   Cache     │  │   Message Queue     │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Key Features

### Python FastAPI Service
- **Repository Analysis**: Comprehensive GitHub repository analysis
- **AI/ML Integration**: Code quality assessment, sentiment analysis, trend prediction
- **Data Processing**: Complex data transformations and aggregations
- **GitHub API Integration**: Rate-limited data ingestion from GitHub
- **Background Tasks**: Celery-based asynchronous job processing

### Go Service
- **High Performance**: Ultra-low latency API endpoints
- **Real-time Operations**: WebSocket connections for live updates
- **Caching Layer**: Redis-based caching for frequently accessed data
- **System Monitoring**: Health checks and metrics collection
- **Concurrent Processing**: Efficient handling of multiple requests

### Database Layer
- **PostgreSQL**: Primary data store with JSONB support
- **Optimized Schema**: Indexed tables for fast queries
- **Migration Management**: Alembic-based database migrations
- **Data Integrity**: Foreign key constraints and validation

### Security & Authentication
- **OAuth2 Integration**: GitHub OAuth for user authentication
- **JWT Tokens**: Secure session management
- **Role-Based Access Control**: Fine-grained permissions
- **API Key Authentication**: Programmatic access control

## Quick Start

### Prerequisites
```bash
# Required software
- Docker & Docker Compose
- Python 3.9+ with pip/pipenv
- Go 1.18+
- PostgreSQL 13+
- Redis 6+
- Node.js 16+ (for frontend)
```

### Development Setup

1. **Clone and Setup Infrastructure**
   ```bash
   git clone https://github.com/your-org/git-insight.git
   cd git-insight
   
   # Start infrastructure services
   docker-compose up -d postgres redis rabbitmq
   ```

2. **Python Service Setup**
   ```bash
   cd backend/python
   
   # Install dependencies
   pipenv install --dev
   pipenv shell
   
   # Setup database
   alembic upgrade head
   
   # Start service
   uvicorn app.main:app --reload --port 8000
   ```

3. **Go Service Setup**
   ```bash
   cd backend/go
   
   # Install dependencies
   go mod tidy
   
   # Start service
   go run cmd/server/main.go
   ```

4. **Verify Services**
   ```bash
   # Check service health
   curl http://localhost:8000/health  # Python API
   curl http://localhost:8080/health  # Go API
   
   # Check API documentation
   open http://localhost:8000/docs    # FastAPI docs
   ```

## API Endpoints

### Python FastAPI (Port 8000)
- `POST /api/v1/repositories` - Add repository for analysis
- `GET /api/v1/repositories/{id}` - Get repository details
- `POST /api/v1/repositories/{id}/analyze` - Trigger analysis
- `GET /api/v1/repositories/{id}/insights` - Get insights
- `POST /api/v1/ai/analyze-code` - AI code analysis

### Go API (Port 8080)
- `GET /api/v1/fast/repositories/{id}/summary` - Quick repository summary
- `GET /api/v1/fast/search` - Fast repository search
- `GET /api/v1/stream/repository/{id}/updates` - Real-time updates (WebSocket)
- `GET /health` - Service health check
- `GET /metrics` - Prometheus metrics

## Development Guidelines

### Code Standards
- **Python**: Black formatting, isort imports, mypy type checking
- **Go**: gofmt formatting, golint linting, go vet analysis
- **Testing**: Minimum 80% code coverage required
- **Documentation**: Comprehensive inline comments and API docs

### Git Workflow
1. Create feature branch from `main`
2. Implement changes with tests
3. Run linting and formatting
4. Submit pull request with description
5. Code review and approval
6. Merge and deploy

### Testing
```bash
# Python tests
cd backend/python
pipenv run pytest --cov=app tests/

# Go tests
cd backend/go
go test -v -cover ./...

# Integration tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

## Deployment

### Docker Deployment
```bash
# Build images
docker-compose build

# Deploy to staging
docker-compose -f docker-compose.staging.yml up -d

# Deploy to production
docker-compose -f docker-compose.prod.yml up -d
```

### Kubernetes Deployment
```bash
# Apply configurations
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployments.yaml
kubectl apply -f k8s/services.yaml
kubectl apply -f k8s/ingress.yaml
```

## Monitoring & Observability

### Health Checks
- **Liveness Probes**: Basic service availability
- **Readiness Probes**: Service ready to handle requests
- **Dependency Checks**: Database and cache connectivity

### Metrics Collection
- **Application Metrics**: Request rates, response times, error rates
- **Business Metrics**: Analysis completion rates, user engagement
- **Infrastructure Metrics**: CPU, memory, disk usage

### Logging
- **Structured Logging**: JSON format with correlation IDs
- **Log Levels**: DEBUG, INFO, WARN, ERROR, FATAL
- **Centralized Logging**: ELK stack or similar solution

## Troubleshooting

### Common Issues

1. **Port Conflicts**
   ```bash
   # Find process using port
   lsof -i :8000
   
   # Kill process
   kill -9 <PID>
   ```

2. **Database Connection Issues**
   ```bash
   # Check database status
   docker-compose ps db
   
   # View database logs
   docker-compose logs db
   ```

3. **Service Dependencies**
   ```bash
   # Restart all services
   docker-compose restart
   
   # Check service logs
   docker-compose logs python-api
   docker-compose logs go-api
   ```

## Contributing

Please read our [Contributing Guidelines](../CONTRIBUTING.md) and [Code of Conduct](../CODE_OF_CONDUCT.md) before contributing to the project.

### Getting Help

- **Documentation**: Check the relevant documentation files
- **Issues**: Create GitHub issues for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Code Review**: All changes require peer review

## License

This project is licensed under the MIT License - see the [LICENSE](../LICENSE) file for details.
