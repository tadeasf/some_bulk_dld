# some_bulk_dld — AI Assistant Onboarding

## Project Overview
Social media bulk downloader. A Flutter Android app with a Python/FastAPI
backend wrapping instaloader for Instagram data fetching. Monorepo with
git submodules for flutter_app, fastapi_backend, and docs.

## Repo Layout
- `some_bulk_dld/` — root monorepo with justfile, CI, CLAUDE.md
- `flutter_app/` — git submodule, Flutter 3.x Android app
- `fastapi_backend/` — git submodule, Python 3.14 / FastAPI / uv / src layout
- `docs/` — regular directory, MkDocs Material documentation

## Tech Stack

### Flutter App
- Flutter 3.x / Dart (Android-first, but all platforms scaffolded)
- State management: Riverpod 2.x (with code generation)
- HTTP client: dio
- Local storage: drift (SQLite) for download history
- Routing: go_router
- Build runner: build_runner for codegen (freezed, riverpod_generator, drift)

### FastAPI Backend
- Python 3.14 / FastAPI / uvicorn
- Package manager: uv (pyproject.toml, uv.lock)
- Project layout: src/ directory (`src/some_bulk_dld_backend/`)
- Instagram integration: instaloader (private API via session cookies)
- Database: SQLite via aiosqlite + SQLAlchemy 2.x (if needed)
- Linting/formatting: ruff

### Task Runner
- just (justfile) at monorepo root
- Delegates to submodule-specific commands

### Documentation
- MkDocs Material theme
- Deployed to GitHub Pages via CI

### CI/CD
- GitHub Actions for all three submodules
- Flutter: lint → test → build debug APK → build signed release APK
- Backend: ruff check → ruff format --check → pytest
- Docs: mkdocs build → deploy to GitHub Pages

## Code Style Rules (ALWAYS ENFORCE)

### Dart/Flutter
- Trailing commas on ALL argument lists (dart format enforces this).
- Prefer const constructors wherever possible.
- Pattern matching (Dart 3 switch expressions) over if/else chains.
- File names: snake_case. Classes: PascalCase.
- Import order: dart → package → relative, separated by blank lines.
- All public APIs must have /// doc comments.
- Prefer final over var. Never use dynamic unless unavoidable.
- Sealed classes for state/event modeling.
- Extension types for newtypes / type-safe wrappers.
- Records for returning multiple values.
- Error handling: Result<T, E> sealed class pattern. Never throw for expected failures.
- Max line length: 80 chars.
- No print() — use package:logging.

### Python (Backend)
- Format: `uv run ruff format .`
- Lint: `uv run ruff check --fix .`
- Type hints on ALL function signatures (params + return).
- Google-style docstrings on all public functions/classes.
- Pydantic v2 models for request/response schemas.
- Async endpoints in FastAPI wherever possible.
- Imports always at top of file — no lazy imports.
- No `except: pass` — always handle or log.
- Pattern matching (match/case) over if/elif/else for literal comparisons.
- Function decomposition: max 20–50 lines, split into _helper() functions.
- Single responsibility, return values over modifying globals.
- src/ layout: all code under `src/some_bulk_dld_backend/`.

## Mandatory Checks (RUN AFTER EVERY TASK)
```bash
# From monorepo root:
just check        # runs ALL checks across both submodules
just check-flutter  # dart format, dart analyze, flutter test
just check-backend  # ruff check, ruff format --check, pytest
```
If any check fails, fix the issue before moving on. Never skip checks.

## Key Architectural Decisions
- Instagram Graph API does NOT support downloading other users' content.
  We use instaloader (Python) which uses Instagram's internal/private API
  via session cookies.
- Flutter app communicates with local/self-hosted Python backend via HTTP.
- Rate limiting is critical: 2–5s delays between requests, 200 req/hr cap.
- Downloads saved to device's Downloads/SomeBulkDld/{username}/ directory.
