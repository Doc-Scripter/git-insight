# Python FastAPI Service Documentation

## Overview

The Python FastAPI service is the core backend component of GitInsight, responsible for repository analysis, AI/ML processing, and complex data operations. Built with FastAPI, it provides high-performance asynchronous API endpoints with automatic OpenAPI documentation.

## Service Architecture

### Technology Stack

- **Framework**: FastAPI 0.104+
- **ASGI Server**: Uvicorn
- **Database ORM**: SQLAlchemy 2.0+ with async support
- **Migration Tool**: Alembic
- **Task Queue**: Celery with Redis broker
- **AI/ML**: Transformers, scikit-learn, pandas
- **Validation**: Pydantic v2
- **Testing**: pytest with async support

### Project Structure

```
backend/python/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI application entry point
│   ├── config.py              # Configuration management
│   ├── dependencies.py        # Dependency injection
│   ├── middleware.py          # Custom middleware
│   ├── api/
│   │   ├── __init__.py
│   │   ├── v1/
│   │   │   ├── __init__.py
│   │   │   ├── endpoints/
│   │   │   │   ├── repositories.py
│   │   │   │   ├── analysis.py
│   │   │   │   ├── insights.py
│   │   │   │   ├── users.py
│   │   │   │   └── auth.py
│   │   │   └── router.py
│   │   └── deps.py
│   ├── core/
│   │   ├── __init__.py
│   │   ├── security.py        # Authentication & authorization
│   │   ├── database.py        # Database configuration
│   │   ├── cache.py           # Redis cache management
│   │   └── exceptions.py      # Custom exceptions
│   ├── models/
│   │   ├── __init__.py
│   │   ├── base.py           # Base model classes
│   │   ├── user.py           # User models
│   │   ├── repository.py     # Repository models
│   │   ├── insight.py        # Insight models
│   │   └── analysis.py       # Analysis job models
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── user.py           # User Pydantic schemas
│   │   ├── repository.py     # Repository schemas
│   │   ├── insight.py        # Insight schemas
│   │   └── analysis.py       # Analysis schemas
│   ├── services/
│   │   ├── __init__.py
│   │   ├── github.py         # GitHub API integration
│   │   ├── analysis.py       # Repository analysis logic
│   │   ├── ai_ml.py          # AI/ML processing
│   │   ├── insights.py       # Insight generation
│   │   └── notifications.py  # User notifications
│   ├── tasks/
│   │   ├── __init__.py
│   │   ├── celery_app.py     # Celery configuration
│   │   ├── analysis.py       # Background analysis tasks
│   │   └── github_sync.py    # GitHub data synchronization
│   └── utils/
│       ├── __init__.py
│       ├── logging.py        # Logging configuration
│       ├── metrics.py        # Metrics collection
│       └── helpers.py        # Utility functions
├── tests/
│   ├── __init__.py
│   ├── conftest.py           # Test configuration
│   ├── test_api/
│   ├── test_services/
│   └── test_models/
├── alembic/                  # Database migrations
├── requirements.txt          # Dependencies
├── requirements-dev.txt      # Development dependencies
├── Dockerfile               # Container configuration
└── docker-compose.yml      # Local development setup
```

## API Endpoints

### Repository Management

#### Create Repository
```http
POST /api/v1/repositories
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "github_url": "https://github.com/owner/repo",
  "auto_analyze": true,
  "notification_settings": {
    "email_updates": true,
    "webhook_url": "https://example.com/webhook"
  }
}
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "github_id": 123456789,
  "name": "repo",
  "full_name": "owner/repo",
  "description": "Repository description",
  "url": "https://github.com/owner/repo",
  "language": "Python",
  "stars": 1234,
  "forks": 567,
  "created_at": "2025-08-16T10:30:00Z",
  "analysis_status": "pending",
  "owner": {
    "id": "user-uuid",
    "username": "owner",
    "avatar_url": "https://github.com/avatars/owner"
  }
}
```

#### Get Repository Details
```http
GET /api/v1/repositories/{repository_id}
Authorization: Bearer <jwt_token>
```

#### Update Repository Settings
```http
PUT /api/v1/repositories/{repository_id}
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "auto_analyze": false,
  "notification_settings": {
    "email_updates": false
  }
}
```

#### Delete Repository
```http
DELETE /api/v1/repositories/{repository_id}
Authorization: Bearer <jwt_token>
```

### Analysis Operations

#### Trigger Repository Analysis
```http
POST /api/v1/repositories/{repository_id}/analyze
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "analysis_type": "full",
  "options": {
    "include_code_quality": true,
    "include_security_scan": true,
    "include_dependency_analysis": true,
    "ai_insights": true
  }
}
```

