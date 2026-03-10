# some_bulk_dld — Project Plan & AI Coding Prompt

**Social Media Bulk Downloader**
Flutter App + FastAPI Backend • Monorepo with Git Submodules • Android-first
March 2026

!! CRUCIAL!!: Use this file as plan markdown file: /home/tadeasf/Documents/coding-projects/some_bulk_dld/plan.md
!! CRUCIAL!!: Update this plan file after implementing each phase

---

## Repository Structure

```
some_bulk_dld/                    # Root monorepo (git)
├─ .serena/                       # Serena AI MCP config
├─ .github/
│  └─ workflows/
│     ├─ flutter-ci.yml           # Build, lint, test, sign Flutter
│     ├─ backend-ci.yml           # Lint, test FastAPI backend
│     └─ docs.yml                 # MkDocs → GitHub Pages
├─ flutter_app/                   # Git submodule — Flutter project
├─ fastapi_backend/               # Git submodule — Python/FastAPI project
├─ docs/                          # Git submodule — MkDocs documentation
│  ├─ mkdocs.yml
│  └─ docs/
│     ├─ index.md
│     ├─ architecture.md
│     ├─ backend-api.md
│     ├─ flutter-app.md
│     ├─ setup-guide.md
│     └─ rate-limiting.md
├─ justfile                       # Root-level task runner
├─ CLAUDE.md                      # Serena / AI assistant onboarding
├─ README.md                      # Root readme
└─ .gitmodules
```

---

## How to Use This Plan

This plan is split into **8 stages**. Each stage is a self-contained prompt you feed to your AI coding assistant (Claude Code, Copilot CLI with Serena, etc.). Start a fresh context for each stage. The CLAUDE.md file persists across all stages as the assistant's memory.

**Before each stage:** Paste the CLAUDE.md content + the stage prompt.
**After each stage:** Run the validation commands listed. Fix any issues before moving on.

---

## Stage 0: Onboarding — CLAUDE.md

Create `CLAUDE.md` in the monorepo root. This is the persistent memory for all AI assistants.

````markdown
# some_bulk_dld — AI Assistant Onboarding

## Project Overview
Social media bulk downloader. A Flutter Android app with a Python/FastAPI
backend wrapping instaloader for Instagram data fetching. Monorepo with
git submodules for flutter_app, fastapi_backend, and docs.

## Repo Layout
- `some_bulk_dld/` — root monorepo with justfile, CI, CLAUDE.md
- `flutter_app/` — git submodule, Flutter 3.x Android app
- `fastapi_backend/` — git submodule, Python 3.14 / FastAPI / uv / src layout
- `docs/` — git submodule, MkDocs Material documentation

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
````

---

## Stage 1: Monorepo Scaffolding & Justfile

**Goal:** Set up the root monorepo, justfile, .gitignore, and git submodules.

### Tasks

1. **Root .gitignore** — add: `.env`, `*.jks`, `key.properties`, `__pycache__/`, `.venv/`, `build/`, `.dart_tool/`, `.flutter-plugins`, `.flutter-plugins-dependencies`, `.serena/cache/`.

2. **Justfile** at monorepo root:

