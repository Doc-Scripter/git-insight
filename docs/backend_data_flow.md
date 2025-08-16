# Data Flow and Business Logic Documentation

## Overview

This document describes the complete data flow within GitInsight, from GitHub data ingestion through AI/ML processing to insight presentation. The system follows a pipeline architecture that ensures data consistency, scalability, and real-time updates.

## Data Flow Architecture

### High-Level Data Pipeline

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub API    │    │  Data Ingestion │    │  Raw Data Store │
│                 │───►│    Service      │───►│   (PostgreSQL)  │
│ • Repositories  │    │                 │    │                 │
│ • Commits       │    │ • Rate Limiting │    │ • Repositories  │
│ • Issues        │    │ • Data Validation│    │ • Commits       │
│ • Pull Requests │    │ • Transformation │    │ • Issues        │
│ • Contributors  │    │ • Deduplication │    │ • Pull Requests │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                 │
                                 ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Message Queue │    │  AI/ML Pipeline │    │ Processed Data  │
│   (RabbitMQ)    │◄───│                 │───►│   (PostgreSQL)  │
│                 │    │ • Code Analysis │    │                 │
│ • Analysis Jobs │    │ • Sentiment     │    │ • Insights      │
│ • Notifications │    │ • Trend Predict │    │ • Metrics       │
│ • Cache Updates │    │ • Quality Score │    │ • Aggregations  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                 │
                                 ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Cache Layer   │    │   API Gateway   │    │   Frontend      │
│   (Redis)       │◄───│                 │───►│   (SvelteKit)   │
│                 │    │ • Authentication│    │                 │
│ • Query Results │    │ • Rate Limiting │    │ • Dashboards    │
│ • User Sessions │    │ • Load Balancing│    │ • Visualizations│
│ • Real-time Data│    │ • Response Cache│    │ • User Interface│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Data Ingestion Pipeline

### GitHub Data Collection

```python
# app/services/github_ingestion.py
import asyncio
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import httpx
from app.core.config import settings
from app.models.repository import Repository
from app.services.rate_limiter import GitHubRateLimiter

class GitHubIngestionService:
    def __init__(self):
        self.rate_limiter = GitHubRateLimiter()
        self.base_url = "https://api.github.com"
        self.headers = {
            "Authorization": f"token {settings.GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "GitInsight/1.0"
        }
    
    async def ingest_repository_data(self, repository: Repository) -> Dict[str, Any]:
        """Complete repository data ingestion pipeline."""
        owner, repo_name = repository.full_name.split("/")
        
        # Collect all data types in parallel
        tasks = [
            self.fetch_repository_metadata(owner, repo_name),
            self.fetch_commits(owner, repo_name, since=repository.last_analyzed),
            self.fetch_issues(owner, repo_name),
            self.fetch_pull_requests(owner, repo_name),
            self.fetch_contributors(owner, repo_name),
            self.fetch_releases(owner, repo_name),
            self.fetch_languages(owner, repo_name),
            self.fetch_topics(owner, repo_name)
        ]
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        return {
            "metadata": results[0] if not isinstance(results[0], Exception) else None,
            "commits": results[1] if not isinstance(results[1], Exception) else [],
            "issues": results[2] if not isinstance(results[2], Exception) else [],
            "pull_requests": results[3] if not isinstance(results[3], Exception) else [],
            "contributors": results[4] if not isinstance(results[4], Exception) else [],
            "releases": results[5] if not isinstance(results[5], Exception) else [],
            "languages": results[6] if not isinstance(results[6], Exception) else {},
            "topics": results[7] if not isinstance(results[7], Exception) else []
        }
    
    async def fetch_commits(self, owner: str, repo: str, since: Optional[datetime] = None) -> List[Dict]:
        """Fetch repository commits with pagination."""
        commits = []
        page = 1
        per_page = 100
        
        params = {"per_page": per_page, "page": page}
        if since:
            params["since"] = since.isoformat()
        
        while True:
            await self.rate_limiter.wait_if_needed()
            
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/repos/{owner}/{repo}/commits",
                    headers=self.headers,
                    params=params
                )
                
                if response.status_code != 200:
                    break
                
                page_commits = response.json()
                if not page_commits:
                    break
                
                commits.extend(page_commits)
                
                # Check if we've reached the last page
                if len(page_commits) < per_page:
                    break
                
                page += 1
                params["page"] = page
        
        return commits
    
    async def fetch_issues(self, owner: str, repo: str) -> List[Dict]:
        """Fetch repository issues and pull requests."""
        issues = []
        page = 1
        
        while True:
            await self.rate_limiter.wait_if_needed()
            
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/repos/{owner}/{repo}/issues",
                    headers=self.headers,
                    params={
                        "state": "all",
                        "per_page": 100,
                        "page": page
                    }
                )
                
                if response.status_code != 200:
                    break
                
                page_issues = response.json()
                if not page_issues:
                    break
                
                # Filter out pull requests (they appear in issues endpoint)
                actual_issues = [issue for issue in page_issues if "pull_request" not in issue]
                issues.extend(actual_issues)
                
                if len(page_issues) < 100:
                    break
                
                page += 1
        
        return issues
```

