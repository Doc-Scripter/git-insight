# API Gateway and Service Communication Documentation

## Overview

The GitInsight API Gateway serves as the single entry point for all client requests, providing routing, authentication, rate limiting, and load balancing across backend services. It implements a microservices communication pattern that ensures scalability, reliability, and security.

## Architecture Overview

### Gateway Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client Apps   │    │   Web Frontend  │    │  Mobile Apps    │
│                 │    │   (SvelteKit)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Load Balancer │
                    │   (Nginx/HAProxy)│
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   API Gateway   │
                    │   (Kong/Nginx)  │
                    │                 │
                    │ • Authentication│
                    │ • Rate Limiting │
                    │ • Load Balancing│
                    │ • Request Routing│
                    │ • Response Cache│
                    └─────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Python API    │    │    Go API       │    │  Auth Service   │
│   (FastAPI)     │    │   (Gin/Echo)    │    │                 │
│   Port: 8000    │    │   Port: 8080    │    │   Port: 8001    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## API Gateway Configuration

### Kong Gateway Setup

#### Kong Configuration (kong.yml)

```yaml
_format_version: "3.0"

services:
  - name: python-api
    url: http://python-api:8000
    plugins:
      - name: rate-limiting
        config:
          minute: 100
          hour: 1000
      - name: prometheus
        config:
          per_consumer: true
    
  - name: go-api
    url: http://go-api:8080
    plugins:
      - name: rate-limiting
        config:
          minute: 500
          hour: 5000
      - name: prometheus
        config:
          per_consumer: true

  - name: auth-service
    url: http://auth-service:8001

routes:
  # Python API routes
  - name: repositories-route
    service: python-api
    paths:
      - /api/v1/repositories
      - /api/v1/analysis
      - /api/v1/ai
    methods:
      - GET
      - POST
      - PUT
      - DELETE
    plugins:
      - name: jwt
        config:
          secret_is_base64: false
          key_claim_name: kid
      - name: cors
        config:
          origins:
            - "https://gitinsight.com"
            - "https://app.gitinsight.com"
          methods:
            - GET
            - POST
            - PUT
            - DELETE
            - OPTIONS
          headers:
            - Accept
            - Authorization
            - Content-Type
            - X-Requested-With

  # Go API routes (high-performance)
  - name: fast-routes
    service: go-api
    paths:
      - /api/v1/fast
      - /api/v1/stream
      - /health
      - /metrics
    methods:
      - GET
      - POST
    plugins:
      - name: jwt
        config:
          secret_is_base64: false
          key_claim_name: kid
      - name: response-caching
        config:
          content_type:
            - application/json
          cache_ttl: 300
          strategy: memory

  # Authentication routes
  - name: auth-routes
    service: auth-service
    paths:
      - /api/v1/auth
    methods:
      - GET
      - POST
    plugins:
      - name: cors
        config:
          origins:
            - "https://gitinsight.com"
            - "https://app.gitinsight.com"

consumers:
  - username: web-frontend
    custom_id: web-frontend
    jwt_secrets:
      - key: web-frontend-key
        secret: "your-jwt-secret-here"

  - username: mobile-app
    custom_id: mobile-app
    jwt_secrets:
      - key: mobile-app-key
        secret: "your-mobile-jwt-secret-here"

plugins:
  - name: prometheus
    config:
      per_consumer: true
      status_code_metrics: true
      latency_metrics: true
      bandwidth_metrics: true

  - name: request-id
    config:
      header_name: X-Request-ID
      generator: uuid

  - name: correlation-id
    config:
      header_name: X-Correlation-ID
      generator: uuid
```

### Nginx Alternative Configuration

