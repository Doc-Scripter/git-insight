# Authentication and Authorization Documentation

## Overview

GitInsight implements a comprehensive authentication and authorization system using OAuth2 for GitHub integration, JWT tokens for session management, and Role-Based Access Control (RBAC) for fine-grained permissions. The system ensures secure access to resources while providing a seamless user experience.

## Authentication Architecture

### Authentication Flow

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Auth Service  │    │   GitHub OAuth  │
│   (SvelteKit)   │    │   (Python/Go)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │ 1. Login Request      │                       │
         ├──────────────────────►│                       │
         │                       │ 2. Redirect to GitHub │
         │                       ├──────────────────────►│
         │ 3. GitHub Auth Page   │                       │
         │◄──────────────────────┼───────────────────────┤
         │                       │                       │
         │ 4. Auth Code          │                       │
         ├──────────────────────►│ 5. Exchange Code      │
         │                       ├──────────────────────►│
         │                       │ 6. Access Token       │
         │                       │◄──────────────────────┤
         │ 7. JWT Token          │                       │
         │◄──────────────────────┤                       │
         │                       │                       │
```

### OAuth2 GitHub Integration

#### GitHub OAuth Configuration

```python
# app/core/auth.py
from authlib.integrations.starlette_client import OAuth
from starlette.config import Config

config = Config('.env')

oauth = OAuth(config)
oauth.register(
    name='github',
    client_id=config('GITHUB_CLIENT_ID'),
    client_secret=config('GITHUB_CLIENT_SECRET'),
    server_metadata_url='https://api.github.com/.well-known/oauth_authorization_server',
    client_kwargs={
        'scope': 'user:email read:user'
    }
)

class GitHubOAuth:
    def __init__(self):
        self.client_id = config('GITHUB_CLIENT_ID')
        self.client_secret = config('GITHUB_CLIENT_SECRET')
        self.redirect_uri = config('GITHUB_REDIRECT_URI')
        
    def get_authorization_url(self, state: str) -> str:
        """Generate GitHub authorization URL."""
        params = {
            'client_id': self.client_id,
            'redirect_uri': self.redirect_uri,
            'scope': 'user:email read:user',
            'state': state,
            'response_type': 'code'
        }
        
        query_string = '&'.join([f"{k}={v}" for k, v in params.items()])
        return f"https://github.com/login/oauth/authorize?{query_string}"
    
    async def exchange_code_for_token(self, code: str, state: str) -> dict:
        """Exchange authorization code for access token."""
        async with httpx.AsyncClient() as client:
            response = await client.post(
                'https://github.com/login/oauth/access_token',
                data={
                    'client_id': self.client_id,
                    'client_secret': self.client_secret,
                    'code': code,
                    'redirect_uri': self.redirect_uri,
                    'state': state
                },
                headers={'Accept': 'application/json'}
            )
            return response.json()
    
    async def get_user_info(self, access_token: str) -> dict:
        """Get user information from GitHub."""
        async with httpx.AsyncClient() as client:
            response = await client.get(
                'https://api.github.com/user',
                headers={
                    'Authorization': f'token {access_token}',
                    'Accept': 'application/vnd.github.v3+json'
                }
            )
            return response.json()
```

#### Authentication Endpoints

```python
# app/api/v1/endpoints/auth.py
from fastapi import APIRouter, Depends, HTTPException, Request, Response
from fastapi.security import HTTPBearer
from app.core.auth import GitHubOAuth
from app.core.security import create_access_token, verify_token
from app.services.user import UserService
from app.schemas.auth import LoginResponse, UserInfo

router = APIRouter()
github_oauth = GitHubOAuth()
security = HTTPBearer()

@router.get("/login")
async def login(request: Request):
    """Initiate GitHub OAuth login."""
    state = secrets.token_urlsafe(32)
    request.session['oauth_state'] = state
    
    authorization_url = github_oauth.get_authorization_url(state)
    return {"authorization_url": authorization_url}