```just
# some_bulk_dld — monorepo task runner

default:
    @just --list

# ══════════════════════ ALL ══════════════════════

# Run all checks across both submodules
check: check-flutter check-backend

# ══════════════════════ FLUTTER ══════════════════════

# Run all Flutter checks
check-flutter:
    cd flutter_app && dart format --set-exit-if-changed .
    cd flutter_app && dart analyze --fatal-infos
    cd flutter_app && flutter test

# Format Flutter code
fmt-flutter:
    cd flutter_app && dart format .

# Analyze Flutter code
analyze-flutter:
    cd flutter_app && dart analyze --fatal-infos

# Run Flutter tests
test-flutter:
    cd flutter_app && flutter test

# Get Flutter dependencies
deps-flutter:
    cd flutter_app && flutter pub get

# Run code generation (freezed, riverpod, drift, json_serializable)
codegen:
    cd flutter_app && dart run build_runner build --delete-conflicting-outputs

# Watch code generation
codegen-watch:
    cd flutter_app && dart run build_runner watch --delete-conflicting-outputs

# Build debug APK
build-debug:
    cd flutter_app && flutter build apk --debug

# Build release APK (requires signing key)
build-release:
    cd flutter_app && flutter build apk --release

# Build release AAB (for Play Store)
build-aab:
    cd flutter_app && flutter build appbundle --release

# Run on connected device
run:
    cd flutter_app && flutter run

# List emulators
emulators:
    cd flutter_app && flutter emulators

# Launch emulator by name
emu name:
    cd flutter_app && flutter emulators --launch {{name}}

# Clean Flutter build artifacts
clean-flutter:
    cd flutter_app && flutter clean && flutter pub get

# Generate launcher icons
icons:
    cd flutter_app && dart run flutter_launcher_icons

# Generate splash screen
splash:
    cd flutter_app && dart run flutter_native_splash:create

# ══════════════════════ BACKEND ══════════════════════

# Run all backend checks
check-backend:
    cd fastapi_backend && uv run ruff check .
    cd fastapi_backend && uv run ruff format --check .
    cd fastapi_backend && uv run pytest

# Format backend code
fmt-backend:
    cd fastapi_backend && uv run ruff format .

# Lint backend code (with autofix)
lint-backend:
    cd fastapi_backend && uv run ruff check --fix .

# Run backend tests
test-backend:
    cd fastapi_backend && uv run pytest -v

# Run backend dev server
backend:
    cd fastapi_backend && uv run uvicorn src.some_bulk_dld_backend.main:app --reload --host 0.0.0.0 --port 8000

# Sync backend dependencies
deps-backend:
    cd fastapi_backend && uv sync

# ══════════════════════ DOCS ══════════════════════

# Serve docs locally
docs-serve:
    cd docs && uv run mkdocs serve

# Build docs
docs-build:
    cd docs && uv run mkdocs build

# ══════════════════════ FORMAT ALL ══════════════════════

# Format everything
fmt: fmt-flutter fmt-backend

# Full pre-commit sweep
pre-commit: fmt check
```

3. **Initialize git submodules** — verify `flutter_app/`, `fastapi_backend/` are tracked as submodules. Create `docs/` as a new submodule repo.

4. **Create `.github/copilot-instructions.md`:**

```markdown
Always use Context7 MCP when generating code involving external libraries or APIs.
Use Serena for symbol lookups, refactoring targets, and codebase navigation.
When tackling multi-step tasks, use Sequential Thinking to structure the approach before editing files.
Run `just check` after every change. Never skip validation.
```

**VALIDATION:** `just --list` shows all recipes. Git status clean.

---

## Stage 2: FastAPI Backend — Project Structure & Core

**Goal:** Set up the backend with proper src layout, pyproject.toml, and core API endpoints.

### 2.1 Restructure fastapi_backend

Transform the existing `uv init` project into a proper src layout:

```
fastapi_backend/
├─ src/
│  └─ some_bulk_dld_backend/
│     ├─ __init__.py
│     ├─ main.py              # FastAPI app, CORS, lifespan
│     ├─ config.py            # Settings via pydantic-settings
│     ├─ routers/
│     │  ├─ __init__.py
│     │  ├─ auth.py           # Login, logout, status, 2FA
│     │  └─ profile.py        # Profile lookup, media listing
│     ├─ services/
│     │  ├─ __init__.py
│     │  ├─ instagram.py      # Instaloader wrapper
│     │  └─ rate_limiter.py   # Request queue, backoff, hourly cap
│     └─ models/
│        ├─ __init__.py
│        ├─ auth.py           # LoginRequest, LoginResponse, etc.
│        └─ profile.py        # ProfileInfo, MediaItem, etc.
├─ tests/
│  ├─ __init__.py
│  ├─ conftest.py
│  ├─ test_auth.py
│  └─ test_profile.py
├─ pyproject.toml
├─ uv.lock
├─ README.md
└─ .gitignore
```

### 2.2 pyproject.toml

```toml
[project]
name = "some-bulk-dld-backend"
version = "0.1.0"
description = "FastAPI backend for social media bulk downloader"
requires-python = ">=3.14"
dependencies = [
    "fastapi[standard]>=0.115",
    "instaloader>=4.15",
    "pydantic-settings>=2.7",
    "aiosqlite>=0.20",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-asyncio>=0.24",
    "pytest-cov>=6.0",
    "httpx",
    "ruff>=0.9",
]

[tool.ruff]
target-version = "py314"
line-length = 120
src = ["src"]

[tool.ruff.lint]
select = ["E", "F", "I", "N", "UP", "B", "A", "SIM", "TCH", "RUF"]

[tool.ruff.lint.isort]
known-first-party = ["some_bulk_dld_backend"]

[tool.pytest.ini_options]
testpaths = ["tests"]
asyncio_mode = "auto"
```