**Response:**
```json
{
  "job_id": "analysis-job-uuid",
  "status": "queued",
  "estimated_duration": "5-10 minutes",
  "created_at": "2025-08-16T10:30:00Z"
}
```

#### Get Analysis Status
```http
GET /api/v1/analysis/{job_id}/status
Authorization: Bearer <jwt_token>
```

#### Get Repository Insights
```http
GET /api/v1/repositories/{repository_id}/insights
Authorization: Bearer <jwt_token>
Query Parameters:
  - type: string (optional) - Filter by insight type
  - limit: int (default: 20) - Number of insights to return
  - offset: int (default: 0) - Pagination offset
```

### AI/ML Services

#### Analyze Code Quality
```http
POST /api/v1/ai/analyze-code
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "repository_id": "repo-uuid",
  "file_paths": ["src/main.py", "src/utils.py"],
  "analysis_types": ["complexity", "maintainability", "security"]
}
```

#### Generate Insights
```http
POST /api/v1/ai/generate-insights
Content-Type: application/json
Authorization: Bearer <jwt_token>

{
  "repository_id": "repo-uuid",
  "data_sources": ["commits", "issues", "pull_requests"],
  "insight_types": ["trends", "patterns", "recommendations"]
}
```

## Data Models

### SQLAlchemy Models

#### Repository Model
```python
from sqlalchemy import Column, String, Integer, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class Repository(BaseModel):
    __tablename__ = "repositories"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    github_id = Column(Integer, unique=True, nullable=False, index=True)
    name = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False, unique=True, index=True)
    description = Column(Text)
    url = Column(String(500), nullable=False)
    clone_url = Column(String(500), nullable=False)
    language = Column(String(50))
    stars = Column(Integer, default=0)
    forks = Column(Integer, default=0)
    watchers = Column(Integer, default=0)
    size = Column(Integer, default=0)
    last_analyzed = Column(DateTime(timezone=True))
    analysis_status = Column(String(20), default="pending")
    settings = Column(JSONB, default=dict)
    
    # Relationships
    owner_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    owner = relationship("User", back_populates="repositories")
    insights = relationship("Insight", back_populates="repository", cascade="all, delete-orphan")
    analysis_jobs = relationship("AnalysisJob", back_populates="repository")
```

#### Insight Model
```python
class Insight(BaseModel):
    __tablename__ = "insights"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    repository_id = Column(UUID(as_uuid=True), ForeignKey("repositories.id"), nullable=False)
    type = Column(String(50), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    confidence_score = Column(Float, nullable=False)
    data = Column(JSONB, nullable=False)
    model_version = Column(String(50))
    tags = Column(ARRAY(String), default=list)
    
    # Relationships
    repository = relationship("Repository", back_populates="insights")
```

### Pydantic Schemas

#### Repository Schemas
```python
from pydantic import BaseModel, HttpUrl, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class AnalysisStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"

class RepositoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    language: Optional[str] = None

class RepositoryCreate(RepositoryBase):
    github_url: HttpUrl
    auto_analyze: bool = True
    notification_settings: Optional[Dict[str, Any]] = None

class RepositoryUpdate(BaseModel):
    auto_analyze: Optional[bool] = None
    notification_settings: Optional[Dict[str, Any]] = None

class RepositoryResponse(RepositoryBase):
    id: UUID
    github_id: int
    full_name: str
    url: str
    stars: int
    forks: int
    watchers: int
    size: int
    created_at: datetime
    updated_at: datetime
    last_analyzed: Optional[datetime]
    analysis_status: AnalysisStatus
    owner: "UserResponse"
    
    class Config:
        from_attributes = True
```

## Service Layer

### GitHub Integration Service

```python
import httpx
from typing import Optional, Dict, Any
from app.core.config import settings
from app.schemas.repository import GitHubRepositoryData

class GitHubService:
    def __init__(self):
        self.base_url = "https://api.github.com"
        self.headers = {
            "Authorization": f"token {settings.GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json"
        }
    
    async def get_repository(self, owner: str, repo: str) -> Optional[GitHubRepositoryData]:
        """Fetch repository data from GitHub API."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/repos/{owner}/{repo}",
                headers=self.headers
            )
            if response.status_code == 200:
                return GitHubRepositoryData(**response.json())
            return None
    
    async def get_commits(self, owner: str, repo: str, since: Optional[str] = None) -> List[Dict[str, Any]]:
        """Fetch repository commits."""
        params = {"per_page": 100}
        if since:
            params["since"] = since
            
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/repos/{owner}/{repo}/commits",
                headers=self.headers,
                params=params
            )
            return response.json() if response.status_code == 200 else []
    
    async def get_issues(self, owner: str, repo: str, state: str = "all") -> List[Dict[str, Any]]:
        """Fetch repository issues."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{self.base_url}/repos/{owner}/{repo}/issues",
                headers=self.headers,
                params={"state": state, "per_page": 100}
            )
            return response.json() if response.status_code == 200 else []
```

