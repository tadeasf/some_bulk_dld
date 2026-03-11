# SomeBulkDld

Social media bulk downloader — Flutter Android app + FastAPI/Python backend.

## Features

- Profile lookup with bio, stats, and content preview
- Bulk download: posts, reels, stories, highlights
- Concurrent downloads with configurable parallelism
- Download history with status tracking
- Built-in rate limiting with exponential backoff
- Two-factor authentication support
- Dark/light theme with system-aware toggle
- Session persistence across app restarts

## Architecture

```
┌─────────────────┐       HTTP        ┌──────────────────┐     Private API    ┌───────────┐
│   Flutter App   │ ◄──────────────► │  FastAPI Backend  │ ◄───────────────► │ Instagram │
│   (Android)     │   JSON over REST  │  (Python/uvicorn) │   instaloader     │  Servers  │
└─────────────────┘                   └──────────────────┘                    └───────────┘
        │                                      │
        ▼                                      ▼
  Local SQLite                          Session files
  (drift DB)                            (server-side)
```

The app communicates with a self-hosted Python backend. The backend uses
[instaloader](https://instaloader.github.io/) to access Instagram's private API
via session cookies — the official Graph API does not support downloading other
users' content.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile app | Flutter 3.x / Dart (Android-first) |
| State management | Riverpod 2.x (code generation) |
| HTTP client | dio |
| Local database | drift (SQLite) |
| Routing | go_router |
| Backend | Python 3.13+ / FastAPI / uvicorn |
| Instagram access | instaloader |
| Package manager | uv (backend), pub (Flutter) |
| Task runner | just |
| Docs | MkDocs Material |

## Quick Start

### Prerequisites

- Flutter SDK 3.x (stable)
- Python 3.13+
- [uv](https://docs.astral.sh/uv/) — `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [just](https://github.com/casey/just) — `cargo install just`

### Setup

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/tadeasf/some_bulk_dld.git
cd some_bulk_dld

# Backend
just deps-backend
just backend              # http://localhost:8000

# Flutter (in another terminal)
just deps-flutter
just codegen
just run
```

## Commands

| Command | Description |
|---------|-------------|
| `just` | List all recipes |
| `just check` | Run all checks (Flutter + backend) |
| `just fmt` | Format all code |
| `just backend` | Start backend dev server |
| `just run` | Launch Flutter app |
| `just codegen` | Run code generation |
| `just build-debug` | Build debug APK |
| `just build-release` | Build signed release APK |
| `just docs-serve` | Preview documentation locally |
| `just pre-commit` | Format + check (full sweep) |

## Repository Structure

```
some_bulk_dld/
├── flutter_app/          # Git submodule — Flutter Android app
├── fastapi_backend/      # Git submodule — Python/FastAPI backend
├── docs/                 # MkDocs Material documentation
├── .github/              # CI workflows
├── justfile              # Task runner
├── CLAUDE.md             # AI assistant onboarding
└── plan.md               # Implementation plan
```

## Documentation

Full documentation is available at the [project docs site](https://tadeasf.github.io/some_bulk_dld/) or locally via `just docs-serve`.

## Disclaimer

This project uses Instagram's private/internal API via instaloader. This may
violate Instagram's Terms of Service. Use responsibly and at your own risk.
Intended for personal archival use only.
