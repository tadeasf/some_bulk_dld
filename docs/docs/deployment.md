# Deployment

## CI/CD Overview

The project uses GitHub Actions with three workflows triggered by path-specific changes:

| Workflow | Trigger Paths | Jobs |
|----------|--------------|------|
| Backend CI | `fastapi_backend/**` | Lint (ruff check + format), test (pytest) |
| Flutter CI | `flutter_app/**` | Lint, analyze, test, build debug APK, build signed release |
| Deploy Docs | `docs/**` (master only) | Build MkDocs, deploy to GitHub Pages |

## Backend CI

**File:** `.github/workflows/backend-ci.yml`

Runs on push/PR when `fastapi_backend/` changes:

1. Checkout with submodules
2. Install uv via `astral-sh/setup-uv@v5`
3. `uv sync --dev` — install all dependencies
4. `uv run ruff check .` — lint
5. `uv run ruff format --check .` — format check
6. `uv run pytest --cov -v` — tests with coverage

## Flutter CI

**File:** `.github/workflows/flutter-ci.yml`

Runs on push/PR when `flutter_app/` changes:

### Lint & Test Job

1. Checkout with submodules
2. Install Flutter (stable channel, cached)
3. `flutter pub get`
4. `dart format --set-exit-if-changed .` — format check
5. `dart analyze --fatal-infos` — static analysis
6. `flutter test` — unit + widget tests

### Build Debug APK

Runs after lint & test passes:

1. Same Flutter + Java 17 setup
2. `flutter build apk --debug`
3. Upload artifact: `debug-apk`

### Build Release APK (master push only)

Runs after lint & test, only on push to `master`:

1. Decode keystore from `KEYSTORE_BASE64` secret
2. Create `key.properties` from secrets
3. `flutter build apk --release`
4. `flutter build appbundle --release`
5. Upload artifacts: `release-apk`, `release-aab`

## Documentation Deployment

**File:** `.github/workflows/docs.yml`

Runs on push to `master` when `docs/` changes:

1. Checkout with submodules
2. Install uv
3. `uv sync` — install MkDocs + plugins
4. `uv run mkdocs build --strict` — build with strict mode
5. Upload to GitHub Pages via `actions/deploy-pages@v4`

### GitHub Pages Setup

1. Go to repo Settings > Pages
2. Set source to "GitHub Actions"
3. The workflow handles the rest

## GitHub Secrets

Configure these in repo Settings > Secrets and variables > Actions:

| Secret | How to Generate |
|--------|----------------|
| `KEYSTORE_BASE64` | `base64 -w 0 ~/some-bulk-dld-release.jks` |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_PASSWORD` | Your key password |
| `KEY_ALIAS` | `some_bulk_dld` |

!!! warning "Private Submodules"
    If the submodule repos are private, CI needs access. Options:

    - Use a GitHub App installation token
    - Use a deploy key with read access
    - Use a PAT with `repo` scope (least recommended)

    Add the token as a secret and pass it to `actions/checkout`:
    ```yaml
    - uses: actions/checkout@v4
      with:
        submodules: true
        token: ${{ secrets.SUBMODULE_TOKEN }}
    ```

## Local Builds

### Backend

```bash
just check-backend    # lint + format + test
just backend          # run dev server (port 8000)
```

### Flutter

```bash
just check-flutter    # format + analyze + test
just build-debug      # debug APK
just build-release    # signed release APK (requires key.properties)
just build-aab        # signed App Bundle
```

### Documentation

```bash
just docs-build       # build static site to docs/site/
just docs-serve       # serve locally at http://localhost:8000
```

!!! tip "Port Conflict"
    Both the backend and mkdocs serve default to port 8000. Run docs on a different port:
    ```bash
    cd docs && uv run mkdocs serve --dev-addr 127.0.0.1:8001
    ```