### Data Transformation and Validation

```python
# app/services/data_transformer.py
from typing import Dict, Any, List
from datetime import datetime
from pydantic import BaseModel, validator
from app.schemas.github import GitHubCommit, GitHubIssue, GitHubPullRequest

class DataTransformer:
    """Transform raw GitHub data into normalized format."""
    
    def transform_commits(self, raw_commits: List[Dict]) -> List[GitHubCommit]:
        """Transform raw commit data."""
        transformed = []
        
        for commit_data in raw_commits:
            try:
                commit = GitHubCommit(
                    sha=commit_data["sha"],
                    message=commit_data["commit"]["message"],
                    author_name=commit_data["commit"]["author"]["name"],
                    author_email=commit_data["commit"]["author"]["email"],
                    author_date=datetime.fromisoformat(
                        commit_data["commit"]["author"]["date"].replace("Z", "+00:00")
                    ),
                    committer_name=commit_data["commit"]["committer"]["name"],
                    committer_email=commit_data["commit"]["committer"]["email"],
                    committer_date=datetime.fromisoformat(
                        commit_data["commit"]["committer"]["date"].replace("Z", "+00:00")
                    ),
                    additions=commit_data.get("stats", {}).get("additions", 0),
                    deletions=commit_data.get("stats", {}).get("deletions", 0),
                    files_changed=len(commit_data.get("files", [])),
                    files=self.extract_file_changes(commit_data.get("files", []))
                )
                transformed.append(commit)
            except Exception as e:
                logger.warning(f"Failed to transform commit {commit_data.get('sha')}: {e}")
                continue
        
        return transformed
    
    def extract_file_changes(self, files: List[Dict]) -> List[Dict[str, Any]]:
        """Extract file change information."""
        return [
            {
                "filename": file_data["filename"],
                "status": file_data["status"],
                "additions": file_data.get("additions", 0),
                "deletions": file_data.get("deletions", 0),
                "changes": file_data.get("changes", 0),
                "patch": file_data.get("patch", "")
            }
            for file_data in files
        ]
    
    def calculate_commit_metrics(self, commits: List[GitHubCommit]) -> Dict[str, Any]:
        """Calculate aggregate metrics from commits."""
        if not commits:
            return {}
        
        total_additions = sum(commit.additions for commit in commits)
        total_deletions = sum(commit.deletions for commit in commits)
        total_files = sum(commit.files_changed for commit in commits)
        
        # Calculate commit frequency
        commit_dates = [commit.author_date.date() for commit in commits]
        unique_dates = set(commit_dates)
        
        # Calculate author diversity
        authors = set(commit.author_email for commit in commits)
        
        return {
            "total_commits": len(commits),
            "total_additions": total_additions,
            "total_deletions": total_deletions,
            "total_files_changed": total_files,
            "active_days": len(unique_dates),
            "unique_authors": len(authors),
            "avg_additions_per_commit": total_additions / len(commits) if commits else 0,
            "avg_deletions_per_commit": total_deletions / len(commits) if commits else 0,
            "avg_files_per_commit": total_files / len(commits) if commits else 0
        }
```

## AI/ML Processing Pipeline

### Analysis Orchestration