```nginx
# nginx.conf
upstream python_api {
    least_conn;
    server python-api-1:8000 max_fails=3 fail_timeout=30s;
    server python-api-2:8000 max_fails=3 fail_timeout=30s;
    server python-api-3:8000 max_fails=3 fail_timeout=30s;
}

upstream go_api {
    least_conn;
    server go-api-1:8080 max_fails=3 fail_timeout=30s;
    server go-api-2:8080 max_fails=3 fail_timeout=30s;
}

upstream auth_service {
    least_conn;
    server auth-service-1:8001 max_fails=3 fail_timeout=30s;
    server auth-service-2:8001 max_fails=3 fail_timeout=30s;
}

# Rate limiting zones
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_zone $jwt_user_id zone=user_limit:10m rate=100r/m;

server {
    listen 80;
    server_name api.gitinsight.com;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

    # Request ID for tracing
    add_header X-Request-ID $request_id;

    # CORS headers
    add_header Access-Control-Allow-Origin "https://gitinsight.com";
    add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS";
    add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With";

    # Handle preflight requests
    if ($request_method = 'OPTIONS') {
        return 204;
    }

    # Python API routes
    location ~ ^/api/v1/(repositories|analysis|ai) {
        limit_req zone=api_limit burst=20 nodelay;
        limit_req zone=user_limit burst=50 nodelay;
        
        proxy_pass http://python_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Request-ID $request_id;
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Go API routes (high-performance)
    location ~ ^/api/v1/(fast|stream) {
        limit_req zone=api_limit burst=50 nodelay;
        
        proxy_pass http://go_api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Request-ID $request_id;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_connect_timeout 5s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }

    # Authentication routes
    location /api/v1/auth {
        limit_req zone=api_limit burst=10 nodelay;
        
        proxy_pass http://auth_service;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Request-ID $request_id;
    }

    # Health checks
    location /health {
        proxy_pass http://go_api;
        access_log off;
    }

    # Metrics endpoint (restricted)
    location /metrics {
        allow 10.0.0.0/8;
        allow 172.16.0.0/12;
        allow 192.168.0.0/16;
        deny all;
        
        proxy_pass http://go_api;
        access_log off;
    }
}
```

## Service Discovery

### Kubernetes Service Discovery

```yaml
# kubernetes/services.yaml
apiVersion: v1
kind: Service
metadata:
  name: python-api-service
  labels:
    app: python-api
spec:
  selector:
    app: python-api
  ports:
    - port: 8000
      targetPort: 8000
      name: http
  type: ClusterIP

---
apiVersion: v1
kind: Service
metadata:
  name: go-api-service
  labels:
    app: go-api
spec:
  selector:
    app: go-api
  ports:
    - port: 8080
      targetPort: 8080
      name: http
  type: ClusterIP

---
apiVersion: v1
kind: Service
metadata:
  name: auth-service
  labels:
    app: auth-service
spec:
  selector:
    app: auth-service
  ports:
    - port: 8001
      targetPort: 8001
      name: http
  type: ClusterIP
```

### Consul Service Discovery

```hcl
# consul/python-api.hcl
service {
  name = "python-api"
  id = "python-api-1"
  port = 8000
  address = "10.0.1.10"
  
  check {
    http = "http://10.0.1.10:8000/health"
    interval = "10s"
    timeout = "3s"
  }
  
  tags = [
    "api",
    "python",
    "fastapi",
    "v1"
  ]
  
  meta = {
    version = "1.0.0"
    environment = "production"
  }
}

service {
  name = "go-api"
  id = "go-api-1"
  port = 8080
  address = "10.0.1.11"
  
  check {
    http = "http://10.0.1.11:8080/health"
    interval = "5s"
    timeout = "2s"
  }
  
  tags = [
    "api",
    "go",
    "high-performance",
    "v1"
  ]
}
```

## Inter-Service Communication

### HTTP Client Configuration

#### Python Service HTTP Client

