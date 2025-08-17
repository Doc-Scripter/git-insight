# Database Architecture Documentation

## Overview

GitInsight uses PostgreSQL as its primary database, chosen for its reliability, advanced querying capabilities, JSONB support for flexible data storage, and excellent performance characteristics. The database design follows normalized principles while leveraging PostgreSQL-specific features for optimal performance.

## Database Schema

### Entity Relationship Diagram

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│      users      │    │  repositories   │    │    insights     │
│                 │    │                 │    │                 │
│ id (UUID) PK    │    │ id (UUID) PK    │    │ id (UUID) PK    │
│ github_id       │    │ github_id       │    │ repository_id FK│
│ username        │    │ name            │    │ type            │
│ email           │    │ full_name       │    │ title           │
│ avatar_url      │    │ description     │    │ description     │
│ name            │    │ url             │    │ confidence_score│
│ bio             │    │ clone_url       │    │ data (JSONB)    │
│ location        │    │ language        │    │ model_version   │
│ company         │    │ stars           │    │ tags (ARRAY)    │
│ subscription    │    │ forks           │    │ generated_at    │
│ created_at      │    │ watchers        │    │ created_at      │
│ updated_at      │    │ size            │    │ updated_at      │
│ last_login      │    │ owner_id FK     │    │                 │
│                 │    │ last_analyzed   │    │                 │
│                 │    │ analysis_status │    │                 │
│                 │    │ settings (JSONB)│    │                 │
│                 │    │ created_at      │    │                 │
│                 │    │ updated_at      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ analysis_jobs   │    │user_repo_follows│    │   api_keys      │
│                 │    │                 │    │                 │
│ id (UUID) PK    │    │ user_id FK      │    │ id (UUID) PK    │
│ repository_id FK│    │ repository_id FK│    │ user_id FK      │
│ status          │    │ followed_at     │    │ name            │
│ type            │    │ notifications   │    │ key_hash        │
│ options (JSONB) │    │                 │    │ permissions     │
│ progress        │    │                 │    │ rate_limit      │
│ error_message   │    │                 │    │ last_used       │
│ started_at      │    │                 │    │ expires_at      │
│ completed_at    │    │                 │    │ created_at      │
│ created_at      │    │                 │    │ is_active       │
│ updated_at      │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Table Definitions

### Users Table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    github_id BIGINT UNIQUE NOT NULL,
    username VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    avatar_url TEXT,
    name VARCHAR(255),
    bio TEXT,
    location VARCHAR(255),
    company VARCHAR(255),
    subscription_tier VARCHAR(20) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'enterprise')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE
);

-- Indexes
CREATE INDEX idx_users_github_id ON users(github_id);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription ON users(subscription_tier);
```

### Repositories Table

```sql
CREATE TABLE repositories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    github_id BIGINT UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    url TEXT NOT NULL,
    clone_url TEXT NOT NULL,
    language VARCHAR(50),
    stars INTEGER DEFAULT 0,
    forks INTEGER DEFAULT 0,
    watchers INTEGER DEFAULT 0,
    size INTEGER DEFAULT 0,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_analyzed TIMESTAMP WITH TIME ZONE,
    analysis_status VARCHAR(20) DEFAULT 'pending' CHECK (analysis_status IN ('pending', 'in_progress', 'completed', 'failed')),
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_repositories_github_id ON repositories(github_id);
CREATE INDEX idx_repositories_full_name ON repositories(full_name);
CREATE INDEX idx_repositories_owner_id ON repositories(owner_id);
CREATE INDEX idx_repositories_language ON repositories(language);
CREATE INDEX idx_repositories_stars ON repositories(stars DESC);
CREATE INDEX idx_repositories_analysis_status ON repositories(analysis_status);
CREATE INDEX idx_repositories_last_analyzed ON repositories(last_analyzed);

-- GIN index for JSONB settings
CREATE INDEX idx_repositories_settings ON repositories USING GIN(settings);

-- Composite indexes for common queries
CREATE INDEX idx_repositories_language_stars ON repositories(language, stars DESC);
CREATE INDEX idx_repositories_owner_status ON repositories(owner_id, analysis_status);
```

### Insights Table

```sql
CREATE TABLE insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id UUID NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score >= 0 AND confidence_score <= 1),
    data JSONB NOT NULL,
    model_version VARCHAR(50),
    tags TEXT[] DEFAULT '{}',
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_insights_repository_id ON insights(repository_id);
CREATE INDEX idx_insights_type ON insights(type);
CREATE INDEX idx_insights_confidence ON insights(confidence_score DESC);
CREATE INDEX idx_insights_generated_at ON insights(generated_at DESC);
CREATE INDEX idx_insights_tags ON insights USING GIN(tags);

-- GIN index for JSONB data
CREATE INDEX idx_insights_data ON insights USING GIN(data);

