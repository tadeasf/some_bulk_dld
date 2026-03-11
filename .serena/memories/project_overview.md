# Project Overview

## Purpose
Social media bulk downloader — Flutter Android app with a Python/FastAPI backend wrapping instaloader for Instagram data fetching.

## Architecture
- **Monorepo** at `tadeasf/some_bulk_dld` (public)
- **flutter_app/** — git submodule → `tadeasf/some_bulk_dld-flutter` (private), Flutter 3.x Android app
- **fastapi_backend/** — git submodule → `tadeasf/some_bulk_dld-backend` (private), Python 3.14 / FastAPI
- **docs/** — regular directory (not submodule), MkDocs Material documentation

## Tech Stack
### Flutter App
- Flutter 3.x / Dart, Android-first
- Riverpod 2.x (code generation), dio, drift (SQLite), go_router
- build_runner for codegen (freezed, riverpod_generator, drift)

### FastAPI Backend
- Python 3.14 / FastAPI / uvicorn
- Package manager: uv (pyproject.toml, uv.lock)
- src/ layout: `src/some_bulk_dld_backend/`
- Instagram integration: instaloader (private API via session cookies)
- Linting/formatting: ruff

### Task Runner
- just (justfile) at monorepo root

## Key Decisions
- Instagram Graph API doesn't support downloading others' content → using instaloader
- Rate limiting critical: 2-5s delays, 200 req/hr cap
- Downloads to device's Downloads/SomeBulkDld/{username}/