```python
# app/services/analysis_orchestrator.py
from typing import Dict, Any, List
from app.services.ai_ml import CodeAnalysisService, SentimentAnalysisService, TrendAnalysisService
from app.models.repository import Repository
from app.models.insight import Insight, InsightType

class AnalysisOrchestrator:
    """Orchestrates all AI/ML analysis processes."""
    
    def __init__(self):
        self.code_analyzer = CodeAnalysisService()
        self.sentiment_analyzer = SentimentAnalysisService()
        self.trend_analyzer = TrendAnalysisService()
    
    async def run_full_analysis(self, repository: Repository, github_data: Dict[str, Any]) -> List[Insight]:
        """Run complete analysis pipeline."""
        insights = []
        
        # 1. Code Quality Analysis
        if github_data.get("commits"):
            code_insights = await self.analyze_code_quality(repository, github_data)
            insights.extend(code_insights)
        
        # 2. Sentiment Analysis
        if github_data.get("issues") or github_data.get("pull_requests"):
            sentiment_insights = await self.analyze_sentiment(repository, github_data)
            insights.extend(sentiment_insights)
        
        # 3. Trend Analysis
        if github_data.get("commits"):
            trend_insights = await self.analyze_trends(repository, github_data)
            insights.extend(trend_insights)
        
        # 4. Contributor Analysis
        if github_data.get("contributors"):
            contributor_insights = await self.analyze_contributors(repository, github_data)
            insights.extend(contributor_insights)
        
        # 5. Security Analysis
        security_insights = await self.analyze_security(repository, github_data)
        insights.extend(security_insights)
        
        return insights
    
    async def analyze_code_quality(self, repository: Repository, data: Dict[str, Any]) -> List[Insight]:
        """Analyze code quality from commits and file changes."""
        commits = data.get("commits", [])
        languages = data.get("languages", {})
        
        # Calculate complexity metrics
        complexity_score = await self.code_analyzer.calculate_complexity(commits)
        maintainability_score = await self.code_analyzer.calculate_maintainability(commits)
        
        insights = []
        
        # Code complexity insight
        if complexity_score is not None:
            insights.append(Insight(
                repository_id=repository.id,
                type=InsightType.CODE_QUALITY,
                title="Code Complexity Analysis",
                description=f"Average code complexity score: {complexity_score:.2f}",
                confidence_score=0.85,
                data={
                    "complexity_score": complexity_score,
                    "complexity_trend": await self.code_analyzer.get_complexity_trend(commits),
                    "high_complexity_files": await self.code_analyzer.identify_complex_files(commits)
                },
                tags=["code-quality", "complexity", "maintainability"]
            ))
        
        # Language distribution insight
        if languages:
            primary_language = max(languages.items(), key=lambda x: x[1])[0]
            insights.append(Insight(
                repository_id=repository.id,
                type=InsightType.TECHNOLOGY,
                title="Technology Stack Analysis",
                description=f"Primary language: {primary_language}",
                confidence_score=0.95,
                data={
                    "languages": languages,
                    "primary_language": primary_language,
                    "language_diversity": len(languages),
                    "recommendations": await self.code_analyzer.get_language_recommendations(languages)
                },
                tags=["technology", "languages", "stack"]
            ))
        
        return insights
    
    async def analyze_sentiment(self, repository: Repository, data: Dict[str, Any]) -> List[Insight]:
        """Analyze sentiment from issues and pull requests."""
        issues = data.get("issues", [])
        pull_requests = data.get("pull_requests", [])
        
        # Combine text from issues and PRs
        texts = []
        texts.extend([issue.get("title", "") + " " + issue.get("body", "") for issue in issues])
        texts.extend([pr.get("title", "") + " " + pr.get("body", "") for pr in pull_requests])
        
        if not texts:
            return []
        
        sentiment_scores = await self.sentiment_analyzer.analyze_batch(texts)
        avg_sentiment = sum(sentiment_scores) / len(sentiment_scores)
        
        # Categorize sentiment
        if avg_sentiment > 0.1:
            sentiment_label = "Positive"
        elif avg_sentiment < -0.1:
            sentiment_label = "Negative"
        else:
            sentiment_label = "Neutral"
        
        return [Insight(
            repository_id=repository.id,
            type=InsightType.COMMUNITY,
            title="Community Sentiment Analysis",
            description=f"Overall community sentiment: {sentiment_label}",
            confidence_score=0.75,
            data={
                "average_sentiment": avg_sentiment,
                "sentiment_label": sentiment_label,
                "sentiment_distribution": {
                    "positive": len([s for s in sentiment_scores if s > 0.1]),
                    "neutral": len([s for s in sentiment_scores if -0.1 <= s <= 0.1]),
                    "negative": len([s for s in sentiment_scores if s < -0.1])
                },
                "sample_positive": await self.sentiment_analyzer.get_most_positive(texts, sentiment_scores),
                "sample_negative": await self.sentiment_analyzer.get_most_negative(texts, sentiment_scores)
            },
            tags=["sentiment", "community", "feedback"]
        )]
```

### Real-time Processing