-- Composite indexes
CREATE INDEX idx_insights_repo_type ON insights(repository_id, type);
CREATE INDEX idx_insights_type_confidence ON insights(type, confidence_score DESC);
```

### Analysis Jobs Table

```sql
CREATE TABLE analysis_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_id UUID NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'queued' CHECK (status IN ('queued', 'in_progress', 'completed', 'failed', 'cancelled')),
    type VARCHAR(50) NOT NULL,
    options JSONB DEFAULT '{}',
    progress INTEGER DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_analysis_jobs_repository_id ON analysis_jobs(repository_id);
CREATE INDEX idx_analysis_jobs_status ON analysis_jobs(status);
CREATE INDEX idx_analysis_jobs_type ON analysis_jobs(type);
CREATE INDEX idx_analysis_jobs_created_at ON analysis_jobs(created_at DESC);

-- Composite indexes
CREATE INDEX idx_analysis_jobs_repo_status ON analysis_jobs(repository_id, status);
CREATE INDEX idx_analysis_jobs_status_created ON analysis_jobs(status, created_at DESC);
```

### User Repository Follows Table

```sql
CREATE TABLE user_repository_follows (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    repository_id UUID NOT NULL REFERENCES repositories(id) ON DELETE CASCADE,
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notification_settings JSONB DEFAULT '{"email": true, "push": false}',
    PRIMARY KEY (user_id, repository_id)
);

-- Indexes
CREATE INDEX idx_user_repo_follows_user_id ON user_repository_follows(user_id);
CREATE INDEX idx_user_repo_follows_repository_id ON user_repository_follows(repository_id);
CREATE INDEX idx_user_repo_follows_followed_at ON user_repository_follows(followed_at DESC);
```

### API Keys Table

```sql
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    permissions TEXT[] DEFAULT '{}',
    rate_limit INTEGER DEFAULT 1000,
    last_used TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_key_hash ON api_keys(key_hash);
CREATE INDEX idx_api_keys_is_active ON api_keys(is_active);
CREATE INDEX idx_api_keys_expires_at ON api_keys(expires_at);
```

### Audit Logs Table

```sql
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    resource_id UUID,
    details JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- Partitioning by month for large audit logs
CREATE TABLE audit_logs_y2025m08 PARTITION OF audit_logs
FOR VALUES FROM ('2025-08-01') TO ('2025-09-01');
```

## Database Functions and Triggers

### Updated At Trigger Function

```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to tables with updated_at columns
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_repositories_updated_at BEFORE UPDATE ON repositories
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_insights_updated_at BEFORE UPDATE ON insights
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_analysis_jobs_updated_at BEFORE UPDATE ON analysis_jobs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### Repository Statistics Function

```sql
CREATE OR REPLACE FUNCTION get_repository_stats(repo_id UUID)
RETURNS TABLE (
    total_insights INTEGER,
    avg_confidence DECIMAL,
    latest_analysis TIMESTAMP WITH TIME ZONE,
    insight_types TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total_insights,
        AVG(confidence_score)::DECIMAL as avg_confidence,
        MAX(generated_at) as latest_analysis,
        ARRAY_AGG(DISTINCT type) as insight_types
    FROM insights 
    WHERE repository_id = repo_id;
END;
$$ LANGUAGE plpgsql;
```

## Data Access Patterns

### Common Queries

#### Repository Search with Filters

```sql
-- Search repositories with language and star filters
SELECT r.*, u.username as owner_username
FROM repositories r
JOIN users u ON r.owner_id = u.id
WHERE 
    (r.name ILIKE '%search_term%' OR r.description ILIKE '%search_term%')
    AND ($1::VARCHAR IS NULL OR r.language = $1)
    AND ($2::INTEGER IS NULL OR r.stars >= $2)
ORDER BY r.stars DESC, r.updated_at DESC
LIMIT $3 OFFSET $4;
```

#### User Dashboard Data

```sql
-- Get user's followed repositories with latest insights
SELECT 
    r.*,
    COUNT(i.id) as insight_count,
    MAX(i.generated_at) as latest_insight,
    aj.status as analysis_status
FROM user_repository_follows urf
JOIN repositories r ON urf.repository_id = r.id
LEFT JOIN insights i ON r.id = i.repository_id
LEFT JOIN analysis_jobs aj ON r.id = aj.repository_id 
    AND aj.created_at = (
        SELECT MAX(created_at) 
        FROM analysis_jobs 
        WHERE repository_id = r.id
    )
WHERE urf.user_id = $1
GROUP BY r.id, aj.status
ORDER BY urf.followed_at DESC;
```

#### Trending Repositories

```sql
-- Get trending repositories based on recent activity
WITH recent_insights AS (
    SELECT 
        repository_id,
        COUNT(*) as recent_insight_count,
        AVG(confidence_score) as avg_confidence
    FROM insights 
    WHERE generated_at >= NOW() - INTERVAL '7 days'
    GROUP BY repository_id
)
SELECT 
    r.*,
    ri.recent_insight_count,
    ri.avg_confidence,
    (r.stars + r.forks + COALESCE(ri.recent_insight_count, 0) * 10) as trending_score
FROM repositories r
LEFT JOIN recent_insights ri ON r.id = ri.repository_id
WHERE r.analysis_status = 'completed'
ORDER BY trending_score DESC
LIMIT 50;
```