@router.get("/callback")
async def oauth_callback(
    request: Request,
    code: str,
    state: str,
    user_service: UserService = Depends()
):
    """Handle GitHub OAuth callback."""
    # Verify state parameter
    if state != request.session.get('oauth_state'):
        raise HTTPException(status_code=400, detail="Invalid state parameter")
    
    # Exchange code for token
    token_data = await github_oauth.exchange_code_for_token(code, state)
    if 'access_token' not in token_data:
        raise HTTPException(status_code=400, detail="Failed to get access token")
    
    # Get user info from GitHub
    github_user = await github_oauth.get_user_info(token_data['access_token'])
    
    # Create or update user in database
    user = await user_service.create_or_update_from_github(github_user)
    
    # Generate JWT token
    access_token = create_access_token(
        data={"sub": str(user.id), "github_id": user.github_id}
    )
    
    return LoginResponse(
        access_token=access_token,
        token_type="bearer",
        user=UserInfo.from_orm(user)
    )

@router.post("/logout")
async def logout(request: Request):
    """Logout user."""
    request.session.clear()
    return {"message": "Successfully logged out"}

@router.get("/me")
async def get_current_user(
    current_user: User = Depends(get_current_user)
):
    """Get current user information."""
    return UserInfo.from_orm(current_user)
