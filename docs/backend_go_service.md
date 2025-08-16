# Go Service Documentation

## Overview

The Go service provides high-performance, low-latency API endpoints for GitInsight, focusing on real-time operations, caching, and system monitoring. Built with Go's excellent concurrency model, it handles read-heavy operations and provides ultra-fast response times.

## Service Architecture

### Technology Stack

- **Framework**: Gin Web Framework / Echo (alternative)
- **Database**: PostgreSQL with pgx driver
- **Cache**: Redis with go-redis client
- **Metrics**: Prometheus with custom metrics
- **Logging**: Structured logging with logrus/zap
- **Configuration**: Viper for configuration management
- **Testing**: Testify for testing framework
- **Containerization**: Multi-stage Docker builds

### Project Structure

```
backend/go/
├── cmd/
│   └── server/
│       └── main.go              # Application entry point
├── internal/
│   ├── api/
│   │   ├── handlers/
│   │   │   ├── health.go        # Health check handlers
│   │   │   ├── repository.go    # Repository handlers
│   │   │   ├── search.go        # Search handlers
│   │   │   ├── metrics.go       # Metrics handlers
│   │   │   └── stream.go        # WebSocket handlers
│   │   ├── middleware/
│   │   │   ├── auth.go          # Authentication middleware
│   │   │   ├── cors.go          # CORS middleware
│   │   │   ├── logging.go       # Request logging
│   │   │   ├── metrics.go       # Metrics collection
│   │   │   └── ratelimit.go     # Rate limiting
│   │   └── routes/
│   │       └── router.go        # Route definitions
│   ├── config/
│   │   └── config.go           # Configuration management
│   ├── database/
│   │   ├── connection.go       # Database connection
│   │   ├── migrations/         # Database migrations
│   │   └── queries.go          # SQL queries
│   ├── cache/
│   │   ├── redis.go           # Redis client
│   │   └── keys.go            # Cache key definitions
│   ├── models/
│   │   ├── repository.go      # Repository models
│   │   ├── user.go           # User models
│   │   └── insight.go        # Insight models
│   ├── services/
│   │   ├── repository.go     # Repository service
│   │   ├── search.go         # Search service
│   │   ├── cache.go          # Cache service
│   │   └── metrics.go        # Metrics service
│   ├── utils/
│   │   ├── logger.go         # Logging utilities
│   │   ├── response.go       # HTTP response helpers
│   │   └── validation.go     # Input validation
│   └── websocket/
│       ├── hub.go           # WebSocket hub
│       ├── client.go        # WebSocket client
│       └── message.go       # Message types
├── pkg/
│   ├── auth/
│   │   └── jwt.go           # JWT utilities
│   └── errors/
│       └── errors.go        # Custom error types
├── tests/
│   ├── integration/
│   ├── unit/
│   └── fixtures/
├── scripts/
│   ├── build.sh            # Build script
│   └── migrate.sh          # Migration script
├── go.mod                  # Go modules
├── go.sum                  # Module checksums
├── Dockerfile             # Container configuration
└── docker-compose.yml    # Local development
```

## API Endpoints

### High-Performance Read Operations

#### Repository Summary
```http
GET /api/v1/fast/repositories/{repo_id}/summary
Authorization: Bearer <jwt_token>
Cache-Control: max-age=300
```

**Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "awesome-project",
  "full_name": "owner/awesome-project",
  "language": "Go",
  "stars": 1234,
  "forks": 567,
  "last_updated": "2025-08-16T10:30:00Z",
  "analysis_status": "completed",
  "insight_count": 15,
  "trending_score": 8.5
}
```

#### Fast Repository Search
```http
GET /api/v1/fast/search
Query Parameters:
  - q: string (required) - Search query
  - language: string (optional) - Filter by language
  - min_stars: int (optional) - Minimum star count
  - sort: string (optional) - Sort by: stars, forks, updated
  - limit: int (default: 20, max: 100)
  - offset: int (default: 0)
