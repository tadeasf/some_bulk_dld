# Architecture

## System Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        Monorepo (some_bulk_dld)                  │
│                                                                  │
│  ┌──────────────────┐                  ┌──────────────────────┐  │
│  │   flutter_app/   │    HTTP/JSON     │  fastapi_backend/    │  │
│  │   (submodule)    │ ◄──────────────► │  (submodule)         │  │
│  │                  │                  │                      │  │
│  │  ┌────────────┐  │                  │  ┌────────────────┐  │  │
│  │  │ Riverpod   │  │                  │  │  Routers       │  │  │
│  │  │ Providers  │  │                  │  │  auth / profile│  │  │
│  │  └─────┬──────┘  │                  │  └───────┬────────┘  │  │
│  │        │         │                  │          │           │  │
│  │  ┌─────▼──────┐  │                  │  ┌───────▼────────┐  │  │
│  │  │ Dio HTTP   │  │                  │  │  Services       │  │  │
│  │  │ Client     │  │                  │  │  instagram.py   │  │  │
│  │  └────────────┘  │                  │  │  rate_limiter   │  │  │
│  │                  │                  │  └───────┬────────┘  │  │
│  │  ┌────────────┐  │                  │          │           │  │
│  │  │ Drift DB   │  │                  │  ┌───────▼────────┐  │  │
│  │  │ (SQLite)   │  │                  │  │  instaloader   │──┼──┼──► Instagram
│  │  └────────────┘  │                  │  └────────────────┘  │  │
│  └──────────────────┘                  └──────────────────────┘  │
│                                                                  │
│  ┌──────────────────┐                                            │
│  │   docs/          │                                            │
│  │   (MkDocs)       │                                            │
│  └──────────────────┘                                            │
└──────────────────────────────────────────────────────────────────┘
```

## Why Not the Instagram Graph API?

The official Instagram Graph API is designed for business accounts managing their **own** content. It does **not** support:

- Viewing or downloading other users' posts, reels, or stories
- Accessing private profiles (even if the authenticated user follows them)
- Bulk media retrieval

This project uses [instaloader](https://instaloader.github.io/), a Python library that interfaces with Instagram's private/internal API via session cookies. This is the same API used by the Instagram mobile app and web client.

!!! warning "Legal & Terms of Service"
    Using Instagram's private API may violate their Terms of Service. This project is intended for personal archival use only. Use responsibly and at your own risk.

## Monorepo Structure

```
some_bulk_dld/
├── flutter_app/          # Git submodule → tadeasf/some_bulk_dld-flutter
├── fastapi_backend/      # Git submodule → tadeasf/some_bulk_dld-backend
├── docs/                 # Regular directory — MkDocs documentation
├── .github/              # CI workflows, copilot instructions
├── justfile              # Task runner (28 recipes)
├── CLAUDE.md             # AI assistant onboarding
├── plan.md               # Implementation plan & progress tracker
└── README.md
```

- **Submodules** (`flutter_app/`, `fastapi_backend/`) are private repos
- **docs/** is a regular directory (not a submodule) — simpler for CI path filters
- **justfile** at root delegates commands to each subproject

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter 3.x / Dart | Android-first UI |
| **State Management** | Riverpod 2.x + codegen | Reactive providers with `@Riverpod` macro |
| **HTTP Client** | dio | REST calls with interceptors |
| **Local Database** | drift (SQLite) | Download history & job tracking |
| **Routing** | go_router | Declarative routes with auth redirect |
| **Serialization** | freezed + json_serializable | Immutable DTOs with JSON support |
| **Backend** | FastAPI / uvicorn | Async Python web framework |
| **Instagram Access** | instaloader 4.15+ | Private API via session cookies |
| **Rate Limiting** | Custom RateLimiter service | Per-session locks, backoff, cooldown |
| **Package Manager** | uv | Fast Python dependency resolution |
| **Linting** | ruff (Python), dart analyze | Code quality enforcement |
| **Task Runner** | just | Cross-project command orchestration |
| **Docs** | MkDocs Material | Static documentation site |

## Key Architectural Decisions

### Session-Based Authentication

The backend manages instaloader sessions on the server side. Each login creates a UUID-based session token that the Flutter app stores in `flutter_secure_storage`. Session files persist on disk so restarts don't require re-login.

```
sessions/
├── a1b2c3d4-...-.session      # instaloader session file
└── a1b2c3d4-...-.meta.json    # { username, created_at }
```

### Rate Limiting is First-Class

Instagram aggressively rate-limits automated access. The backend implements:

- **5-second delay** between requests per session
- **200 requests/hour** cap per session
- **Exponential backoff** on errors (5s base, 300s max)
- **10-minute cooldown** on 429 responses
- **30-second timeout** to bail before instaloader retries internally

See [Rate Limiting](rate-limiting.md) for full details.

### Result Type Pattern

The Flutter app uses a sealed `Result<T, E>` class instead of throwing exceptions for expected failures:

```dart
sealed class Result<T, E> {
  const Result();
}
final class Ok<T, E> extends Result<T, E> { ... }
final class Err<T, E> extends Result<T, E> { ... }
```

All repository methods return `Result<T, AppError>`, enabling exhaustive pattern matching on error variants (Network, Unauthorized, NotFound, RateLimited, Server, Unknown).

### No Separate Domain Layer

DTOs serve as domain models. The backend models are simple value objects — adding a domain layer would be unnecessary indirection for this project's complexity level.

### Two Dio Instances

- **`dioProvider`** — with `SessionInterceptor` injecting `X-Session-Token` for API calls
- **Plain `Dio()`** — for CDN file downloads (no auth headers needed) and auth endpoints (avoids circular dependency)