```

## JWT Token Management

### Token Generation and Validation

```python
# app/core/security.py
import jwt
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token."""
    to_encode = data.copy()
    
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(hours=settings.ACCESS_TOKEN_EXPIRE_HOURS)
    
    to_encode.update({
        "exp": expire,
        "iat": datetime.utcnow(),
        "type": "access"
    })
    
    encoded_jwt = jwt.encode(
        to_encode, 
        settings.SECRET_KEY, 
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt

def create_refresh_token(user_id: str) -> str:
    """Create JWT refresh token."""
    to_encode = {
        "sub": user_id,
        "exp": datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        "iat": datetime.utcnow(),
        "type": "refresh"
    }
    
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=settings.ALGORITHM
    )
    return encoded_jwt

def verify_token(token: str) -> Optional[Dict[str, Any]]:
    """Verify and decode JWT token."""
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_current_user(token: str = Depends(security)) -> User:
    """Get current user from JWT token."""
    payload = verify_token(token.credentials)
    user_id = payload.get("sub")
    
    if user_id is None:
        raise HTTPException(status_code=401, detail="Invalid token")
    
    user = user_service.get_by_id(user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    
    return user
```

### Token Refresh Mechanism

```python
@router.post("/refresh")
async def refresh_token(
    refresh_token: str,
    user_service: UserService = Depends()
):
    """Refresh access token using refresh token."""
    try:
        payload = jwt.decode(
            refresh_token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM]
        )
        
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        
        user_id = payload.get("sub")
        user = await user_service.get_by_id(user_id)
        
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        
        # Generate new access token
        new_access_token = create_access_token(
            data={"sub": str(user.id), "github_id": user.github_id}
        )
        
        return {
            "access_token": new_access_token,
            "token_type": "bearer"
        }
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Refresh token has expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid refresh token")
```

## Role-Based Access Control (RBAC)

### Permission System

```python
# app/models/permission.py
from enum import Enum
from sqlalchemy import Column, String, Boolean, Table, ForeignKey
from sqlalchemy.orm import relationship
from app.models.base import BaseModel

class PermissionType(str, Enum):
    # Repository permissions
    REPOSITORY_READ = "repository:read"
    REPOSITORY_WRITE = "repository:write"
    REPOSITORY_DELETE = "repository:delete"
    REPOSITORY_ANALYZE = "repository:analyze"
    
    # Insight permissions
    INSIGHTS_READ = "insights:read"
    INSIGHTS_EXPORT = "insights:export"
    INSIGHTS_SHARE = "insights:share"
    
    # User permissions
    USER_READ = "user:read"
    USER_WRITE = "user:write"
    
    # Admin permissions
    ADMIN_USERS = "admin:users"
    ADMIN_SYSTEM = "admin:system"
    ADMIN_ANALYTICS = "admin:analytics"

class Role(BaseModel):
    __tablename__ = "roles"
    
    name = Column(String(50), unique=True, nullable=False)
    description = Column(String(255))
    is_active = Column(Boolean, default=True)
    
    # Relationships
    permissions = relationship("Permission", secondary="role_permissions", back_populates="roles")
    users = relationship("User", back_populates="role")

class Permission(BaseModel):
    __tablename__ = "permissions"
    
    name = Column(String(50), unique=True, nullable=False)
    description = Column(String(255))
    resource_type = Column(String(50))  # repository, user, system
    
    # Relationships
    roles = relationship("Role", secondary="role_permissions", back_populates="permissions")

# Association table for many-to-many relationship
role_permissions = Table(
    'role_permissions',
    BaseModel.metadata,
    Column('role_id', ForeignKey('roles.id'), primary_key=True),
    Column('permission_id', ForeignKey('permissions.id'), primary_key=True)
)
```

### User Roles

```python
# app/models/user.py (extended)
from sqlalchemy import Column, String, ForeignKey
from sqlalchemy.orm import relationship

class SubscriptionTier(str, Enum):
    FREE = "free"
    PREMIUM = "premium"
    ENTERPRISE = "enterprise"

class User(BaseModel):
    __tablename__ = "users"
    
    # ... existing fields ...
    subscription_tier = Column(String(20), default=SubscriptionTier.FREE)
    role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id"))
    
    # Relationships
    role = relationship("Role", back_populates="users")
    
    def has_permission(self, permission: PermissionType) -> bool:
        """Check if user has specific permission."""
        if not self.role:
            return False
        
        return any(
            perm.name == permission.value 
            for perm in self.role.permissions
        )
    
    def can_access_repository(self, repository: "Repository") -> bool:
        """Check if user can access repository."""
        # Owner can always access
        if repository.owner_id == self.id:
            return True
        
        # Check if user follows repository
        if repository.id in [r.id for r in self.followed_repositories]:
            return self.has_permission(PermissionType.REPOSITORY_READ)
        
        # Public repositories with read permission
        return self.has_permission(PermissionType.REPOSITORY_READ)
```

### Permission Decorators

```python
# app/core/permissions.py
from functools import wraps
from typing import List, Union
from fastapi import HTTPException, Depends
from app.models.user import User, PermissionType
from app.core.security import get_current_user

def require_permissions(permissions: Union[PermissionType, List[PermissionType]]):
    """Decorator to require specific permissions."""
    if isinstance(permissions, PermissionType):
        permissions = [permissions]
    
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            # Get current user from dependency injection
            current_user = kwargs.get('current_user')
            if not current_user:
                raise HTTPException(status_code=401, detail="Authentication required")
            
            # Check permissions
            for permission in permissions:
                if not current_user.has_permission(permission):
                    raise HTTPException(
                        status_code=403, 
                        detail=f"Permission denied: {permission.value}"
                    )
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator

def require_subscription(min_tier: SubscriptionTier):
    """Decorator to require minimum subscription tier."""
    tier_levels = {
        SubscriptionTier.FREE: 0,
        SubscriptionTier.PREMIUM: 1,
        SubscriptionTier.ENTERPRISE: 2
    }
    
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            current_user = kwargs.get('current_user')
            if not current_user:
                raise HTTPException(status_code=401, detail="Authentication required")
            
            user_level = tier_levels.get(current_user.subscription_tier, 0)
            required_level = tier_levels.get(min_tier, 0)
            
            if user_level < required_level:
                raise HTTPException(
                    status_code=403,
                    detail=f"Subscription upgrade required: {min_tier.value}"
                )
            
            return await func(*args, **kwargs)
        return wrapper
    return decorator

# Usage in endpoints
@router.post("/repositories/{repo_id}/analyze")
@require_permissions(PermissionType.REPOSITORY_ANALYZE)
@require_subscription(SubscriptionTier.PREMIUM)
async def trigger_analysis(
    repo_id: str,
    current_user: User = Depends(get_current_user)
):
    # Implementation here
    pass
```

## API Key Authentication

### API Key Management

```python
# app/models/api_key.py
import secrets
import hashlib
from sqlalchemy import Column, String, Integer, Boolean, ARRAY, DateTime
from sqlalchemy.orm import relationship

class APIKey(BaseModel):
    __tablename__ = "api_keys"
    
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False)
    key_hash = Column(String(255), unique=True, nullable=False)
    permissions = Column(ARRAY(String), default=list)
    rate_limit = Column(Integer, default=1000)  # requests per hour
    last_used = Column(DateTime(timezone=True))
    expires_at = Column(DateTime(timezone=True))
    is_active = Column(Boolean, default=True)
    
    # Relationships
    user = relationship("User", back_populates="api_keys")
    
    @classmethod
    def generate_key(cls) -> tuple[str, str]:
        """Generate API key and its hash."""
        key = f"gi_{secrets.token_urlsafe(32)}"
        key_hash = hashlib.sha256(key.encode()).hexdigest()
        return key, key_hash
    
    def verify_key(self, key: str) -> bool:
        """Verify API key against stored hash."""
        key_hash = hashlib.sha256(key.encode()).hexdigest()
        return key_hash == self.key_hash

# API Key authentication
async def get_current_user_from_api_key(
    api_key: str = Header(None, alias="X-API-Key")
) -> User:
    """Authenticate user using API key."""
    if not api_key:
        raise HTTPException(status_code=401, detail="API key required")
    
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()
    
    db_key = db.query(APIKey).filter(
        APIKey.key_hash == key_hash,
        APIKey.is_active == True
    ).first()
    
    if not db_key:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    if db_key.expires_at and db_key.expires_at < datetime.utcnow():
        raise HTTPException(status_code=401, detail="API key expired")
    
    # Update last used timestamp
    db_key.last_used = datetime.utcnow()
    db.commit()
    
    return db_key.user
```

## Security Middleware

### Rate Limiting

```python
# app/middleware/rate_limit.py
import time
from collections import defaultdict
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, calls: int = 100, period: int = 3600):
        super().__init__(app)
        self.calls = calls
        self.period = period
        self.clients = defaultdict(list)
    
    async def dispatch(self, request: Request, call_next):
        # Get client identifier
        client_id = self.get_client_id(request)
        
        # Clean old requests
        now = time.time()
        self.clients[client_id] = [
            req_time for req_time in self.clients[client_id]
            if now - req_time < self.period
        ]
        
        # Check rate limit
        if len(self.clients[client_id]) >= self.calls:
            raise HTTPException(
                status_code=429,
                detail="Rate limit exceeded",
                headers={"Retry-After": str(self.period)}
            )
        
        # Record request
        self.clients[client_id].append(now)
        
        response = await call_next(request)
        return response
    
    def get_client_id(self, request: Request) -> str:
        # Try to get user ID from JWT token
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload = verify_token(token)
                return f"user:{payload.get('sub')}"
            except:
                pass
        
        # Fall back to IP address
        return f"ip:{request.client.host}"
```

### Security Headers

```python
# app/middleware/security.py
from starlette.middleware.base import BaseHTTPMiddleware

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        response = await call_next(request)
        
        # Security headers
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Content-Security-Policy"] = "default-src 'self'"
        
        return response
```

This authentication and authorization system provides comprehensive security for GitInsight while maintaining usability and scalability. The combination of OAuth2, JWT tokens, RBAC, and API keys ensures that all access patterns are properly secured and audited.