```

**Response:**
```json
{
  "total": 1500,
  "repositories": [
    {
      "id": "repo-uuid",
      "name": "project-name",
      "full_name": "owner/project-name",
      "description": "Project description",
      "language": "Go",
      "stars": 2500,
      "forks": 800,
      "trending_score": 9.2
    }
  ],
  "facets": {
    "languages": {
      "Go": 450,
      "Python": 380,
      "JavaScript": 320
    },
    "star_ranges": {
      "0-10": 200,
      "11-100": 500,
      "101-1000": 600,
      "1000+": 200
    }
  }
}
```

#### Repository Leaderboard
```http
GET /api/v1/fast/leaderboard
Query Parameters:
  - category: string (trending, popular, quality)
  - timeframe: string (day, week, month, year)
  - language: string (optional)
  - limit: int (default: 50, max: 100)
```

### Real-time Operations

#### Repository Updates Stream
```http
GET /api/v1/stream/repository/{repo_id}/updates
Upgrade: websocket
Connection: Upgrade
Authorization: Bearer <jwt_token>
```

**WebSocket Messages:**
```json
{
  "type": "analysis_completed",
  "repository_id": "repo-uuid",
  "timestamp": "2025-08-16T10:30:00Z",
  "data": {
    "insights_added": 5,
    "analysis_duration": "4m32s"
  }
}
```

#### Global Activity Stream
```http
GET /api/v1/stream/global/activity
Upgrade: websocket
Connection: Upgrade
```

### System Operations

#### Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-08-16T10:30:00Z",
  "version": "1.0.0",
  "uptime": "72h15m30s",
  "dependencies": {
    "database": "healthy",
    "redis": "healthy",
    "python_api": "healthy"
  }
}
```

#### Prometheus Metrics
```http
GET /metrics
```

#### System Statistics
```http
GET /api/v1/system/stats
Authorization: Bearer <admin_token>
```

**Response:**
```json
{
  "requests_per_second": 1250.5,
  "average_response_time": "15ms",
  "active_connections": 450,
  "cache_hit_ratio": 0.85,
  "memory_usage": {
    "allocated": "256MB",
    "system": "512MB",
    "gc_cycles": 1234
  },
  "goroutines": 89
}
```

## Implementation Details

### Main Application

```go
package main

import (
    "context"
    "fmt"
    "log"
    "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/gitinsight/backend/internal/api/routes"
    "github.com/gitinsight/backend/internal/config"
    "github.com/gitinsight/backend/internal/database"
    "github.com/gitinsight/backend/internal/cache"
    "github.com/gitinsight/backend/internal/utils"
)

func main() {
    // Load configuration
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("Failed to load configuration: %v", err)
    }

    // Initialize logger
    logger := utils.NewLogger(cfg.LogLevel)

    // Initialize database
    db, err := database.NewConnection(cfg.DatabaseURL)
    if err != nil {
        logger.Fatalf("Failed to connect to database: %v", err)
    }
    defer db.Close()

    // Initialize Redis cache
    redisClient, err := cache.NewRedisClient(cfg.RedisURL)
    if err != nil {
        logger.Fatalf("Failed to connect to Redis: %v", err)
    }
    defer redisClient.Close()

    // Setup Gin router
    if cfg.Environment == "production" {
        gin.SetMode(gin.ReleaseMode)
    }

    router := gin.New()
    routes.SetupRoutes(router, db, redisClient, logger)

    // Create HTTP server
    server := &http.Server{
        Addr:         fmt.Sprintf(":%d", cfg.Port),
        Handler:      router,
        ReadTimeout:  15 * time.Second,
        WriteTimeout: 15 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    // Start server in goroutine
    go func() {
        logger.Infof("Starting server on port %d", cfg.Port)
        if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            logger.Fatalf("Failed to start server: %v", err)
        }
    }()

    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    logger.Info("Shutting down server...")

    // Graceful shutdown
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := server.Shutdown(ctx); err != nil {
        logger.Fatalf("Server forced to shutdown: %v", err)
    }

    logger.Info("Server exited")
}
```

