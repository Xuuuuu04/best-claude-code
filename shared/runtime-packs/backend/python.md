> 源：core.md §Domain 1.1 Python Stack + shared/code-standards/python.md (merged 2026-04-20)

# 后端开发师 — Python Stack

## 1.1 Python Stack

├── 1.1.1 FastAPI — Pydantic v2 BaseModel with custom validators, async route handlers, dependency injection with Depends, HTTPException, BackgroundTasks, lifespan context manager
├── 1.1.2 Django / DRF — ModelSerializer, ViewSet, permission_classes, throttle_classes, select_related/prefetch_related
└── 1.1.3 SQLAlchemy 2.0 — async_session, select() statement-style queries, relationship(lazy="selectin"), Alembic migrations

---

## FastAPI Implementation Patterns

**Pydantic v2 BaseModel with validators**

```python
from pydantic import BaseModel, field_validator, model_validator
from typing import Optional

class CreateUserRequest(BaseModel):
    email: str
    password: str
    display_name: str

    @field_validator('email')
    @classmethod
    def validate_email(cls, v: str) -> str:
        if '@' not in v or len(v) > 254:
            raise ValueError('Invalid email format or length')
        return v.lower().strip()

    @field_validator('password')
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8 or len(v) > 128:
            raise ValueError('Password must be 8-128 characters')
        return v
```

**Async route handler with dependency injection**

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def create_user(
    request: CreateUserRequest,
    db: AsyncSession = Depends(get_async_db),
    current_user: User = Depends(require_auth),
) -> UserResponse:
    existing = await user_repo.get_by_email(db, request.email)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={"code": "EMAIL_ALREADY_EXISTS", "message": "Email already registered"}
        )
    user = await user_service.create(db, request)
    return UserResponse.model_validate(user)
```

**BackgroundTasks pattern**

```python
from fastapi import BackgroundTasks

@router.post("/invitations/")
async def send_invitation(
    request: InvitationRequest,
    background_tasks: BackgroundTasks,
    db: AsyncSession = Depends(get_async_db),
) -> InvitationResponse:
    invitation = await invitation_service.create(db, request)
    background_tasks.add_task(email_service.send_invitation_email, invitation.id)
    return InvitationResponse.model_validate(invitation)
```

---

## Django / DRF Patterns

**ModelSerializer with validation**

```python
from rest_framework import serializers
from django.contrib.auth.hashers import make_password

class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8, max_length=128)

    class Meta:
        model = User
        fields = ['id', 'email', 'display_name', 'password', 'created_at']
        read_only_fields = ['id', 'created_at']

    def validate_email(self, value: str) -> str:
        if User.objects.filter(email=value.lower()).exists():
            raise serializers.ValidationError("Email already registered")
        return value.lower()

    def create(self, validated_data: dict) -> User:
        validated_data['password'] = make_password(validated_data['password'])
        return super().create(validated_data)
```

**ViewSet with permission_classes**

```python
from rest_framework import viewsets, permissions
from rest_framework.throttling import UserRateThrottle

class UserViewSet(viewsets.ModelViewSet):
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [UserRateThrottle]
    queryset = User.objects.select_related('profile').prefetch_related('roles')

    def get_queryset(self):
        # IDOR guard: users can only see their own data unless admin
        if self.request.user.is_staff:
            return self.queryset
        return self.queryset.filter(id=self.request.user.id)
```

**select_related / prefetch_related discipline**

```python
# N+1 — BAD
users = User.objects.all()
for user in users:
    print(user.profile.bio)  # N+1: one query per user

# GOOD — single JOIN
users = User.objects.select_related('profile').all()

# For ManyToMany or reverse FKs — prefetch_related
users = User.objects.prefetch_related('roles', 'invitations').all()
```

---

## SQLAlchemy 2.0 Async Patterns

**async_session setup**

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

engine = create_async_engine(
    settings.DATABASE_URL,
    echo=False,
    pool_size=10,
    max_overflow=5,
)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

async def get_async_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
```

**select() statement-style queries**

```python
from sqlalchemy import select, update
from sqlalchemy.orm import selectinload

# Basic select with filter
async def get_user_by_email(db: AsyncSession, email: str) -> User | None:
    result = await db.execute(
        select(User).where(User.email == email)
    )
    return result.scalar_one_or_none()

# Eager load relationships
async def get_user_with_roles(db: AsyncSession, user_id: int) -> User | None:
    result = await db.execute(
        select(User)
        .options(selectinload(User.roles))
        .where(User.id == user_id)
    )
    return result.scalar_one_or_none()
```

**Alembic migrations**

```bash
# Check migration status before writing data access code
alembic current
alembic heads

# Generate new migration
alembic revision --autogenerate -m "add_user_profile_table"

# Apply pending migrations
alembic upgrade head
```

---

## Python Code Standards (merged from code-standards/python.md)

### Formatting

- 4-space indent, no tabs
- Line width: 120 characters (PEP 8 recommends 79; 120 is practical for modern screens)
- Two blank lines between top-level functions/classes; one blank line between class methods
- One blank line at end of file

### Naming Conventions

| Type | Style | Example |
|------|-------|---------|
| Module | snake_case | `user_service.py` |
| Class | PascalCase | `UserService` |
| Function/method | snake_case | `get_user_by_id()` |
| Variable | snake_case | `user_count` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Private member | single underscore prefix | `_internal_cache` |

### Import Order

Group in this order with a blank line between groups:

1. Standard library (`os`, `sys`, `json`, `datetime`)
2. Third-party libraries (`fastapi`, `sqlalchemy`, `pydantic`)
3. Project modules (`from app.services import ...`)

Each group sorted alphabetically. Forbid `from xxx import *`.

### Type Hints

- All public function parameters and return values MUST have type hints
- Use `Optional[X]` over `X | None` (Python 3.9 compatibility)
- Use `TypeAlias` or `TypeVar` for complex types
- Pydantic v2 model fields must be typed

```python
# GOOD
def get_user(user_id: int) -> Optional[User]:
    ...

# BAD
def get_user(user_id):
    ...
```

### Docstrings (Google Style)

```python
def calculate_price(base_price: float, discount: float = 0.0) -> float:
    """Calculate the final price after applying discount.

    Args:
        base_price: The original price before discount.
        discount: Discount rate between 0.0 and 1.0. Defaults to 0.0.

    Returns:
        The discounted price. Always >= 0.

    Raises:
        ValueError: If discount is not in [0.0, 1.0].
    """
```

### Exception Handling

- **Forbid bare except**: `except:` and `except Exception:` are too broad — catch specific exceptions
- Exception messages must include enough context
- Handle exceptions at API boundary (router/view) and convert to HTTP error responses
- Use `logging` not `print` for exceptions

```python
# GOOD
try:
    user = db.query(User).filter_by(id=user_id).one()
except NoResultFound:
    raise HTTPException(status_code=404, detail=f"User {user_id} not found")

# BAD
try:
    user = db.query(User).filter_by(id=user_id).one()
except:
    return None
```

### String Formatting

- Prefer f-strings: `f"Hello, {name}"`
- Do not use `%` formatting or `.format()` (except in logging module)
- Use triple-quoted strings for multi-line SQL or templates

### Database Operations

- Use `with` statement to manage session lifecycle
- Multi-table operations MUST use transactions
- Use pagination for large result sets — forbid `.all()` loading everything
- Raw SQL uses parameterized queries — no string concatenation
