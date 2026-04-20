> 源：core.md §Domain 1.3 Go Stack + shared/code-standards/go.md (merged 2026-04-20)

# 后端开发师 — Go Stack

## 1.3 Go Stack

├── 1.3.1 Gin/Echo — ShouldBindJSON, struct validation tags, context.Context propagation, custom error response middleware
├── 1.3.2 GORM — db.Where, db.Transaction, db.AutoMigrate cautions, db.Raw().Scan()
└── 1.3.3 Go Concurrency — goroutine fan-out with sync.WaitGroup, sync.Mutex, context.WithTimeout, errgroup.WithContext

---

## Gin / Echo Patterns

**ShouldBindJSON + struct validation tags**

```go
package handler

import (
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/go-playground/validator/v10"
)

type CreateUserRequest struct {
    Email       string `json:"email"       binding:"required,email,max=254"`
    Password    string `json:"password"    binding:"required,min=8,max=128"`
    DisplayName string `json:"display_name" binding:"required,min=1,max=100"`
}

func (h *UserHandler) Create(c *gin.Context) {
    var req CreateUserRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{
            "code":    "VALIDATION_ERROR",
            "message": err.Error(),
        })
        return
    }

    user, err := h.userService.Create(c.Request.Context(), req)
    if err != nil {
        h.handleError(c, err)
        return
    }
    c.JSON(http.StatusCreated, user)
}
```

**context.Context propagation — always pass ctx, never background**

```go
// Service layer receives and passes context through all calls
func (s *UserService) Create(ctx context.Context, req CreateUserRequest) (*User, error) {
    existing, err := s.repo.GetByEmail(ctx, req.Email)
    if err != nil {
        return nil, fmt.Errorf("checking email uniqueness: %w", err)
    }
    if existing != nil {
        return nil, ErrEmailAlreadyExists
    }

    hashedPw, err := bcrypt.GenerateFromPassword([]byte(req.Password), 12)
    if err != nil {
        return nil, fmt.Errorf("hashing password: %w", err)
    }

    return s.repo.Create(ctx, &User{
        Email:       req.Email,
        Password:    string(hashedPw),
        DisplayName: req.DisplayName,
    })
}
```

**Custom error response middleware**

```go
func ErrorHandlerMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        c.Next()
        if len(c.Errors) == 0 {
            return
        }
        err := c.Errors.Last().Err
        switch {
        case errors.Is(err, ErrEmailAlreadyExists):
            c.JSON(http.StatusConflict, ErrorResponse{Code: "EMAIL_ALREADY_EXISTS", Message: "Email already registered"})
        case errors.Is(err, ErrNotFound):
            c.JSON(http.StatusNotFound, ErrorResponse{Code: "NOT_FOUND", Message: "Resource not found"})
        default:
            c.JSON(http.StatusInternalServerError, ErrorResponse{Code: "INTERNAL_ERROR", Message: "Internal server error"})
        }
    }
}
```

---

## GORM Patterns

**db.Where + db.Transaction**

```go
// Parameterized queries — GORM handles parameterization
var user User
result := db.WithContext(ctx).Where("email = ? AND is_active = ?", email, true).First(&user)
if errors.Is(result.Error, gorm.ErrRecordNotFound) {
    return nil, ErrNotFound
}
if result.Error != nil {
    return nil, fmt.Errorf("querying user by email: %w", result.Error)
}

// Transaction
err := db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
    if err := tx.Create(&invitation).Error; err != nil {
        return fmt.Errorf("creating invitation: %w", err)
    }
    if err := tx.Create(&auditLog).Error; err != nil {
        return fmt.Errorf("creating audit log: %w", err)
    }
    return nil
})
```

**db.AutoMigrate cautions**

```go
// AutoMigrate is for development ONLY — never use in production
// Production: use golang-migrate or Atlas
// BAD in production:
// db.AutoMigrate(&User{}, &Invitation{})

// GOOD: check migration status
// run: migrate -database $DB_URL -path migrations status
```

**db.Raw().Scan() with parameterization**

```go
type UserSummary struct {
    ID    uint   `json:"id"`
    Email string `json:"email"`
    Count int    `json:"invitation_count"`
}

var summaries []UserSummary
err := db.WithContext(ctx).Raw(`
    SELECT u.id, u.email, COUNT(i.id) as invitation_count
    FROM users u
    LEFT JOIN invitations i ON i.user_id = u.id
    WHERE u.is_active = ?
    GROUP BY u.id, u.email