### Repository Handler

```go
package handlers

import (
    "net/http"
    "strconv"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/gitinsight/backend/internal/services"
    "github.com/gitinsight/backend/internal/models"
    "github.com/gitinsight/backend/internal/utils"
)

type RepositoryHandler struct {
    repositoryService *services.RepositoryService
    cacheService      *services.CacheService
    logger           *utils.Logger
}

func NewRepositoryHandler(repoService *services.RepositoryService, cacheService *services.CacheService, logger *utils.Logger) *RepositoryHandler {
    return &RepositoryHandler{
        repositoryService: repoService,
        cacheService:      cacheService,
        logger:           logger,
    }
}

func (h *RepositoryHandler) GetRepositorySummary(c *gin.Context) {
    repoID := c.Param("repo_id")
    
    // Check cache first
    cacheKey := fmt.Sprintf("repo_summary:%s", repoID)
    if cached, err := h.cacheService.Get(cacheKey); err == nil {
        var summary models.RepositorySummary
        if err := json.Unmarshal([]byte(cached), &summary); err == nil {
            c.Header("X-Cache", "HIT")
            c.JSON(http.StatusOK, summary)
            return
        }
    }

    // Fetch from database
    summary, err := h.repositoryService.GetSummary(repoID)
    if err != nil {
        h.logger.Errorf("Failed to get repository summary: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Internal server error"})
        return
    }

    if summary == nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Repository not found"})
        return
    }

    // Cache the result
    if data, err := json.Marshal(summary); err == nil {
        h.cacheService.Set(cacheKey, string(data), 5*time.Minute)
    }

    c.Header("X-Cache", "MISS")
    c.JSON(http.StatusOK, summary)
}

func (h *RepositoryHandler) SearchRepositories(c *gin.Context) {
    query := c.Query("q")
    if query == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Query parameter 'q' is required"})
        return
    }

    // Parse query parameters
    params := &models.SearchParams{
        Query:    query,
        Language: c.Query("language"),
        Sort:     c.DefaultQuery("sort", "stars"),
        Limit:    parseIntDefault(c.Query("limit"), 20),
        Offset:   parseIntDefault(c.Query("offset"), 0),
    }

    if minStars := c.Query("min_stars"); minStars != "" {
        if stars, err := strconv.Atoi(minStars); err == nil {
            params.MinStars = &stars
        }
    }

    // Validate parameters
    if params.Limit > 100 {
        params.Limit = 100
    }

    // Generate cache key
    cacheKey := fmt.Sprintf("search:%s", params.Hash())
    
    // Check cache
    if cached, err := h.cacheService.Get(cacheKey); err == nil {
        var results models.SearchResults
        if err := json.Unmarshal([]byte(cached), &results); err == nil {
            c.Header("X-Cache", "HIT")
            c.JSON(http.StatusOK, results)
            return
        }
    }

    // Perform search
    results, err := h.repositoryService.Search(params)
    if err != nil {
        h.logger.Errorf("Search failed: %v", err)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Search failed"})
        return
    }

    // Cache results
    if data, err := json.Marshal(results); err == nil {
        h.cacheService.Set(cacheKey, string(data), 2*time.Minute)
    }

    c.Header("X-Cache", "MISS")
    c.JSON(http.StatusOK, results)
}

func parseIntDefault(s string, defaultValue int) int {
    if i, err := strconv.Atoi(s); err == nil {
        return i
    }
    return defaultValue
}
```

### WebSocket Hub