```python
# app/tasks/real_time_processor.py
from celery import current_task
from app.tasks.celery_app import celery_app
from app.services.websocket import WebSocketManager
from app.services.cache import CacheService

@celery_app.task(bind=True)
def process_real_time_update(self, event_type: str, data: Dict[str, Any]):
    """Process real-time updates from GitHub webhooks."""
    try:
        if event_type == "push":
            return process_push_event(data)
        elif event_type == "issues":
            return process_issue_event(data)
        elif event_type == "pull_request":
            return process_pr_event(data)
        else:
            logger.info(f"Unhandled event type: {event_type}")
            return {"status": "ignored", "event_type": event_type}
    
    except Exception as exc:
        logger.error(f"Failed to process real-time update: {exc}")
        raise self.retry(exc=exc, countdown=60, max_retries=3)

def process_push_event(data: Dict[str, Any]) -> Dict[str, str]:
    """Process GitHub push event."""
    repository_id = data["repository"]["id"]
    commits = data["commits"]
    
    # Quick analysis for real-time insights
    commit_count = len(commits)
    total_additions = sum(commit.get("added", []) for commit in commits)
    total_deletions = sum(commit.get("removed", []) for commit in commits)
    
    # Update cache
    cache_service = CacheService()
    cache_key = f"repo_activity:{repository_id}"
    activity_data = {
        "last_push": datetime.utcnow().isoformat(),
        "recent_commits": commit_count,
        "recent_changes": len(total_additions) + len(total_deletions)
    }
    cache_service.set(cache_key, activity_data, expiration=timedelta(hours=1))
    
    # Broadcast to WebSocket clients
    ws_manager = WebSocketManager()
    ws_manager.broadcast_to_repository(repository_id, {
        "type": "repository_updated",
        "data": {
            "commits_added": commit_count,
            "files_changed": len(total_additions) + len(total_deletions)
        }
    })
    
    # Trigger incremental analysis if significant changes
    if commit_count > 5 or (len(total_additions) + len(total_deletions)) > 20:
        trigger_incremental_analysis.delay(repository_id, commits)
    
    return {"status": "processed", "commits": commit_count}
```

## Business Logic Layer

### Repository Management

```python
# app/services/repository_service.py
from typing import Optional, List, Dict, Any
from app.models.repository import Repository, AnalysisStatus
from app.models.user import User
from app.services.github_ingestion import GitHubIngestionService
from app.services.analysis_orchestrator import AnalysisOrchestrator

class RepositoryService:
    """Core business logic for repository management."""
    
    def __init__(self):
        self.github_service = GitHubIngestionService()
        self.analysis_orchestrator = AnalysisOrchestrator()
    
    async def add_repository(self, github_url: str, user: User, auto_analyze: bool = True) -> Repository:
        """Add a new repository for analysis."""
        # Parse GitHub URL
        owner, repo_name = self.parse_github_url(github_url)
        
        # Check if repository already exists
        existing_repo = await self.get_by_full_name(f"{owner}/{repo_name}")
        if existing_repo:
            # Add user as follower if not already following
            if not await self.is_user_following(existing_repo.id, user.id):
                await self.follow_repository(existing_repo.id, user.id)
            return existing_repo
        
        # Fetch repository metadata from GitHub
        repo_metadata = await self.github_service.fetch_repository_metadata(owner, repo_name)
        if not repo_metadata:
            raise ValueError("Repository not found on GitHub")
        
        # Create repository record
        repository = Repository(
            github_id=repo_metadata["id"],
            name=repo_metadata["name"],
            full_name=repo_metadata["full_name"],
            description=repo_metadata.get("description"),
            url=repo_metadata["html_url"],
            clone_url=repo_metadata["clone_url"],
            language=repo_metadata.get("language"),
            stars=repo_metadata["stargazers_count"],
            forks=repo_metadata["forks_count"],
            watchers=repo_metadata["watchers_count"],
            size=repo_metadata["size"],
            owner_id=user.id,
            analysis_status=AnalysisStatus.PENDING
        )
        
        # Save to database
        db.add(repository)
        db.commit()
        db.refresh(repository)
        
        # Trigger analysis if requested
        if auto_analyze:
            await self.trigger_analysis(repository.id, user.id)
        
        return repository
    
    async def trigger_analysis(self, repository_id: str, user_id: str, options: Optional[Dict[str, Any]] = None) -> str:
        """Trigger repository analysis."""
        repository = await self.get_by_id(repository_id)
        if not repository:
            raise ValueError("Repository not found")
        
        # Check user permissions
        if not await self.can_user_analyze(repository, user_id):
            raise PermissionError("User cannot analyze this repository")
        
        # Check if analysis is already in progress
        if repository.analysis_status == AnalysisStatus.IN_PROGRESS:
            raise ValueError("Analysis already in progress")
        
        # Update status
        repository.analysis_status = AnalysisStatus.IN_PROGRESS
        db.commit()
        
        # Queue analysis job
        job_id = str(uuid.uuid4())
        analysis_options = options or {
            "include_code_quality": True,
            "include_security_scan": True,
            "include_sentiment_analysis": True,
            "include_trend_analysis": True
        }
        
        # Start background task
        analyze_repository_task.delay(repository_id, analysis_options, job_id)
        
        return job_id
    
    async def get_repository_insights(self, repository_id: str, user_id: str, filters: Optional[Dict] = None) -> List[Insight]:
        """Get repository insights with filtering."""
        repository = await self.get_by_id(repository_id)
        if not repository:
            raise ValueError("Repository not found")
        
        # Check user permissions
        if not await self.can_user_view(repository, user_id):
            raise PermissionError("User cannot view this repository")
        
        # Build query
        query = db.query(Insight).filter(Insight.repository_id == repository_id)
        
        # Apply filters
        if filters:
            if "type" in filters:
                query = query.filter(Insight.type == filters["type"])
            if "min_confidence" in filters:
                query = query.filter(Insight.confidence_score >= filters["min_confidence"])
            if "tags" in filters:
                query = query.filter(Insight.tags.contains(filters["tags"]))
        
        # Order by confidence and recency
        query = query.order_by(Insight.confidence_score.desc(), Insight.generated_at.desc())
        
        # Apply pagination
        limit = filters.get("limit", 20) if filters else 20
        offset = filters.get("offset", 0) if filters else 0
        
        return query.offset(offset).limit(limit).all()
```