### 2.3 API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/auth/login` | Accept username + password, create instaloader session, return session token (UUID). Store session file server-side in `sessions/` (gitignored). |
| `POST` | `/auth/login/2fa` | Accept session_token + 2FA code, complete login. |
| `POST` | `/auth/logout` | Invalidate session, delete session file. |
| `GET` | `/auth/status` | Check if current session is still valid. |
| `GET` | `/profile/{username}` | Profile info: bio, followers, post count, profile pic URL, is_private, follows_viewer. |
| `GET` | `/profile/{username}/posts` | Paginated post metadata. `?limit=50&cursor=X`. |
| `GET` | `/profile/{username}/reels` | Paginated reel metadata. |
| `GET` | `/profile/{username}/stories` | Current story items (expire in 24h). |
| `GET` | `/profile/{username}/highlights` | Highlight groups with their items. |
| `GET` | `/media/{media_id}/download-url` | Direct CDN download URL for a specific media item. |

### 2.4 Rate Limiter Service

- Request queue with configurable delay (default 3s between API calls).
- Exponential backoff on 429 / connection errors (5s → 10s → 20s → ... max 300s).
- Hourly cap: 200 requests/hour/session. Pause 10min when exceeded.
- Response headers: `X-RateLimit-Remaining`, `X-RateLimit-Reset`.

### 2.5 Session Management

- `instaloader.save_session_to_file()` / `load_session_from_file()`.
- Session files in `sessions/` (gitignored).
- UUID token for Flutter app to reference sessions.
- 24h inactivity expiry.
- 2FA support: catch `TwoFactorAuthRequiredException`, return `needs_2fa` flag.

**VALIDATION:** `just check-backend` passes. `just backend` starts. Test with `curl http://localhost:8000/docs`.

---

## Stage 3: Flutter App — Android Prerequisites & Dependencies

**Goal:** Configure Android settings, generate icons/splash, set up signing, add all dependencies.

### 3.1 Android Configuration

- Set `minSdkVersion` to 24 in `android/app/build.gradle`.
- Set `targetSdkVersion` to 35.
- Enable `multiDexEnabled true`.
- Set application label to "SomeBulkDld" in `AndroidManifest.xml`.
- Add permissions: `INTERNET`, `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE` (API < 33), `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` (API >= 33).

### 3.2 App Icon

- Add `flutter_launcher_icons` to dev_dependencies.
- Place 1024x1024 icon at `assets/icon/app_icon.png`.
- Config in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

- Run: `just icons`

### 3.3 Splash Screen

- Add `flutter_native_splash` to dev_dependencies.
- Config in `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash/splash_logo.png
  android: true
  ios: false
  android_12:
    color: "#FFFFFF"
    image: assets/splash/splash_logo.png
```

- Run: `just splash`

### 3.4 Signing Key

- Generate: `keytool -genkey -v -keystore ~/some-bulk-dld-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias some_bulk_dld`
- Create `android/key.properties` (gitignored):

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=some_bulk_dld
storeFile=/home/tadeasf/some-bulk-dld-release.jks
```

- Update `android/app/build.gradle` to read `key.properties` for release `signingConfig`.

### 3.5 Dependencies

Add to `pubspec.yaml`:

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` / `riverpod_annotation` / `riverpod_generator` | State management |
| `dio` | HTTP client |
| `go_router` | Routing |
| `drift` + `sqlite3_flutter_libs` | Local DB (download history) |
| `flutter_secure_storage` | Secure token storage |
| `path_provider` | File system paths |
| `permission_handler` | Runtime permissions |
| `flutter_local_notifications` | Download completion alerts |
| `percent_indicator` | Progress bars |
| `cached_network_image` | Profile picture caching |
| `flutter_dotenv` | .env config loading |
| `freezed` + `freezed_annotation` + `json_serializable` | Immutable models + JSON |
| `build_runner` (dev) | Code generation |
| `flutter_launcher_icons` (dev) | Icon gen |
| `flutter_native_splash` (dev) | Splash gen |

### 3.6 Project Structure

```
flutter_app/lib/
├─ main.dart
├─ app.dart                    # MaterialApp + GoRouter setup
├─ core/
│  ├─ constants.dart
│  ├─ theme.dart
│  ├─ result.dart              # sealed class Result<T, E> { Ok, Err }
│  ├─ logger.dart
│  └─ api_client.dart          # dio instance, interceptors, base URL from .env
├─ features/
│  ├─ auth/
│  │  ├─ data/                 # Repository, DTOs
│  │  ├─ domain/               # Models, interfaces
│  │  └─ presentation/         # Screens, widgets, providers
│  ├─ profile/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  ├─ download/
│  │  ├─ data/
│  │  ├─ domain/
│  │  └─ presentation/
│  └─ history/
│     ├─ data/                 # Drift database, DAOs
│     ├─ domain/
│     └─ presentation/
└─ shared/
   ├─ widgets/
   └─ models/
```