```go
package websocket

import (
    "encoding/json"
    "log"
    "net/http"
    "sync"

    "github.com/gorilla/websocket"
    "github.com/gitinsight/backend/internal/models"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool {
        // Configure CORS for WebSocket connections
        return true // In production, implement proper origin checking
    },
}

type Hub struct {
    clients    map[*Client]bool
    broadcast  chan []byte
    register   chan *Client
    unregister chan *Client
    mutex      sync.RWMutex
}

type Client struct {
    hub      *Hub
    conn     *websocket.Conn
    send     chan []byte
    userID   string
    filters  map[string]interface{}
}

type Message struct {
    Type         string                 `json:"type"`
    RepositoryID string                 `json:"repository_id,omitempty"`
    UserID       string                 `json:"user_id,omitempty"`
    Timestamp    string                 `json:"timestamp"`
    Data         map[string]interface{} `json:"data"`
}

func NewHub() *Hub {
    return &Hub{
        clients:    make(map[*Client]bool),
        broadcast:  make(chan []byte),
        register:   make(chan *Client),
        unregister: make(chan *Client),
    }
}

func (h *Hub) Run() {
    for {
        select {
        case client := <-h.register:
            h.mutex.Lock()
            h.clients[client] = true
            h.mutex.Unlock()
            log.Printf("Client connected: %s", client.userID)

        case client := <-h.unregister:
            h.mutex.Lock()
            if _, ok := h.clients[client]; ok {
                delete(h.clients, client)
                close(client.send)
            }
            h.mutex.Unlock()
            log.Printf("Client disconnected: %s", client.userID)

        case message := <-h.broadcast:
            h.mutex.RLock()
            for client := range h.clients {
                select {
                case client.send <- message:
                default:
                    close(client.send)
                    delete(h.clients, client)
                }
            }
            h.mutex.RUnlock()
        }
    }
}

func (h *Hub) BroadcastMessage(msg *Message) {
    data, err := json.Marshal(msg)
    if err != nil {
        log.Printf("Failed to marshal message: %v", err)
        return
    }
    h.broadcast <- data
}

func (h *Hub) ServeWS(w http.ResponseWriter, r *http.Request, userID string) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Printf("WebSocket upgrade failed: %v", err)
        return
    }

    client := &Client{
        hub:     h,
        conn:    conn,
        send:    make(chan []byte, 256),
        userID:  userID,
        filters: make(map[string]interface{}),
    }

    client.hub.register <- client

    go client.writePump()
    go client.readPump()
}
```

### Performance Optimizations

#### Database Connection Pool

```go
package database

import (
    "context"
    "time"

    "github.com/jackc/pgx/v5/pgxpool"
)

func NewConnection(databaseURL string) (*pgxpool.Pool, error) {
    config, err := pgxpool.ParseConfig(databaseURL)
    if err != nil {
        return nil, err
    }

    // Configure connection pool
    config.MaxConns = 30
    config.MinConns = 5
    config.MaxConnLifetime = time.Hour
    config.MaxConnIdleTime = time.Minute * 30
    config.HealthCheckPeriod = time.Minute

    pool, err := pgxpool.NewWithConfig(context.Background(), config)
    if err != nil {
        return nil, err
    }

    return pool, nil
}
```

#### Redis Cache Service

```go
package services

import (
    "context"
    "encoding/json"
    "time"

    "github.com/redis/go-redis/v9"
)

type CacheService struct {
    client *redis.Client
}

func NewCacheService(client *redis.Client) *CacheService {
    return &CacheService{client: client}
}

func (s *CacheService) Get(key string) (string, error) {
    return s.client.Get(context.Background(), key).Result()
}

func (s *CacheService) Set(key string, value string, expiration time.Duration) error {
    return s.client.Set(context.Background(), key, value, expiration).Err()
}

func (s *CacheService) SetJSON(key string, value interface{}, expiration time.Duration) error {
    data, err := json.Marshal(value)
    if err != nil {
        return err
    }
    return s.Set(key, string(data), expiration)
}

func (s *CacheService) GetJSON(key string, dest interface{}) error {
    data, err := s.Get(key)
    if err != nil {
        return err
    }
    return json.Unmarshal([]byte(data), dest)
}

func (s *CacheService) Delete(key string) error {
    return s.client.Del(context.Background(), key).Err()
}

func (s *CacheService) Exists(key string) (bool, error) {
    count, err := s.client.Exists(context.Background(), key).Result()
    return count > 0, err
}
```