### Insight Generation Pipeline

```python
# app/services/insight_generator.py
from typing import List, Dict, Any
from app.models.insight import Insight, InsightType
from app.services.ai_ml import AIMLService

class InsightGenerator:
    """Generate actionable insights from analysis results."""
    
    def __init__(self):
        self.ai_service = AIMLService()
    
    async def generate_insights(self, repository: Repository, analysis_data: Dict[str, Any]) -> List[Insight]:
        """Generate comprehensive insights from analysis data."""
        insights = []
        
        # Performance insights
        performance_insights = await self.generate_performance_insights(repository, analysis_data)
        insights.extend(performance_insights)
        
        # Security insights
        security_insights = await self.generate_security_insights(repository, analysis_data)
        insights.extend(security_insights)
        
        # Maintainability insights
        maintainability_insights = await self.generate_maintainability_insights(repository, analysis_data)
        insights.extend(maintainability_insights)
        
        # Community insights
        community_insights = await self.generate_community_insights(repository, analysis_data)
        insights.extend(community_insights)
        
        # Trend insights
        trend_insights = await self.generate_trend_insights(repository, analysis_data)
        insights.extend(trend_insights)
        
        return insights
    
    async def generate_performance_insights(self, repository: Repository, data: Dict[str, Any]) -> List[Insight]:
        """Generate performance-related insights."""
        insights = []
        
        # Code efficiency analysis
        if "code_metrics" in data:
            metrics = data["code_metrics"]
            
            if metrics.get("cyclomatic_complexity", 0) > 10:
                insights.append(Insight(
                    repository_id=repository.id,
                    type=InsightType.PERFORMANCE,
                    title="High Code Complexity Detected",
                    description="Several functions have high cyclomatic complexity, which may impact maintainability and performance.",
                    confidence_score=0.85,
                    data={
                        "average_complexity": metrics["cyclomatic_complexity"],
                        "complex_functions": metrics.get("complex_functions", []),
                        "recommendations": [
                            "Consider breaking down complex functions into smaller, more focused functions",
                            "Implement unit tests for complex code paths",
                            "Use design patterns to reduce complexity"
                        ]
                    },
                    tags=["performance", "complexity", "maintainability"]
                ))
        
        return insights
    
    async def generate_actionable_recommendations(self, insights: List[Insight]) -> Dict[str, List[str]]:
        """Generate actionable recommendations based on insights."""
        recommendations = {
            "immediate": [],
            "short_term": [],
            "long_term": []
        }
        
        for insight in insights:
            if insight.confidence_score > 0.8:
                if insight.type == InsightType.SECURITY:
                    recommendations["immediate"].extend(insight.data.get("recommendations", []))
                elif insight.type == InsightType.PERFORMANCE:
                    recommendations["short_term"].extend(insight.data.get("recommendations", []))
                else:
                    recommendations["long_term"].extend(insight.data.get("recommendations", []))
        
        return recommendations
```

This comprehensive data flow documentation shows how GitInsight processes data from ingestion through analysis to insight generation, ensuring scalability, reliability, and real-time capabilities throughout the pipeline.