`, true).Scan(&summaries).Error
```

---

## Go Concurrency Patterns

**goroutine fan-out with sync.WaitGroup**

```go
func (s *NotificationService) SendBatch(ctx context.Context, userIDs []int64) error {
    var wg sync.WaitGroup
    errs := make([]error, len(userIDs))

    for i, id := range userIDs {
        wg.Add(1)
        go func(idx int, userID int64) {
            defer wg.Done()
            if err := s.send(ctx, userID); err != nil {
                errs[idx] = fmt.Errorf("user %d: %w", userID, err)
            }
        }(i, id)
    }
    wg.Wait()

    return errors.Join(errs...)
}
```

**errgroup.WithContext — preferred over manual WaitGroup for error collection**

```go
import "golang.org/x/sync/errgroup"

func (s *Service) FetchMultiple(ctx context.Context, ids []int64) ([]Result, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]Result, len(ids))

    for i, id := range ids {
        i, id := i, id // capture loop vars
        g.Go(func() error {
            r, err := s.fetchOne(ctx, id)
            if err != nil {
                return fmt.Errorf("fetching id %d: %w", id, err)
            }
            results[i] = r
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}
```

**context.WithTimeout for external calls**

```go
func (c *HTTPClient) Call(ctx context.Context, url string) (*Response, error) {
    callCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    req, err := http.NewRequestWithContext(callCtx, http.MethodGet, url, nil)
    if err != nil {
        return nil, fmt.Errorf("creating request: %w", err)
    }
    resp, err := c.client.Do(req)
    if err != nil {
        return nil, fmt.Errorf("executing request: %w", err)
    }
    defer resp.Body.Close()
    // ... parse response
}
```

---

## Go Code Standards (merged from code-standards/go.md)

### Formatting

- All code MUST be formatted with `gofmt` — no exceptions
- Use `goimports` for automatic import management
- CI must include `go vet` and `golint`

### Project Layout

```
project/
├── cmd/                # executable entries (main.go)
│   └── server/
│       └── main.go
├── internal/           # private app code (not importable externally)
│   ├── handler/        # HTTP handlers
│   ├── service/        # business logic
│   ├── repository/     # data access
│   └── model/          # data models
├── pkg/                # public libraries
├── api/                # API definitions (OpenAPI/protobuf)
├── configs/            # config templates
├── scripts/            # build/deploy scripts
├── go.mod
└── go.sum
```

### Error Handling Rules

- **errors MUST be handled — never discard with `_`**
- Wrap errors with `fmt.Errorf("context: %w", err)` to preserve error chain
- Convert errors to HTTP responses at API boundaries
- Custom error types implement the `error` interface

```go
// GOOD
result, err := db.Query(sql)
if err != nil {
    return nil, fmt.Errorf("query users failed: %w", err)
}

// BAD
result, _ := db.Query(sql)
```

### Naming Conventions

| Type | Style | Example |
|------|-------|---------|
| Package | lowercase, no underscore | `userservice` |
| Exported | PascalCase | `GetUserByID` |
| Unexported | camelCase | `validateInput` |
| Interface (single-method) | method name + er | `Reader`, `Writer` |
| Constants | PascalCase or camelCase | `MaxRetryCount` |

- Abbreviations: full uppercase or lowercase — `userID`, `httpClient`, `URL`
- Receiver names: first letter of type — `func (u *User) Name() string`

### Interface Design

- Interfaces defined by consumers, not providers (Go implicit interface)
- Keep interfaces small: 1–3 methods preferred
- Compose multiple small interfaces rather than inherit

```go
// GOOD — small interfaces composed
type UserReader interface {
    GetUser(ctx context.Context, id int) (*User, error)
}
type UserWriter interface {
    CreateUser(ctx context.Context, user *User) error
}
type UserRepository interface {
    UserReader
    UserWriter
}
```

### Concurrency Rules

- Pass cancel signals and timeouts via `context.Context`
- goroutines MUST have an exit mechanism — no leaks
- Prefer channel over shared memory + mutex
- Use `sync.WaitGroup` to wait for multiple goroutines
- Use `errgroup` for concurrent error management (see patterns above)

### Dependency Injection

- Constructor accepts interface parameters, returns concrete type
- Pass config as struct — never read env vars inside functions
- Use `functional options` pattern for optional configuration