### Analysis Service

```python
from typing import List, Dict, Any
from app.models.repository import Repository
from app.models.insight import Insight
from app.services.github import GitHubService
from app.services.ai_ml import AIMLService

class AnalysisService:
    def __init__(self):
        self.github_service = GitHubService()
        self.ai_service = AIMLService()
    
    async def analyze_repository(self, repository: Repository, options: Dict[str, Any]) -> List[Insight]:
        """Perform comprehensive repository analysis."""
        insights = []
        
        # Fetch GitHub data
        github_data = await self._fetch_github_data(repository)
        
        # Code quality analysis
        if options.get("include_code_quality", True):
            code_insights = await self._analyze_code_quality(repository, github_data)
            insights.extend(code_insights)
        
        # Security analysis
        if options.get("include_security_scan", True):
            security_insights = await self._analyze_security(repository, github_data)
            insights.extend(security_insights)
        
        # AI-powered insights
        if options.get("ai_insights", True):
            ai_insights = await self._generate_ai_insights(repository, github_data)
            insights.extend(ai_insights)
        
        return insights
    
    async def _fetch_github_data(self, repository: Repository) -> Dict[str, Any]:
        """Fetch comprehensive GitHub data for analysis."""
        owner, repo_name = repository.full_name.split("/")
        
        return {
            "commits": await self.github_service.get_commits(owner, repo_name),
            "issues": await self.github_service.get_issues(owner, repo_name),
            "pull_requests": await self.github_service.get_pull_requests(owner, repo_name),
            "contributors": await self.github_service.get_contributors(owner, repo_name)
        }
```

## Background Tasks

### Celery Configuration

```python
from celery import Celery
from app.core.config import settings

celery_app = Celery(
    "gitinsight",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.tasks.analysis", "app.tasks.github_sync"]
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 minutes
    task_soft_time_limit=25 * 60,  # 25 minutes
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
)
```

### Analysis Tasks

```python
from celery import current_task
from app.tasks.celery_app import celery_app
from app.services.analysis import AnalysisService
from app.models.repository import Repository
from app.core.database import get_db

@celery_app.task(bind=True)
def analyze_repository_task(self, repository_id: str, options: dict):
    """Background task for repository analysis."""
    try:
        # Update task status
        current_task.update_state(state="PROGRESS", meta={"step": "initializing"})
        
        # Get repository from database
        db = next(get_db())
        repository = db.query(Repository).filter(Repository.id == repository_id).first()
        
        if not repository:
            raise ValueError(f"Repository {repository_id} not found")
        
        # Perform analysis
        analysis_service = AnalysisService()
        current_task.update_state(state="PROGRESS", meta={"step": "analyzing"})
        
        insights = await analysis_service.analyze_repository(repository, options)
        
        # Save insights to database
        current_task.update_state(state="PROGRESS", meta={"step": "saving_results"})
        
        for insight_data in insights:
            insight = Insight(**insight_data, repository_id=repository_id)
            db.add(insight)
        
        repository.analysis_status = "completed"
        repository.last_analyzed = datetime.utcnow()
        db.commit()
        
        return {"status": "completed", "insights_count": len(insights)}
        
    except Exception as exc:
        repository.analysis_status = "failed"
        db.commit()
        raise self.retry(exc=exc, countdown=60, max_retries=3)
```

## Testing

### Test Configuration

```python
import pytest
import asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from app.main import app
from app.core.database import get_db
from app.core.config import settings

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
async def async_client():
    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

@pytest.fixture
async def test_db():
    engine = create_async_engine(settings.TEST_DATABASE_URL)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async with AsyncSession(engine) as session:
        yield session
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
```

### API Tests

```python
import pytest
from httpx import AsyncClient

class TestRepositoryAPI:
    async def test_create_repository(self, async_client: AsyncClient, auth_headers):
        response = await async_client.post(
            "/api/v1/repositories",
            json={
                "github_url": "https://github.com/test/repo",
                "auto_analyze": True
            },
            headers=auth_headers
        )
        assert response.status_code == 201
        data = response.json()
        assert data["name"] == "repo"
        assert data["full_name"] == "test/repo"
    
    async def test_get_repository(self, async_client: AsyncClient, test_repository, auth_headers):
        response = await async_client.get(
            f"/api/v1/repositories/{test_repository.id}",
            headers=auth_headers
        )
        assert response.status_code == 200
        data = response.json()
        assert data["id"] == str(test_repository.id)
```

This documentation provides comprehensive coverage of the Python FastAPI service implementation. The service handles core business logic, AI/ML processing, and complex data operations while maintaining high performance and scalability.