### 3.7 .env

```env
BACKEND_URL=http://10.0.2.2:8000
```

**VALIDATION:** `just deps-flutter && just check-flutter` passes. `just codegen` succeeds. `just build-debug` produces APK.

---

## Stage 4: Flutter App — Auth & Profile Features

**Goal:** Implement login flow (including 2FA) and profile lookup with content selection.

### 4.1 Authentication

- Login screen: username + password fields, "Log In" button.
- Call `POST /auth/login`. Store session token in `flutter_secure_storage`.
- 2FA flow: if backend returns `needs_2fa`, show 2FA code dialog, call `POST /auth/login/2fa`.
- Loading states, error messages (wrong password, rate limited, network error).
- Session persistence: on launch, call `GET /auth/status`. If valid, skip to home.
- Logout: call `POST /auth/logout`, clear secure storage, navigate to login.

### 4.2 Profile Lookup

- Home screen: text field for Instagram username, "Look Up" button.
- Call `GET /profile/{username}`.
- Profile card: cached profile picture, username, bio, follower/following counts, post count, private badge.
- If private + not following → show warning banner.
- Content toggles (all on by default): Profile Picture, Posts, Reels, Stories, Highlights.
- "Download All Selected" button → navigate to download screen.

**VALIDATION:** `just check-flutter` passes. Manual test: login → lookup → see profile card.

---

## Stage 5: Flutter App — Download Manager & History

**Goal:** Implement download queue, progress tracking, file organization, and history.

### 5.1 Download Manager

- Queue system: fetch media URLs from backend, then download files via dio.
- Concurrent downloads: max 3 simultaneous.
- File organization: `Downloads/SomeBulkDld/{username}/{posts|reels|stories|highlights}/`.
- Overall progress: "X of Y items downloaded".
- Per-item progress bars (especially for videos).
- Rate limit display from backend `X-RateLimit-*` headers.
- Pause/resume queue.
- Completion notification via `flutter_local_notifications`.
- Save metadata to drift DB.

### 5.2 History Screen

- List past downloads from drift DB.
- Show: username, date, item count, total size, status (complete/partial/failed).
- Tap to open folder or re-download failed items.

### 5.3 Settings Screen

- Backend URL configuration.
- Download directory.
- Max concurrent downloads (1–5 slider).
- Dark/light theme toggle (system default).
- Auto-delete after N days (off by default).

**VALIDATION:** `just check-flutter` passes. Full flow test: login → lookup → download → check history.

---

## Stage 6: Documentation — MkDocs Setup

**Goal:** Set up the docs submodule with MkDocs Material and write comprehensive documentation.

### 6.1 docs/ Submodule

```
docs/
├─ mkdocs.yml
├─ pyproject.toml            # uv-managed, mkdocs-material dependency
├─ docs/
│  ├─ index.md               # Overview, quick start
│  ├─ architecture.md        # System diagram, tech decisions, why not Graph API
│  ├─ backend-api.md         # All endpoints, request/response examples
│  ├─ flutter-app.md         # Screens, state management, project structure
│  ├─ setup-guide.md         # Dev setup: Flutter SDK, Python 3.14, uv, just, Android SDK
│  ├─ rate-limiting.md       # Strategy, Instagram limits, backoff algorithm
│  ├─ deployment.md          # CI/CD, signing, GitHub Actions
│  └─ contributing.md        # Code style, PR process, running tests
└─ .gitignore
```

### 6.2 mkdocs.yml

```yaml
site_name: SomeBulkDld
site_description: Social Media Bulk Downloader — Documentation
repo_url: https://github.com/<user>/some_bulk_dld
theme:
  name: material
  palette:
    - scheme: default
      primary: blue
      accent: blue
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    - scheme: slate
      primary: blue
      accent: blue
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  features:
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - content.code.copy
    - search.suggest
markdown_extensions:
  - admonition
  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.tabbed:
      alternate_style: true
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.inlinehilite
  - toc:
      permalink: true
nav:
  - Home: index.md
  - Architecture: architecture.md
  - Backend API: backend-api.md
  - Flutter App: flutter-app.md
  - Setup Guide: setup-guide.md
  - Rate Limiting: rate-limiting.md
  - Deployment: deployment.md
  - Contributing: contributing.md
```

### 6.3 docs/pyproject.toml

```toml
[project]
name = "some-bulk-dld-docs"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "mkdocs-material>=9.5",
    "mkdocs-minify-plugin>=0.8",
]
```