```python
import httpx
import asyncio
from typing import Optional, Dict, Any
from app.core.config import settings

class ServiceClient:
    def __init__(self):
        self.timeout = httpx.Timeout(10.0, connect=5.0)
        self.limits = httpx.Limits(max_keepalive_connections=20, max_connections=100)
        
    async def call_go_api(self, endpoint: str, method: str = "GET", 
                         data: Optional[Dict[str, Any]] = None) -> Optional[Dict[str, Any]]:
        """Call Go API service."""
        url = f"{settings.GO_API_URL}{endpoint}"
        headers = {
            "X-Service-Name": "python-api",
            "X-Request-ID": self.get_request_id(),
            "Authorization": f"Bearer {settings.INTERNAL_SERVICE_TOKEN}"
        }
        
        async with httpx.AsyncClient(timeout=self.timeout, limits=self.limits) as client:
            try:
                if method.upper() == "GET":
                    response = await client.get(url, headers=headers)
                elif method.upper() == "POST":
                    response = await client.post(url, json=data, headers=headers)
                else:
                    raise ValueError(f"Unsupported method: {method}")
                
                response.raise_for_status()
                return response.json()
                
            except httpx.RequestError as e:
                logger.error(f"Request to Go API failed: {e}")
                return None
            except httpx.HTTPStatusError as e:
                logger.error(f"Go API returned error: {e.response.status_code}")
                return None

    async def get_repository_summary(self, repo_id: str) -> Optional[Dict[str, Any]]:
        """Get repository summary from Go API."""
        return await self.call_go_api(f"/api/v1/fast/repositories/{repo_id}/summary")

    async def invalidate_cache(self, cache_key: str) -> bool:
        """Invalidate cache entry in Go API."""
        result = await self.call_go_api(f"/api/v1/cache/invalidate", "POST", {"key": cache_key})
        return result is not None and result.get("success", False)
```

#### Go Service HTTP Client

```go
package clients

import (
    "bytes"
    "context"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type PythonAPIClient struct {
    baseURL    string
    httpClient *http.Client
    token      string
}

func NewPythonAPIClient(baseURL, token string) *PythonAPIClient {
    return &PythonAPIClient{
        baseURL: baseURL,
        token:   token,
        httpClient: &http.Client{
            Timeout: 30 * time.Second,
            Transport: &http.Transport{
                MaxIdleConns:        100,
                MaxIdleConnsPerHost: 10,
                IdleConnTimeout:     90 * time.Second,
            },
        },
    }
}

func (c *PythonAPIClient) TriggerAnalysis(ctx context.Context, repoID string, options map[string]interface{}) (*AnalysisJob, error) {
    url := fmt.Sprintf("%s/api/v1/repositories/%s/analyze", c.baseURL, repoID)
    
    payload, err := json.Marshal(options)
    if err != nil {
        return nil, fmt.Errorf("failed to marshal request: %w", err)
    }
    
    req, err := http.NewRequestWithContext(ctx, "POST", url, bytes.NewBuffer(payload))
    if err != nil {
        return nil, fmt.Errorf("failed to create request: %w", err)
    }
    
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.token))
    req.Header.Set("X-Service-Name", "go-api")
    
    resp, err := c.httpClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("request failed: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
    }
    
    var job AnalysisJob
    if err := json.NewDecoder(resp.Body).Decode(&job); err != nil {
        return nil, fmt.Errorf("failed to decode response: %w", err)
    }
    
    return &job, nil
}
```

### Message Queue Communication

#### RabbitMQ Configuration

```python
# Python service - Message publisher
import aio_pika
import json
from typing import Dict, Any

class MessagePublisher:
    def __init__(self, connection_url: str):
        self.connection_url = connection_url
        self.connection = None
        self.channel = None
    
    async def connect(self):
        self.connection = await aio_pika.connect_robust(self.connection_url)
        self.channel = await self.connection.channel()
        
        # Declare exchanges
        self.analysis_exchange = await self.channel.declare_exchange(
            "analysis", aio_pika.ExchangeType.TOPIC, durable=True
        )
        
        self.insights_exchange = await self.channel.declare_exchange(
            "insights", aio_pika.ExchangeType.TOPIC, durable=True
        )
    
    async def publish_analysis_completed(self, repo_id: str, job_id: str, insights_count: int):
        message = {
            "repository_id": repo_id,
            "job_id": job_id,
            "insights_count": insights_count,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        await self.analysis_exchange.publish(
            aio_pika.Message(
                json.dumps(message).encode(),
                content_type="application/json",
                headers={"event_type": "analysis_completed"}
            ),
            routing_key=f"analysis.completed.{repo_id}"
        )
    
    async def publish_insights_generated(self, repo_id: str, insight_ids: list):
        message = {
            "repository_id": repo_id,
            "insight_ids": insight_ids,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        await self.insights_exchange.publish(
            aio_pika.Message(
                json.dumps(message).encode(),
                content_type="application/json",
                headers={"event_type": "insights_generated"}
            ),
            routing_key=f"insights.generated.{repo_id}"
        )
```