## Testing

### Unit Tests

```go
package handlers_test

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"

    "github.com/gin-gonic/gin"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
    "github.com/gitinsight/backend/internal/handlers"
    "github.com/gitinsight/backend/internal/models"
)

type MockRepositoryService struct {
    mock.Mock
}

func (m *MockRepositoryService) GetSummary(repoID string) (*models.RepositorySummary, error) {
    args := m.Called(repoID)
    return args.Get(0).(*models.RepositorySummary), args.Error(1)
}

func TestRepositoryHandler_GetRepositorySummary(t *testing.T) {
    gin.SetMode(gin.TestMode)

    mockService := new(MockRepositoryService)
    mockCache := new(MockCacheService)
    logger := utils.NewTestLogger()

    handler := handlers.NewRepositoryHandler(mockService, mockCache, logger)

    // Setup test data
    expectedSummary := &models.RepositorySummary{
        ID:       "test-repo-id",
        Name:     "test-repo",
        FullName: "owner/test-repo",
        Language: "Go",
        Stars:    100,
    }

    mockCache.On("Get", "repo_summary:test-repo-id").Return("", errors.New("cache miss"))
    mockService.On("GetSummary", "test-repo-id").Return(expectedSummary, nil)
    mockCache.On("Set", mock.AnythingOfType("string"), mock.AnythingOfType("string"), mock.AnythingOfType("time.Duration")).Return(nil)

    // Create test request
    w := httptest.NewRecorder()
    c, _ := gin.CreateTestContext(w)
    c.Params = gin.Params{{Key: "repo_id", Value: "test-repo-id"}}

    // Execute handler
    handler.GetRepositorySummary(c)

    // Assertions
    assert.Equal(t, http.StatusOK, w.Code)
    
    var response models.RepositorySummary
    err := json.Unmarshal(w.Body.Bytes(), &response)
    assert.NoError(t, err)
    assert.Equal(t, expectedSummary.ID, response.ID)
    assert.Equal(t, expectedSummary.Name, response.Name)

    mockService.AssertExpectations(t)
    mockCache.AssertExpectations(t)
}
```

### Benchmarks

```go
package handlers_test

import (
    "testing"
    "net/http/httptest"
    "github.com/gin-gonic/gin"
)

func BenchmarkRepositoryHandler_GetRepositorySummary(b *testing.B) {
    gin.SetMode(gin.TestMode)
    
    // Setup handler with real services
    handler := setupTestHandler()
    
    b.ResetTimer()
    b.RunParallel(func(pb *testing.PB) {
        for pb.Next() {
            w := httptest.NewRecorder()
            c, _ := gin.CreateTestContext(w)
            c.Params = gin.Params{{Key: "repo_id", Value: "test-repo-id"}}
            
            handler.GetRepositorySummary(c)
        }
    })
}
```

## Monitoring & Metrics

### Prometheus Metrics

```go
package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    RequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "gitinsight_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )

    RequestDuration = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "gitinsight_request_duration_seconds",
            Help:    "HTTP request duration in seconds",
            Buckets: prometheus.DefBuckets,
        },
        []string{"method", "endpoint"},
    )

    ActiveConnections = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "gitinsight_active_connections",
            Help: "Number of active connections",
        },
    )

    CacheHitRatio = promauto.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "gitinsight_cache_hit_ratio",
            Help: "Cache hit ratio",
        },
        []string{"cache_type"},
    )
)
```

This Go service documentation provides comprehensive coverage of the high-performance backend component, focusing on speed, concurrency, and real-time capabilities that complement the Python FastAPI service.
