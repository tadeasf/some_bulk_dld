# SomeBulkDld

**Social Media Bulk Downloader** — Flutter Android app + FastAPI/Python backend for downloading Instagram content.

## Features

- **Profile lookup** — View any public profile's info, bio, stats, and content
- **Bulk download** — Posts, reels, stories, and highlights in one batch
- **Concurrent downloads** — Configurable parallelism (1–5 simultaneous)
- **Download history** — Track past downloads with status and file counts
- **Rate limiting** — Built-in backoff, cooldown, and hourly caps to avoid bans
- **2FA support** — Full two-factor authentication flow
- **Dark/light theme** — System-aware with manual toggle
- **Session persistence** — Resume sessions across app restarts

## Architecture Overview

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

The Flutter app communicates with a self-hosted Python backend via REST. The backend uses [instaloader](https://instaloader.github.io/) to access Instagram's private API through session cookies — the official Graph API does not support downloading other users' content.

## Quick Start

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/tadeasf/some_bulk_dld.git
cd some_bulk_dld

# Start the backend
just deps-backend
just backend          # runs on http://localhost:8000

# Run the Flutter app (in another terminal)
just deps-flutter
just codegen
just run              # launches on connected device/emulator
```

See the [Setup Guide](setup-guide.md) for full prerequisites and configuration.

## Documentation

| Page | Description |
|------|-------------|
| [Architecture](architecture.md) | System design, tech stack, key decisions |
| [Backend API](backend-api.md) | All endpoints, request/response schemas, error codes |
| [Flutter App](flutter-app.md) | Project structure, screens, providers, patterns |
| [Setup Guide](setup-guide.md) | Prerequisites, installation, configuration |
| [Rate Limiting](rate-limiting.md) | Strategy, config values, backoff algorithm |
| [Deployment](deployment.md) | CI/CD workflows, signing, GitHub Pages |
| [Contributing](contributing.md) | Code style, checks, PR process |

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile app | Flutter 3.x / Dart (Android-first) |
| State management | Riverpod 2.x (with code generation) |
| HTTP client | dio |
| Local database | drift (SQLite) |
| Routing | go_router |
| Backend | Python 3.13+ / FastAPI / uvicorn |
| Instagram access | instaloader (private API) |
| Package manager | uv (backend), pub (Flutter) |
| Task runner | just |
| Documentation | MkDocs Material |