```go
// Go service - Message consumer
package messaging

import (
    "encoding/json"
    "log"
    
    "github.com/streadway/amqp"
)

type MessageConsumer struct {
    conn    *amqp.Connection
    channel *amqp.Channel
}

func NewMessageConsumer(connectionURL string) (*MessageConsumer, error) {
    conn, err := amqp.Dial(connectionURL)
    if err != nil {
        return nil, err
    }
    
    channel, err := conn.Channel()
    if err != nil {
        return nil, err
    }
    
    return &MessageConsumer{
        conn:    conn,
        channel: channel,
    }, nil
}

func (c *MessageConsumer) ConsumeAnalysisEvents() error {
    // Declare queue
    queue, err := c.channel.QueueDeclare(
        "go-api-analysis-events", // queue name
        true,                     // durable
        false,                    // delete when unused
        false,                    // exclusive
        false,                    // no-wait
        nil,                      // arguments
    )
    if err != nil {
        return err
    }
    
    // Bind queue to exchange
    err = c.channel.QueueBind(
        queue.Name,
        "analysis.completed.*",
        "analysis",
        false,
        nil,
    )
    if err != nil {
        return err
    }
    
    // Consume messages
    messages, err := c.channel.Consume(
        queue.Name,
        "go-api-consumer",
        false, // auto-ack
        false, // exclusive
        false, // no-local
        false, // no-wait
        nil,   // args
    )
    if err != nil {
        return err
    }
    
    go func() {
        for msg := range messages {
            var event AnalysisCompletedEvent
            if err := json.Unmarshal(msg.Body, &event); err != nil {
                log.Printf("Failed to unmarshal message: %v", err)
                msg.Nack(false, false)
                continue
            }
            
            // Process the event
            if err := c.handleAnalysisCompleted(&event); err != nil {
                log.Printf("Failed to handle analysis completed event: %v", err)
                msg.Nack(false, true) // requeue
                continue
            }
            
            msg.Ack(false)
        }
    }()
    
    return nil
}

func (c *MessageConsumer) handleAnalysisCompleted(event *AnalysisCompletedEvent) error {
    // Invalidate cache for repository
    cacheKey := fmt.Sprintf("repo_summary:%s", event.RepositoryID)
    if err := c.cacheService.Delete(cacheKey); err != nil {
        log.Printf("Failed to invalidate cache: %v", err)
    }
    
    // Broadcast WebSocket message
    wsMessage := &WebSocketMessage{
        Type:         "analysis_completed",
        RepositoryID: event.RepositoryID,
        Timestamp:    time.Now().Format(time.RFC3339),
        Data: map[string]interface{}{
            "job_id":         event.JobID,
            "insights_count": event.InsightsCount,
        },
    }
    
    c.wsHub.BroadcastMessage(wsMessage)
    
    return nil
}
```

## Load Balancing Strategies

### Health Check Configuration

```yaml
# Docker Compose health checks
version: '3.8'
services:
  python-api:
    image: gitinsight/python-api:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    deploy:
      replicas: 3
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

  go-api:
    image: gitinsight/go-api:latest
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 15s
      timeout: 5s
      retries: 3
      start_period: 20s
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 5s
        order: start-first
```

### Circuit Breaker Pattern

```python
# Python implementation
import asyncio
from enum import Enum
from typing import Callable, Any
import time

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class CircuitBreaker:
    def __init__(self, failure_threshold: int = 5, timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
    
    async def call(self, func: Callable, *args, **kwargs) -> Any:
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time > self.timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = await func(*args, **kwargs)
            self.on_success()
            return result
        except Exception as e:
            self.on_failure()
            raise e
    
    def on_success(self):
        self.failure_count = 0
        self.state = CircuitState.CLOSED
    
    def on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

# Usage
go_api_breaker = CircuitBreaker(failure_threshold=3, timeout=30)

async def call_go_api_with_breaker(endpoint: str):
    return await go_api_breaker.call(service_client.call_go_api, endpoint)
```

This API Gateway and service communication documentation provides a comprehensive foundation for managing traffic, ensuring reliability, and maintaining secure communication between GitInsight's microservices.