### 6.4 Root README.md

Write a comprehensive README.md for the monorepo root covering: project description, features, architecture diagram (text-based), quick start (prerequisites, clone with submodules, `just backend` + `just run`), links to full docs.

**VALIDATION:** `just docs-serve` renders locally at `http://localhost:8000`. All pages render without errors.

---

## Stage 7: GitHub Actions CI/CD

**Goal:** Set up CI workflows for linting, testing, building, signing, and documentation deployment.

### 7.1 `.github/workflows/backend-ci.yml`

```yaml
name: Backend CI
on:
  push:
    paths: ['fastapi_backend/**']
  pull_request:
    paths: ['fastapi_backend/**']

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: fastapi_backend
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
      - uses: astral-sh/setup-uv@v5
        with:
          version: "latest"
      - run: uv sync --dev
      - name: Ruff check
        run: uv run ruff check .
      - name: Ruff format check
        run: uv run ruff format --check .
      - name: Tests
        run: uv run pytest --cov=src/some_bulk_dld_backend --cov-report=xml -v
```

### 7.2 `.github/workflows/flutter-ci.yml`

```yaml
name: Flutter CI
on:
  push:
    paths: ['flutter_app/**']
  pull_request:
    paths: ['flutter_app/**']

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: flutter_app
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - run: flutter pub get
      - name: Format check
        run: dart format --set-exit-if-changed .
      - name: Analyze
        run: dart analyze --fatal-infos
      - name: Test
        run: flutter test

  build-debug:
    needs: lint-and-test
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: flutter_app
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: '17'
      - run: flutter pub get
      - run: flutter build apk --debug
      - uses: actions/upload-artifact@v4
        with:
          name: debug-apk
          path: flutter_app/build/app/outputs/flutter-apk/app-debug.apk

  build-release:
    needs: lint-and-test
    if: github.ref == 'refs/heads/master' && github.event_name == 'push'
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: flutter_app
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true
      - uses: actions/setup-java@v4
        with:
          distribution: zulu
          java-version: '17'
      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/release.jks
      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.KEY_PASSWORD }}
          keyAlias=${{ secrets.KEY_ALIAS }}
          storeFile=release.jks
          EOF
      - run: flutter pub get
      - run: flutter build apk --release
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: flutter_app/build/app/outputs/flutter-apk/app-release.apk
      - uses: actions/upload-artifact@v4
        with:
          name: release-aab
          path: flutter_app/build/app/outputs/bundle/release/app-release.aab
```

### 7.3 `.github/workflows/docs.yml`

```yaml
name: Deploy Docs
on:
  push:
    branches: [master]
    paths: ['docs/**']

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    defaults:
      run:
        working-directory: docs
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
      - uses: astral-sh/setup-uv@v5
      - run: uv sync
      - run: uv run mkdocs build --strict
      - uses: actions/upload-pages-artifact@v3
        with:
          path: docs/site
      - id: deployment
        uses: actions/deploy-pages@v4
```

### 7.4 GitHub Secrets to Configure

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | `base64 -w 0 ~/some-bulk-dld-release.jks` |
| `KEYSTORE_PASSWORD` | Keystore password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | `some_bulk_dld` |

**VALIDATION:** Push to a branch, verify all three workflows trigger and pass (backend-ci, flutter-ci on relevant path changes; docs on docs/ changes).

---

## Stage 8: Polish, Testing & Hardening

**Goal:** Error handling, retry logic, comprehensive tests, final cleanup.

### 8.1 Error Handling

- Implement `Result<T, E>` sealed class throughout Flutter app.
- Dio interceptors: retry on 5xx (max 3 attempts), log all requests.
- Backend: structured error responses with error codes, not raw exceptions.

### 8.2 Testing

**Flutter:**
- Unit tests: Result type, download queue logic, rate limit parsing.
- Widget tests: login form validation, profile card rendering, toggle states.
- Integration tests: full login → lookup → download flow (mock backend with `http_mock_adapter`).

**Backend:**
- Unit tests: rate limiter logic, session management, model validation.
- Integration tests: endpoint responses with mocked instaloader (don't hit real Instagram in CI).

### 8.3 Final Cleanup

- Verify all `just check` passes.
- `just build-release` succeeds.
- `just docs-build` succeeds.
- All GitHub Actions green.
- README.md and docs are accurate and complete.
- No print() calls in production code.
- No TODOs left unresolved.

**VALIDATION:** `just pre-commit` — zero warnings, all tests green across both submodules.

---

*--- END OF PLAN ---*