## Performance Optimization

### Connection Pooling

```python
# SQLAlchemy connection pool configuration
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=30,
    pool_pre_ping=True,
    pool_recycle=3600,
    echo=False
)
```

### Query Optimization Strategies

1. **Index Usage**: Ensure all frequently queried columns have appropriate indexes
2. **Query Planning**: Use EXPLAIN ANALYZE to optimize slow queries
3. **Partitioning**: Partition large tables (audit_logs) by date
4. **Materialized Views**: Create for complex aggregations
5. **Connection Pooling**: Optimize connection pool settings

### Materialized Views

```sql
-- Repository statistics materialized view
CREATE MATERIALIZED VIEW repository_stats AS
SELECT 
    r.id,
    r.full_name,
    r.language,
    r.stars,
    r.forks,
    COUNT(i.id) as total_insights,
    AVG(i.confidence_score) as avg_confidence,
    MAX(i.generated_at) as latest_insight,
    COUNT(DISTINCT urf.user_id) as follower_count
FROM repositories r
LEFT JOIN insights i ON r.id = i.repository_id
LEFT JOIN user_repository_follows urf ON r.id = urf.repository_id
GROUP BY r.id, r.full_name, r.language, r.stars, r.forks;

-- Create indexes on materialized view
CREATE INDEX idx_repo_stats_language ON repository_stats(language);
CREATE INDEX idx_repo_stats_stars ON repository_stats(stars DESC);
CREATE INDEX idx_repo_stats_insights ON repository_stats(total_insights DESC);

-- Refresh strategy (can be automated with cron job)
REFRESH MATERIALIZED VIEW CONCURRENTLY repository_stats;
```

## Migration Management

### Alembic Configuration

```python
# alembic/env.py
from alembic import context
from sqlalchemy import engine_from_config, pool
from app.models.base import Base
from app.core.config import settings

config = context.config
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

target_metadata = Base.metadata

def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True
        )

        with context.begin_transaction():
            context.run_migrations()
```

### Sample Migration

```python
"""Add repository settings column

Revision ID: 001_add_repo_settings
Revises: 
Create Date: 2025-08-16 10:30:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '001_add_repo_settings'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    op.add_column('repositories', 
        sa.Column('settings', postgresql.JSONB(), nullable=True, default=sa.text("'{}'::jsonb"))
    )
    op.create_index('idx_repositories_settings', 'repositories', ['settings'], 
                   postgresql_using='gin')

def downgrade():
    op.drop_index('idx_repositories_settings', table_name='repositories')
    op.drop_column('repositories', 'settings')
```

## Backup and Recovery

### Backup Strategy

```bash
#!/bin/bash
# Daily backup script
BACKUP_DIR="/backups/gitinsight"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="gitinsight_db"

# Create backup directory
mkdir -p $BACKUP_DIR

# Full database backup
pg_dump -h localhost -U gitinsight_user -d $DB_NAME \
    --format=custom --compress=9 \
    --file="$BACKUP_DIR/gitinsight_full_$DATE.dump"

# Schema-only backup
pg_dump -h localhost -U gitinsight_user -d $DB_NAME \
    --schema-only --format=plain \
    --file="$BACKUP_DIR/gitinsight_schema_$DATE.sql"

# Cleanup old backups (keep 30 days)
find $BACKUP_DIR -name "*.dump" -mtime +30 -delete
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
```

### Point-in-Time Recovery

```bash
# Enable WAL archiving in postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/wal_archive/%f'

# Recovery example
pg_basebackup -h localhost -D /var/lib/postgresql/recovery -U replication -P -W
# Create recovery.conf with target time
echo "restore_command = 'cp /var/lib/postgresql/wal_archive/%f %p'" > recovery.conf
echo "recovery_target_time = '2025-08-16 10:30:00'" >> recovery.conf
```

## Security Considerations

### Row Level Security

```sql
-- Enable RLS on sensitive tables
ALTER TABLE repositories ENABLE ROW LEVEL SECURITY;
ALTER TABLE insights ENABLE ROW LEVEL SECURITY;

-- Policy for repository access
CREATE POLICY repository_access_policy ON repositories
    FOR ALL TO application_role
    USING (
        owner_id = current_setting('app.current_user_id')::UUID 
        OR 
        id IN (
            SELECT repository_id 
            FROM user_repository_follows 
            WHERE user_id = current_setting('app.current_user_id')::UUID
        )
    );
```

### Data Encryption

```sql
-- Encrypt sensitive columns
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Example: Encrypt API keys
ALTER TABLE api_keys 
ADD COLUMN encrypted_key BYTEA;

-- Function to encrypt/decrypt
CREATE OR REPLACE FUNCTION encrypt_api_key(key_text TEXT)
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(key_text, current_setting('app.encryption_key'));
END;
$$ LANGUAGE plpgsql;
```

This database architecture provides a solid foundation for GitInsight's data storage needs, with proper indexing, relationships, and optimization strategies for high performance and scalability.
